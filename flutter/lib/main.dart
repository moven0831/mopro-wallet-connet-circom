import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mopro_flutter/mopro_flutter.dart';
import 'package:mopro_flutter/mopro_types.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  CircomProofResult? _circomProofResult;
  bool? _circomValid;
  final _moproFlutterPlugin = MoproFlutter();
  bool isProving = false;
  Exception? _error;

  // Controllers to handle user input
  final TextEditingController _controllerA = TextEditingController();
  final TextEditingController _controllerB = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controllerA.text = "5";
    _controllerB.text = "3";
  }

  @override
  void dispose() {
    _controllerA.dispose();
    _controllerB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Circom Proof Generator'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isProving) const CircularProgressIndicator(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_error.toString()),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _controllerA,
                    decoration: const InputDecoration(
                      labelText: "Public input `a`",
                      hintText: "For example, 5",
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
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton(
                          onPressed: () async {
                            if (_controllerA.text.isEmpty ||
                                _controllerB.text.isEmpty ||
                                isProving) {
                              return;
                            }
                            setState(() {
                              _error = null;
                              isProving = true;
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
                          child: const Text("Generate Proof")),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton(
                          onPressed: () async {
                            if (_controllerA.text.isEmpty ||
                                _controllerB.text.isEmpty ||
                                isProving) {
                              return;
                            }
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
                              isProving = false;
                              _circomValid = valid;
                            });
                          },
                          child: const Text("Verify Proof")),
                    ),
                  ],
                ),
                if (_circomProofResult != null)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Proof is valid: ${_circomValid ?? false}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:
                            Text('Proof inputs: ${_circomProofResult?.inputs ?? ""}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Proof: ${_circomProofResult?.proof ?? ""}'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
