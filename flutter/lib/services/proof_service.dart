import 'package:flutter/material.dart';
import 'package:mopro_flutter/mopro_flutter.dart';
import 'package:mopro_flutter/mopro_types.dart';
import '../config/app_config.dart';
import '../models/proof_result.dart';

/// Service for handling zero-knowledge proof generation and verification
class ProofService {
  static ProofService? _instance;
  final MoproFlutter _moproFlutterPlugin = MoproFlutter();
  
  ProofService._internal();
  
  static ProofService get instance {
    _instance ??= ProofService._internal();
    return _instance!;
  }
  
  /// Generate a zero-knowledge proof for the given circuit inputs
  Future<ProofResult> generateProof(
    CircuitInputs inputs, {
    String? zkeyPath,
    ProofLib? proofLib,
  }) async {
    debugPrint('[ProofService] Generating proof for inputs: a=${inputs.a}, b=${inputs.b}');
    
    try {
      if (!inputs.isValid) {
        throw Exception('Invalid circuit inputs: both a and b must be valid numbers');
      }
      
      final finalZkeyPath = zkeyPath ?? AppConfig.zkeyPath;
      final finalProofLib = proofLib ?? ProofLib.arkworks;
      
      final CircomProofResult? circomProof = await _moproFlutterPlugin.generateCircomProof(
        finalZkeyPath,
        inputs.toJson(),
        finalProofLib,
      );
      
      if (circomProof == null) {
        throw Exception('Proof generation failed: received null result');
      }
      
      debugPrint('[ProofService] Proof generated successfully');
      
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
  Future<ProofResult> verifyProofLocally(
    ProofResult proofResult, {
    String? zkeyPath,
    ProofLib? proofLib,
  }) async {
    debugPrint('[ProofService] Verifying proof locally');
    
    try {
      if (proofResult.circomProof == null) {
        throw Exception('No proof available to verify');
      }
      
      final finalZkeyPath = zkeyPath ?? AppConfig.zkeyPath;
      final finalProofLib = proofLib ?? ProofLib.arkworks;
      
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
  Future<ProofResult> generateAndVerifyProof(
    CircuitInputs inputs, {
    String? zkeyPath,
    ProofLib? proofLib,
  }) async {
    debugPrint('[ProofService] Generating and verifying proof');
    
    final proofResult = await generateProof(
      inputs,
      zkeyPath: zkeyPath,
      proofLib: proofLib,
    );
    
    if (proofResult.hasError || !proofResult.hasProof) {
      return proofResult;
    }
    
    return await verifyProofLocally(
      proofResult,
      zkeyPath: zkeyPath,
      proofLib: proofLib,
    );
  }
  
  /// Extract proof components for on-chain verification
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
        [proofData.b.x[1], proofData.b.x[0]], // B coordinates are swapped for Groth16
        [proofData.b.y[1], proofData.b.y[0]]
      ];
      final List<String> pC = [proofData.c.x, proofData.c.y];
      
      // Get public signals (inputs)
      final List<dynamic> inputs = proofResult.circomProof!.inputs;
      final List<String> pubSignals = inputs.map((e) => e.toString()).toList();
      
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
  
  /// Get circuit information
  Map<String, dynamic> getCircuitInfo() {
    return {
      'name': AppConfig.circuitName,
      'description': AppConfig.circuitDescription,
      'zkeyPath': AppConfig.zkeyPath,
      'proofSystem': 'Groth16',
      'curve': 'bn128',
      'inputFields': ['a', 'b'],
      'outputFields': ['result'],
    };
  }
} 