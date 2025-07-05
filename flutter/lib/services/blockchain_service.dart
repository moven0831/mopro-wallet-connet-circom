import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import '../config/network_config.dart';
import '../models/proof_result.dart';
import '../services/proof_service.dart';

/// Service for handling on-chain verification of zero-knowledge proofs
/// 
/// This service encapsulates all blockchain-related functionality,
/// making it easy for developers to verify proofs on-chain.
class BlockchainService {
  static BlockchainService? _instance;
  Web3Client? _web3Client;
  http.Client? _httpClient;
  
  BlockchainService._internal();
  
  /// Get the singleton instance of BlockchainService
  static BlockchainService get instance {
    _instance ??= BlockchainService._internal();
    return _instance!;
  }
  
  /// Initialize the blockchain service with a specific network
  /// 
  /// [networkKey] - The network key from NetworkConfig.networks
  /// [customRpcUrl] - Optional custom RPC URL to use instead of default
  Future<void> initialize({
    String networkKey = 'sepolia',
    String? customRpcUrl,
  }) async {
    debugPrint('[BlockchainService] Initializing with network: $networkKey');
    
    try {
      await dispose(); // Clean up any existing connections
      
      final rpcUrl = customRpcUrl ?? NetworkConfig.getRpcUrl(networkKey);
      debugPrint('[BlockchainService] Using RPC URL: $rpcUrl');
      
      _httpClient = http.Client();
      _web3Client = Web3Client(rpcUrl, _httpClient!);
      
      // Test the connection
      await _web3Client!.getBlockNumber();
      debugPrint('[BlockchainService] Successfully connected to blockchain');
      
    } catch (e) {
      debugPrint('[BlockchainService] Error initializing: $e');
      await dispose();
      rethrow;
    }
  }
  
