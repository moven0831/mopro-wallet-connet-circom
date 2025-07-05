import 'package:mopro_flutter/mopro_types.dart';

/// Model for storing proof generation and verification results
class ProofResult {
  final CircomProofResult? circomProof;
  final bool? localVerification;
  final bool? onChainVerification;
  final String? error;
  final DateTime timestamp;
  
  ProofResult({
    this.circomProof,
    this.localVerification,
    this.onChainVerification,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Create a copy of this ProofResult with updated fields
  ProofResult copyWith({
    CircomProofResult? circomProof,
    bool? localVerification,
    bool? onChainVerification,
    String? error,
    DateTime? timestamp,
  }) {
    return ProofResult(
      circomProof: circomProof ?? this.circomProof,
      localVerification: localVerification ?? this.localVerification,
      onChainVerification: onChainVerification ?? this.onChainVerification,
      error: error ?? this.error,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  /// Check if there's a proof available
  bool get hasProof => circomProof != null;
  
  /// Check if local verification was successful
  bool get isLocallyVerified => localVerification == true;
  
  /// Check if on-chain verification was successful
  bool get isOnChainVerified => onChainVerification == true;
  
  /// Check if there's an error
  bool get hasError => error != null;
  
  /// Get the public inputs from the proof
  List<dynamic> get publicInputs => circomProof?.inputs ?? [];
  
  /// Get the proof data
  ProofCalldata? get proofData => circomProof?.proof;
}

/// Model for storing circuit inputs
class CircuitInputs {
  final String a;
  final String b;
  
  CircuitInputs({
    required this.a,
    required this.b,
  });
  
  /// Create JSON string for the circuit inputs
  String toJson() {
    return '{"a":["$a"],"b":["$b"]}';
  }
  
  /// Calculate the expected result
  int get expectedResult {
    final aValue = int.tryParse(a) ?? 0;
    final bValue = int.tryParse(b) ?? 0;
    return aValue * bValue;
  }
  
  /// Check if inputs are valid
  bool get isValid {
    return a.isNotEmpty && b.isNotEmpty && 
           int.tryParse(a) != null && int.tryParse(b) != null;
  }
  
  /// Create a copy with updated values
  CircuitInputs copyWith({
    String? a,
    String? b,
  }) {
    return CircuitInputs(
      a: a ?? this.a,
      b: b ?? this.b,
    );
  }
}

/// Model for application state
class AppState {
  final bool isInitializing;
  final bool isProving;
  final bool isVerifyingOnChain;
  final bool isWalletConnected;
  final String? walletAddress;
  final String? selectedNetwork;
  final CircuitInputs inputs;
  final ProofResult proofResult;
  
  AppState({
    this.isInitializing = false,
    this.isProving = false,
    this.isVerifyingOnChain = false,
    this.isWalletConnected = false,
    this.walletAddress,
    this.selectedNetwork,
    CircuitInputs? inputs,
    ProofResult? proofResult,
  }) : inputs = inputs ?? CircuitInputs(a: '5', b: '3'),
       proofResult = proofResult ?? ProofResult();
  
  /// Create a copy of this AppState with updated fields
  AppState copyWith({
    bool? isInitializing,
    bool? isProving,
    bool? isVerifyingOnChain,
    bool? isWalletConnected,
    String? walletAddress,
    String? selectedNetwork,
    CircuitInputs? inputs,
    ProofResult? proofResult,
  }) {
    return AppState(
      isInitializing: isInitializing ?? this.isInitializing,
      isProving: isProving ?? this.isProving,
      isVerifyingOnChain: isVerifyingOnChain ?? this.isVerifyingOnChain,
      isWalletConnected: isWalletConnected ?? this.isWalletConnected,
      walletAddress: walletAddress ?? this.walletAddress,
      selectedNetwork: selectedNetwork ?? this.selectedNetwork,
      inputs: inputs ?? this.inputs,
      proofResult: proofResult ?? this.proofResult,
    );
  }
  
  /// Check if any operation is in progress
  bool get isLoading => isInitializing || isProving || isVerifyingOnChain;
  
  /// Check if all inputs are valid
  bool get hasValidInputs => inputs.isValid;
  
  /// Check if proof generation is possible
  bool get canGenerateProof => hasValidInputs && !isLoading;
  
  /// Check if local verification is possible
  bool get canVerifyLocally => hasValidInputs && !isLoading && proofResult.hasProof;
  
  /// Check if on-chain verification is possible
  bool get canVerifyOnChain => hasValidInputs && !isLoading && proofResult.hasProof;
} 