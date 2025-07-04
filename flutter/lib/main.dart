import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

import 'package:mopro_flutter/mopro_flutter.dart';
import 'package:mopro_flutter/mopro_types.dart';
import 'deep_link_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ReownAppKitModal? _appKitModal;
  CircomProofResult? _circomProofResult;
  bool? _circomValid;
  bool? _onChainValid;
  final _moproFlutterPlugin = MoproFlutter();
  bool isProving = false;
  bool isInitializing = false;
  bool isVerifyingOnChain = false;
  Exception? _error;

  // Controllers to handle user input
  final TextEditingController _controllerA = TextEditingController();
  final TextEditingController _controllerB = TextEditingController();
  
  // On-chain verification constants
  static const String sepoliaRpcUrl = 'https://ethereum-sepolia-rpc.publicnode.com';
  static const String verifierContractAddress = '0x01AfBba5fB7D57a37D2B8CE1CCA4DC696ed358FE';
  static const String verifierAbi = '''[
	{
		"inputs": [
			{
				"internalType": "uint256[2]",
				"name": "_pA",
				"type": "uint256[2]"
			},
			{
				"internalType": "uint256[2][2]",
				"name": "_pB",
				"type": "uint256[2][2]"
			},
			{
				"internalType": "uint256[2]",
				"name": "_pC",
				"type": "uint256[2]"
			},
			{
				"internalType": "uint256[2]",
				"name": "_pubSignals",
				"type": "uint256[2]"
			}
		],
		"name": "verifyProof",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	}
]''';

  @override
  void initState() {
    super.initState();
    _controllerA.text = "5";
    _controllerB.text = "3";
    
    // Add listeners to update UI when text changes
    _controllerA.addListener(() {
      setState(() {});
    });
    _controllerB.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controllerA.dispose();
    _controllerB.dispose();
    super.dispose();
  }

  Future<void> _ensureAppKitInitialized(BuildContext context) async {
    if (_appKitModal != null) return;

    setState(() {
      isInitializing = true;
      _error = null;
    });

    try {
      print('[MoproWallet] Starting AppKit initialization...');
      
      // Initialize AppKit with proper context that has MaterialLocalizations
      final appKitModal = ReownAppKitModal(
        context: context,
        projectId: const String.fromEnvironment('PROJECT_ID', defaultValue: '248ac32fac3313463f6d442c787f4b7b'), // Using the Project ID from your build command
        metadata: const PairingMetadata(
          name: 'Mopro Wallet Connect',
          description: 'Zero-Knowledge Proof Generator with Wallet Connect',
          url: 'https://mopro.org/',
          icons: ['https://avatars.githubusercontent.com/u/37784886'],
          redirect: Redirect(
            native: 'moprowallet://',
            universal: 'https://mopro.org/moprowallet',
            linkMode: true, // Enable link mode for better mobile UX
          ),
        ),
        requiredNamespaces: {
          'eip155': const RequiredNamespace(
            chains: ['eip155:1', 'eip155:137', 'eip155:11155111'], // Ethereum, Polygon, and Sepolia
            methods: [
              'eth_sendTransaction',
              'eth_signTransaction',
              'eth_sign',
              'personal_sign',
              'eth_signTypedData',
            ],
            events: ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      print('[MoproWallet] Calling appKitModal.init()...');
      // Wait for initialization with timeout
      await appKitModal.init().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout - please check your internet connection and try again');
        },
      );

      print('[MoproWallet] AppKit initialization completed successfully');

      if (mounted) {
        setState(() {
          _appKitModal = appKitModal;
          isInitializing = false;
        });
        
        // Initialize deep link handler for wallet responses
        print('[MoproWallet] Initializing deep link handler...');
        DeepLinkHandler.init(_appKitModal!);
        
        // Open the modal after initialization
        print('[MoproWallet] Opening modal view...');
        _appKitModal!.openModalView();
      }
    } catch (e) {
      print('[MoproWallet] Error during initialization: $e');
      print('[MoproWallet] Error type: ${e.runtimeType}');
      if (mounted) {
        setState(() {
          _error = Exception('Failed to initialize AppKit: $e');
          isInitializing = false;
        });
      }
    }
  }

  Future<void> _verifyProofOnChain() async {
    if (_circomProofResult == null) {
      setState(() {
        _error = Exception('No proof available to verify');
      });
      return;
    }

    setState(() {
      _error = null;
      isVerifyingOnChain = true;
      _onChainValid = null;
    });

    try {
      // Parse the circom proof result to extract the components
      final ProofCalldata proofData = _circomProofResult!.proof;
      
      // Extract proof components from ProofCalldata
      final List<String> pA = [proofData.a.x, proofData.a.y];
      final List<List<String>> pB = [
        [proofData.b.x[1], proofData.b.x[0]], // Note: B coordinates are swapped for Groth16  
        [proofData.b.y[1], proofData.b.y[0]]
      ];
      final List<String> pC = [proofData.c.x, proofData.c.y];
      
      // Get public signals (inputs)
      final List<dynamic> inputs = _circomProofResult!.inputs;
      final List<String> pubSignals = inputs.map((e) => e.toString()).toList();
      
      print('Public signals: $pubSignals');
      print('Proof pA: $pA');
      print('Proof pB: $pB');
      print('Proof pC: $pC');

      // Create Web3 client
      final httpClient = http.Client();
      final web3client = Web3Client(sepoliaRpcUrl, httpClient);

      // Create contract instance
      final contractAbi = ContractAbi.fromJson(verifierAbi, 'Groth16Verifier');
      final contract = DeployedContract(
        contractAbi,
        EthereumAddress.fromHex(verifierContractAddress),
      );

      // Get the verifyProof function
      final verifyFunction = contract.function('verifyProof');

      print('Calling contract at: $verifierContractAddress');
      print('Function: ${verifyFunction.name}');

      // Call the verifyProof function
      final contractResult = await web3client.call(
        contract: contract,
        function: verifyFunction,
        params: [
          pA.map((e) => BigInt.parse(e)).toList(),
          pB.map((row) => row.map((e) => BigInt.parse(e)).toList()).toList(),
          pC.map((e) => BigInt.parse(e)).toList(),
          pubSignals.map((e) => BigInt.parse(e)).toList(),
        ],
      );

      final bool isValid = contractResult.first as bool;
      print('Contract verification result: $isValid');

      if (mounted) {
        setState(() {
          _onChainValid = isValid;
          isVerifyingOnChain = false;
        });
      }

      await web3client.dispose();
    } catch (e) {
      print('On-chain verification error: $e');
      print('Error type: ${e.runtimeType}');
      if (mounted) {
        setState(() {
          _error = Exception('On-chain verification failed: ${e.toString()}');
          isVerifyingOnChain = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (BuildContext materialContext) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Mopro Wallet Connect'),
              actions: [
                // Wallet Connect button in upper right
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _appKitModal == null
                      ? ElevatedButton.icon(
                          onPressed: isInitializing ? null : () async {
                            await _ensureAppKitInitialized(materialContext);
                          },
                          icon: isInitializing 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.account_balance_wallet),
                          label: Text(isInitializing ? 'Connecting...' : 'Connect Wallet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInitializing ? Colors.grey : Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        )
                      : AppKitModalConnectButton(
                          appKit: _appKitModal!,
                          custom: ElevatedButton.icon(
                            onPressed: () {
                              _appKitModal!.openModalView();
                            },
                            icon: const Icon(Icons.account_balance_wallet),
                            label: const Text('Connect Wallet'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Wallet connection status
                    if (_appKitModal != null)
                      AppKitModalAccountButton(appKitModal: _appKitModal!),
                    const SizedBox(height: 20),
                  
                    const Text(
                      'Circom Zero-Knowledge Proof',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Multiplier Circuit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This circuit proves you know two numbers (a, b) that multiply to a specific result.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Public: a (first number)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            'Private: b (second number)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            'Public: result = a × b (revealed to verifier)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isProving) const CircularProgressIndicator(),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            _error.toString(),
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: _controllerA,
                        decoration: const InputDecoration(
                          labelText: "Public input `a`",
                          hintText: "For example, 5",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: _controllerB,
                        decoration: const InputDecoration(
                          labelText: "Private input `b`",
                          hintText: "For example, 3",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_controllerA.text.isNotEmpty && _controllerB.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Text(
                          'Public result: ${_controllerA.text} × ${_controllerB.text} = ${(int.tryParse(_controllerA.text) ?? 0) * (int.tryParse(_controllerB.text) ?? 0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: (_controllerA.text.isEmpty || 
                                          _controllerB.text.isEmpty || 
                                          isProving) ? null : () async {
                                setState(() {
                                  _error = null;
                                  isProving = true;
                                  // Reset verification results when generating a new proof
                                  _circomValid = null;
                                  _onChainValid = null;
                                });

                                FocusManager.instance.primaryFocus?.unfocus();
                                CircomProofResult? proofResult;
                                try {
                                  var inputs =
                                      '{"a":["${_controllerA.text}"],"b":["${_controllerB.text}"]}';
                                  proofResult =
                                      await _moproFlutterPlugin.generateCircomProof(
                                          "assets/multiplier2_final.zkey", inputs, ProofLib.arkworks);  // DO NOT change the proofLib if you don't build for rapidsnark
                                } on Exception catch (e) {
                                  print("Error: $e");
                                  proofResult = null;
                                  setState(() {
                                    _error = e;
                                  });
                                }

                                if (!mounted) return;

                                setState(() {
                                  isProving = false;
                                  _circomProofResult = proofResult;
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text("Generate Proof"),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: (_controllerA.text.isEmpty || 
                                          _controllerB.text.isEmpty || 
                                          isProving ||
                                          _circomProofResult == null) ? null : () async {
                                setState(() {
                                  _error = null;
                                  isProving = true;
                                });

                                FocusManager.instance.primaryFocus?.unfocus();
                                bool? valid;
                                try {
                                  var proofResult = _circomProofResult;
                                  valid = await _moproFlutterPlugin.verifyCircomProof(
                                      "assets/multiplier2_final.zkey", proofResult!, ProofLib.arkworks); // DO NOT change the proofLib if you don't build for rapidsnark
                                } on Exception catch (e) {
                                  print("Error: $e");
                                  valid = false;
                                  setState(() {
                                    _error = e;
                                  });
                                } on TypeError catch (e) {
                                  print("Error: $e");
                                  valid = false;
                                  setState(() {
                                    _error = Exception(e.toString());
                                  });
                                }

                                if (!mounted) return;

                                setState(() {
                                  _circomValid = valid;
                                  isProving = false;
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text("Verify Proof"),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // On-chain verification button
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          onPressed: (_controllerA.text.isEmpty || 
                                      _controllerB.text.isEmpty || 
                                      isProving ||
                                      isVerifyingOnChain ||
                                      _circomProofResult == null) ? null : () async {
                            await _verifyProofOnChain();
                          },
                          icon: isVerifyingOnChain 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.link),
                          label: Text(isVerifyingOnChain ? 'Verifying On-Chain...' : 'Verify On-Chain (Sepolia)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_circomProofResult != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Proof Results:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Local verification: ${_circomValid ?? "Not verified"}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'On-chain verification: ${_onChainValid ?? "Not verified"}',
                              style: TextStyle(
                                fontSize: 16,
                                color: _onChainValid == true ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Public Inputs: ${_circomProofResult?.inputs ?? ""}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Proof:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                _circomProofResult?.proof.toString() ?? "",
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}