  /// Verify a zero-knowledge proof on-chain
  /// 
  /// This method takes a proof result and verifies it using the
  /// deployed Solidity verifier contract.
  /// 
  /// [proofResult] - The proof result containing the proof to verify
  /// [contractAddress] - Optional custom contract address (defaults to config)
  /// [networkKey] - The network to use for verification (defaults to sepolia)
  /// 
  /// Returns an updated [ProofResult] with the on-chain verification result
  Future<ProofResult> verifyProofOnChain(
    ProofResult proofResult, {
    String? contractAddress,
    String networkKey = 'sepolia',
  }) async {
    debugPrint('[BlockchainService] Starting on-chain verification');
    
    try {
      // Ensure we have a proof to verify
      if (proofResult.circomProof == null) {
        throw Exception('No proof available to verify');
      }
      
      // Initialize if not already done
      if (_web3Client == null) {
        await initialize(networkKey: networkKey);
      }
      
      // Extract proof components
      final proofComponents = ProofService.instance.extractProofComponents(proofResult);
      if (proofComponents == null) {
        throw Exception('Failed to extract proof components');
      }
      
      // Use default contract address if not provided
      final finalContractAddress = contractAddress ?? NetworkConfig.verifierContractAddress;
      debugPrint('[BlockchainService] Using contract address: $finalContractAddress');
      
      // Create contract instance
      final contractAbi = ContractAbi.fromJson(
        NetworkConfig.verifierContractAbi,
        'Groth16Verifier',
      );
      final contract = DeployedContract(
        contractAbi,
        EthereumAddress.fromHex(finalContractAddress),
      );
      
      // Get the verifyProof function
      final verifyFunction = contract.function('verifyProof');
      debugPrint('[BlockchainService] Calling verifyProof function');
      
      // Prepare parameters
      final pA = (proofComponents['pA'] as List<String>)
          .map((e) => BigInt.parse(e))
          .toList();
      final pB = (proofComponents['pB'] as List<List<String>>)
          .map((row) => row.map((e) => BigInt.parse(e)).toList())
          .toList();
      final pC = (proofComponents['pC'] as List<String>)
          .map((e) => BigInt.parse(e))
          .toList();
      final pubSignals = (proofComponents['pubSignals'] as List<String>)
          .map((e) => BigInt.parse(e))
          .toList();
      
      debugPrint('[BlockchainService] Proof parameters prepared');
      
      // Call the verifyProof function
      final contractResult = await _web3Client!.call(
        contract: contract,
        function: verifyFunction,
        params: [pA, pB, pC, pubSignals],
      );
      
      final bool isValid = contractResult.first as bool;
      debugPrint('[BlockchainService] On-chain verification result: $isValid');
      
      return proofResult.copyWith(
        onChainVerification: isValid,
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      debugPrint('[BlockchainService] Error during on-chain verification: $e');
      return proofResult.copyWith(
        error: 'On-chain verification failed: ${e.toString()}',
        timestamp: DateTime.now(),
      );
    }
  }
  
  /// Get the current block number
  /// 
  /// This method returns the current block number from the connected network.
  /// Useful for checking connectivity and getting network status.
  Future<int> getCurrentBlockNumber() async {
    if (_web3Client == null) {
      throw Exception('BlockchainService not initialized');
    }
    
    try {
      final blockNumber = await _web3Client!.getBlockNumber();
      debugPrint('[BlockchainService] Current block number: $blockNumber');
      return blockNumber;
    } catch (e) {
      debugPrint('[BlockchainService] Error getting block number: $e');
      rethrow;
    }
  }
  
  /// Get network information
  /// 
  /// Returns information about the currently connected network.
  Future<Map<String, dynamic>> getNetworkInfo() async {
    if (_web3Client == null) {
      throw Exception('BlockchainService not initialized');
    }
    
    try {
      final blockNumber = await _web3Client!.getBlockNumber();
      final chainId = await _web3Client!.getChainId();
      
      return {
        'blockNumber': blockNumber,
        'chainId': chainId,
        'isConnected': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('[BlockchainService] Error getting network info: $e');
      return {
        'isConnected': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Check if the verifier contract is deployed
  /// 
  /// This method checks if the verifier contract exists at the specified address.
  /// 
  /// [contractAddress] - Optional custom contract address (defaults to config)
  Future<bool> isVerifierContractDeployed({String? contractAddress}) async {
    if (_web3Client == null) {
      throw Exception('BlockchainService not initialized');
    }
    
    try {
      final finalContractAddress = contractAddress ?? NetworkConfig.verifierContractAddress;
      final code = await _web3Client!.getCode(EthereumAddress.fromHex(finalContractAddress));
      
      final isDeployed = code.isNotEmpty;
      debugPrint('[BlockchainService] Contract deployed: $isDeployed at $finalContractAddress');
      return isDeployed;
      
    } catch (e) {
      debugPrint('[BlockchainService] Error checking contract deployment: $e');
      return false;
    }
  }
  
  /// Get the verifier contract address
  /// 
  /// Returns the address of the verifier contract being used.
  String getVerifierContractAddress() {
    return NetworkConfig.verifierContractAddress;
  }
  
  /// Get the block explorer URL for a transaction
  /// 
  /// [txHash] - The transaction hash
  /// [networkKey] - The network key (defaults to sepolia)
  /// 
  /// Returns the block explorer URL for the transaction
  String getBlockExplorerUrl(String txHash, {String networkKey = 'sepolia'}) {
    final network = NetworkConfig.networks[networkKey];
    if (network == null) {
      return '';
    }
    
    return '${network.blockExplorerUrl}/tx/$txHash';
  }
  
  /// Get the block explorer URL for a contract
  /// 
  /// [contractAddress] - The contract address
  /// [networkKey] - The network key (defaults to sepolia)
  /// 
  /// Returns the block explorer URL for the contract
  String getContractExplorerUrl(String contractAddress, {String networkKey = 'sepolia'}) {
    final network = NetworkConfig.networks[networkKey];
    if (network == null) {
      return '';
    }
    
    return '${network.blockExplorerUrl}/address/$contractAddress';
  }
  
  /// Estimate gas for proof verification
  /// 
  /// This method estimates the gas cost for verifying a proof on-chain.
  /// 
  /// [proofResult] - The proof result containing the proof to verify
  /// [contractAddress] - Optional custom contract address (defaults to config)
  /// [from] - Optional from address for estimation
  /// 
  /// Returns the estimated gas amount
  Future<BigInt> estimateVerificationGas(
    ProofResult proofResult, {
    String? contractAddress,
    EthereumAddress? from,
  }) async {
    if (_web3Client == null) {
      throw Exception('BlockchainService not initialized');
    }
    
    try {
      // Extract proof components
      final proofComponents = ProofService.instance.extractProofComponents(proofResult);
      if (proofComponents == null) {
        throw Exception('Failed to extract proof components');
      }
      
      // Use default contract address if not provided
      final finalContractAddress = contractAddress ?? NetworkConfig.verifierContractAddress;
      
      // Create contract instance
      final contractAbi = ContractAbi.fromJson(
        NetworkConfig.verifierContractAbi,
        'Groth16Verifier',
      );
      final contract = DeployedContract(
        contractAbi,
        EthereumAddress.fromHex(finalContractAddress),
      );
      
      // Get the verifyProof function
      final verifyFunction = contract.function('verifyProof');
      
      // Prepare parameters
      final pA = (proofComponents['pA'] as List<String>)
          .map((e) => BigInt.parse(e))
          .toList();
      final pB = (proofComponents['pB'] as List<List<String>>)
          .map((row) => row.map((e) => BigInt.parse(e)).toList())
          .toList();
      final pC = (proofComponents['pC'] as List<String>)
          .map((e) => BigInt.parse(e))
          .toList();
      final pubSignals = (proofComponents['pubSignals'] as List<String>)
          .map((e) => BigInt.parse(e))
          .toList();
      
      // Estimate gas
      final gasEstimate = await _web3Client!.estimateGas(
        sender: from ?? EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'),
        to: EthereumAddress.fromHex(finalContractAddress),
        data: verifyFunction.encodeCall([pA, pB, pC, pubSignals]),
      );
      
      debugPrint('[BlockchainService] Estimated gas: $gasEstimate');
      return gasEstimate;
      
    } catch (e) {
      debugPrint('[BlockchainService] Error estimating gas: $e');
      // Return a reasonable default if estimation fails
      return BigInt.from(500000);
    }
  }
  
  /// Clean up resources
  /// 
  /// Call this method when the app is being disposed to clean up
  /// any resources used by the blockchain service.
  Future<void> dispose() async {
    if (_web3Client != null) {
      await _web3Client!.dispose();
      _web3Client = null;
    }
    
    if (_httpClient != null) {
      _httpClient!.close();
      _httpClient = null;
    }
    
    _instance = null;
    debugPrint('[BlockchainService] Service disposed');
  }
} 