import 'package:flutter/material.dart';
import 'package:mopro_flutter/mopro_flutter.dart';
import 'package:mopro_flutter/mopro_types.dart';
import '../config/app_config.dart';
import '../models/proof_result.dart';

/// Service for handling zero-knowledge proof generation and verification
/// 
/// This service encapsulates all ZK proof functionality, making it easy
/// for developers to integrate zero-knowledge proofs into their dApps.
class ProofService {
  static ProofService? _instance;
  final MoproFlutter _moproFlutterPlugin = MoproFlutter();
  
  ProofService._internal();
  
  /// Get the singleton instance of ProofService
  static ProofService get instance {
    _instance ??= ProofService._internal();
    return _instance!;
  }
  
  /// Generate a zero-knowledge proof for the given circuit inputs
  /// 
  /// This method takes circuit inputs and generates a Groth16 proof
  /// that can be verified both locally and on-chain.
  /// 
  /// [inputs] - The circuit inputs containing the values to prove
  /// [zkeyPath] - Optional path to the zkey file (defaults to config)
  /// [proofLib] - Optional proof library to use (defaults to arkworks)
  /// 
  /// Returns a [ProofResult] containing the generated proof or error information
  Future<ProofResult> generateProof(
    CircuitInputs inputs, {
    String? zkeyPath,
    ProofLib? proofLib,
  }) async {
    debugPrint('[ProofService] Generating proof for inputs: a=${inputs.a}, b=${inputs.b}');
    
    try {
      // Validate inputs
      if (!inputs.isValid) {
        throw Exception('Invalid circuit inputs: both a and b must be valid numbers');
      }
      
      // Use default values if not provided
      final finalZkeyPath = zkeyPath ?? AppConfig.zkeyPath;
      final finalProofLib = proofLib ?? ProofLib.arkworks;
      
      debugPrint('[ProofService] Using zkey path: $finalZkeyPath');
      debugPrint('[ProofService] Using proof library: $finalProofLib');
      
      // Generate the proof
      final CircomProofResult? circomProof = await _moproFlutterPlugin.generateCircomProof(
        finalZkeyPath,
        inputs.toJson(),
        finalProofLib,
      );
      
      if (circomProof == null) {
        throw Exception('Proof generation failed: received null result');
      }
      
      debugPrint('[ProofService] Proof generated successfully');
      debugPrint('[ProofService] Public inputs: ${circomProof.inputs}');
      
      return ProofResult(
        circomProof: circomProof,
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      debugPrint('[ProofService] Error generating proof: $e');
      return ProofResult(
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }
  
  /// Verify a zero-knowledge proof locally
  /// 
  /// This method verifies a proof using the local verification key,
  /// without requiring any network connection.
  /// 
  /// [proofResult] - The proof result containing the proof to verify
  /// [zkeyPath] - Optional path to the zkey file (defaults to config)
  /// [proofLib] - Optional proof library to use (defaults to arkworks)
  /// 
  /// Returns an updated [ProofResult] with the verification result
  Future<ProofResult> verifyProofLocally(
    ProofResult proofResult, {
    String? zkeyPath,
    ProofLib? proofLib,
  }) async {
    debugPrint('[ProofService] Verifying proof locally');
    
    try {
      // Check if proof exists
      if (proofResult.circomProof == null) {
        throw Exception('No proof available to verify');
      }
      
      // Use default values if not provided
      final finalZkeyPath = zkeyPath ?? AppConfig.zkeyPath;
      final finalProofLib = proofLib ?? ProofLib.arkworks;
      
      debugPrint('[ProofService] Using zkey path: $finalZkeyPath');
      debugPrint('[ProofService] Using proof library: $finalProofLib');
      
      // Verify the proof
      final bool isValid = await _moproFlutterPlugin.verifyCircomProof(
        finalZkeyPath,
        proofResult.circomProof!,
        finalProofLib,
      );
      
      debugPrint('[ProofService] Local verification result: $isValid');
      
      return proofResult.copyWith(
        localVerification: isValid,
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      debugPrint('[ProofService] Error verifying proof locally: $e');
      return proofResult.copyWith(
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }
  
  /// Generate and verify a proof in one step
  /// 
  /// This is a convenience method that combines proof generation and
  /// local verification in a single operation.
  /// 
  /// [inputs] - The circuit inputs containing the values to prove
  /// [zkeyPath] - Optional path to the zkey file (defaults to config)
  /// [proofLib] - Optional proof library to use (defaults to arkworks)
  /// 
  /// Returns a [ProofResult] with both generation and verification results
  Future<ProofResult> generateAndVerifyProof(
    CircuitInputs inputs, {
    String? zkeyPath,
    ProofLib? proofLib,
  }) async {
    debugPrint('[ProofService] Generating and verifying proof');
    
    // Generate the proof
    final proofResult = await generateProof(
      inputs,
      zkeyPath: zkeyPath,
      proofLib: proofLib,
    );
    
    // If generation failed, return early
    if (proofResult.hasError || !proofResult.hasProof) {
      return proofResult;
    }
    
    // Verify the proof locally
    return await verifyProofLocally(
      proofResult,
      zkeyPath: zkeyPath,
      proofLib: proofLib,
    );
  }
  
  /// Extract proof components for on-chain verification
  /// 
  /// This method extracts the proof components in the format required
  /// for Solidity verifier contracts.
  /// 
  /// [proofResult] - The proof result containing the proof to extract
  /// 
  /// Returns a map containing the formatted proof components
  Map<String, dynamic>? extractProofComponents(ProofResult proofResult) {
    if (proofResult.circomProof == null) {
      debugPrint('[ProofService] No proof available to extract components');
      return null;
    }
    
    try {
      final ProofCalldata proofData = proofResult.circomProof!.proof;
      
      // Extract proof components from ProofCalldata
      final List<String> pA = [proofData.a.x, proofData.a.y];
      final List<List<String>> pB = [
        [proofData.b.x[1], proofData.b.x[0]], // Note: B coordinates are swapped for Groth16
        [proofData.b.y[1], proofData.b.y[0]]
      ];
      final List<String> pC = [proofData.c.x, proofData.c.y];
      
      // Get public signals (inputs)
      final List<dynamic> inputs = proofResult.circomProof!.inputs;
      final List<String> pubSignals = inputs.map((e) => e.toString()).toList();
      
      debugPrint('[ProofService] Extracted proof components:');
      debugPrint('[ProofService] pA: $pA');
      debugPrint('[ProofService] pB: $pB');
      debugPrint('[ProofService] pC: $pC');
      debugPrint('[ProofService] pubSignals: $pubSignals');
      
      return {
        'pA': pA,
        'pB': pB,
        'pC': pC,
        'pubSignals': pubSignals,
      };
      
    } catch (e) {
      debugPrint('[ProofService] Error extracting proof components: $e');
      return null;
    }
  }
  
  /// Validate circuit inputs
  /// 
  /// This method validates that the circuit inputs are in the correct
  /// format and within acceptable ranges.
  /// 
  /// [inputs] - The circuit inputs to validate
  /// 
  /// Returns true if inputs are valid, false otherwise
  bool validateInputs(CircuitInputs inputs) {
    try {
      // Check if inputs are valid numbers
      if (!inputs.isValid) {
        debugPrint('[ProofService] Invalid inputs: not valid numbers');
        return false;
      }
      
      // Parse values to check ranges
      final aValue = int.parse(inputs.a);
      final bValue = int.parse(inputs.b);
      
      // Check for reasonable ranges (adjust as needed for your circuit)
      if (aValue < 0 || bValue < 0) {
        debugPrint('[ProofService] Invalid inputs: negative values not allowed');
        return false;
      }
      
      if (aValue > 1000000 || bValue > 1000000) {
        debugPrint('[ProofService] Invalid inputs: values too large');
        return false;
      }
      
      debugPrint('[ProofService] Inputs validated successfully');
      return true;
      
    } catch (e) {
      debugPrint('[ProofService] Error validating inputs: $e');
      return false;
    }
  }
  
  /// Get information about the current circuit
  /// 
  /// Returns information about the circuit that's being used for proof generation.
  Map<String, dynamic> getCircuitInfo() {
    return {
      'name': AppConfig.circuitName,
      'description': AppConfig.circuitDescription,
      'zkeyPath': AppConfig.zkeyPath,
      'inputFields': ['a', 'b'],
      'outputFields': ['result'],
      'proofSystem': 'Groth16',
      'curve': 'bn128',
    };
  }
  
  /// Clean up resources
  /// 
  /// Call this method when the app is being disposed to clean up
  /// any resources used by the proof service.
  void dispose() {
    _instance = null;
    debugPrint('[ProofService] Service disposed');
  }
} 