import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/proof_result.dart';
import '../services/proof_service.dart';
import '../services/blockchain_service.dart';
import '../widgets/circuit_info.dart';

/// A widget that provides a form for entering circuit inputs and generating proofs
/// 
/// This widget handles the entire proof generation and verification workflow,
/// providing a clean interface for users to interact with the ZK system.
class ProofForm extends StatefulWidget {
  final Function(ProofResult)? onProofGenerated;
  final Function(ProofResult)? onProofVerified;
  final Function(ProofResult)? onOnChainVerified;
  final Function(String)? onError;
  final CircuitInputs? initialInputs;
  final bool showCircuitInfo;
  final bool enableOnChainVerification;

  const ProofForm({
    Key? key,
    this.onProofGenerated,
    this.onProofVerified,
    this.onOnChainVerified,
    this.onError,
    this.initialInputs,
    this.showCircuitInfo = true,
    this.enableOnChainVerification = true,
  }) : super(key: key);

  @override
  State<ProofForm> createState() => _ProofFormState();
}

class _ProofFormState extends State<ProofForm> {
  final ProofService _proofService = ProofService.instance;
  final BlockchainService _blockchainService = BlockchainService.instance;
  
  late TextEditingController _controllerA;
  late TextEditingController _controllerB;
  
  ProofResult _currentProofResult = ProofResult();
  bool _isProving = false;
  bool _isVerifyingOnChain = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    final initialInputs = widget.initialInputs ?? 
        CircuitInputs(a: AppConfig.defaultInputA, b: AppConfig.defaultInputB);
    
    _controllerA = TextEditingController(text: initialInputs.a);
    _controllerB = TextEditingController(text: initialInputs.b);
    
    // Add listeners to update UI when text changes
    _controllerA.addListener(() => setState(() {}));
    _controllerB.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controllerA.dispose();
    _controllerB.dispose();
    super.dispose();
  }

  CircuitInputs get _currentInputs => CircuitInputs(
    a: _controllerA.text,
    b: _controllerB.text,
  );

  bool get _canGenerateProof => _currentInputs.isValid && !_isProving;
  bool get _canVerifyLocally => _currentInputs.isValid && !_isProving && _currentProofResult.hasProof;
  bool get _canVerifyOnChain => _currentInputs.isValid && !_isProving && !_isVerifyingOnChain && _currentProofResult.hasProof;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Circuit Information
          if (widget.showCircuitInfo) ...[
            const CircuitInfo(),
            const SizedBox(height: 20),
          ],
          
          // Loading indicator
          if (_isProving || _isVerifyingOnChain)
            const Center(child: CircularProgressIndicator()),
          
          // Error message
          if (_error != null) ...[
            _buildErrorMessage(),
            const SizedBox(height: 16),
          ],
          
          // Input form
          _buildInputForm(),
          
          const SizedBox(height: 16),
          
          // Expected result display
          if (_currentInputs.isValid) ...[
            _buildExpectedResult(),
            const SizedBox(height: 16),
          ],
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _error = null),
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Column(
      children: [
        // Input A
        TextFormField(
          controller: _controllerA,
          decoration: const InputDecoration(
            labelText: "Public input `a`",
            hintText: "For example, 5",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.visibility),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => _resetProofResults(),
        ),
        
        const SizedBox(height: 16),
        
        // Input B
        TextFormField(
          controller: _controllerB,
          decoration: const InputDecoration(
            labelText: "Private input `b`",
            hintText: "For example, 3",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.visibility_off),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => _resetProofResults(),
        ),
      ],
    );
  }

  Widget _buildExpectedResult() {
    return CircuitInfoCompact(
      title: 'Expected Result',
      description: '${_controllerA.text} × ${_controllerB.text} = ${_currentInputs.expectedResult}',
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Generate and Verify buttons row
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _canGenerateProof ? _generateProof : null,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("Generate Proof"),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _canVerifyLocally ? _verifyProofLocally : null,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("Verify Proof"),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // On-chain verification button
        if (widget.enableOnChainVerification)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canVerifyOnChain ? _verifyProofOnChain : null,
              icon: _isVerifyingOnChain 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link),
              label: Text(_isVerifyingOnChain ? 'Verifying On-Chain...' : 'Verify On-Chain (Sepolia)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16.0),
              ),
            ),
          ),
      ],
    );
  }

  void _resetProofResults() {
    setState(() {
      _currentProofResult = ProofResult();
      _error = null;
    });
  }

  Future<void> _generateProof() async {
    setState(() {
      _isProving = true;
      _error = null;
    });

    try {
      final result = await _proofService.generateProof(_currentInputs);
      
      setState(() {
        _currentProofResult = result;
        _isProving = false;
      });
      
      if (result.hasError) {
        setState(() {
          _error = result.error;
        });
        widget.onError?.call(result.error!);
      } else {
        widget.onProofGenerated?.call(result);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProving = false;
      });
      widget.onError?.call(e.toString());
    }
  }

  Future<void> _verifyProofLocally() async {
    setState(() {
      _isProving = true;
      _error = null;
    });

    try {
      final result = await _proofService.verifyProofLocally(_currentProofResult);
      
      setState(() {
        _currentProofResult = result;
        _isProving = false;
      });
      
      if (result.hasError) {
        setState(() {
          _error = result.error;
        });
        widget.onError?.call(result.error!);
      } else {
        widget.onProofVerified?.call(result);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProving = false;
      });
      widget.onError?.call(e.toString());
    }
  }

  Future<void> _verifyProofOnChain() async {
    setState(() {
      _isVerifyingOnChain = true;
      _error = null;
    });

    try {
      final result = await _blockchainService.verifyProofOnChain(_currentProofResult);
      
      setState(() {
        _currentProofResult = result;
        _isVerifyingOnChain = false;
      });
      
      if (result.hasError) {
        setState(() {
          _error = result.error;
        });
        widget.onError?.call(result.error!);
      } else {
        widget.onOnChainVerified?.call(result);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isVerifyingOnChain = false;
      });
      widget.onError?.call(e.toString());
    }
  }

  /// Get the current proof result
  ProofResult get currentProofResult => _currentProofResult;
  
  /// Get the current circuit inputs
  CircuitInputs get currentInputs => _currentInputs;
  
  /// Check if the form is currently processing
  bool get isProcessing => _isProving || _isVerifyingOnChain;
} 