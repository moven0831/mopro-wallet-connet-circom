import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import '../config/network_config.dart';
import '../models/proof_result.dart';
import '../services/proof_service.dart';

/// Service for handling on-chain verification of zero-knowledge proofs
class BlockchainService {
  static BlockchainService? _instance;
  Web3Client? _web3Client;
  http.Client? _httpClient;
  
  BlockchainService._internal();
  
  static BlockchainService get instance {
    _instance ??= BlockchainService._internal();
    return _instance!;
  }
  
  /// Initialize the blockchain service with a specific network
  Future<void> initialize({
    String networkKey = 'sepolia',
    String? customRpcUrl,
  }) async {
    debugPrint('[BlockchainService] Initializing with network: $networkKey');
    
    try {
      await dispose();
      
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
  Future<ProofResult> verifyProofOnChain(
    ProofResult proofResult, {
    String? contractAddress,
    String networkKey = 'sepolia',
  }) async {
    debugPrint('[BlockchainService] Starting on-chain verification');
    
    try {
      if (proofResult.circomProof == null) {
        throw Exception('No proof available to verify');
      }
      
      if (_web3Client == null) {
        await initialize(networkKey: networkKey);
      }
      
      final proofComponents = ProofService.instance.extractProofComponents(proofResult);
      if (proofComponents == null) {
        throw Exception('Failed to extract proof components');
      }
      
      final finalContractAddress = contractAddress ?? NetworkConfig.verifierContractAddress;
      debugPrint('[BlockchainService] Using contract address: $finalContractAddress');
      
      final contractAbi = ContractAbi.fromJson(
        NetworkConfig.verifierContractAbi,
        'Groth16Verifier',
      );
      final contract = DeployedContract(
        contractAbi,
        EthereumAddress.fromHex(finalContractAddress),
      );
      
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
  Future<bool> isVerifierContractDeployed({String? contractAddress}) async {
    if (_web3Client == null) {
      throw Exception('BlockchainService not initialized');
    }
    
    try {
      final address = contractAddress ?? NetworkConfig.verifierContractAddress;
      final code = await _web3Client!.getCode(EthereumAddress.fromHex(address));
      return code.isNotEmpty;
    } catch (e) {
      debugPrint('[BlockchainService] Error checking contract deployment: $e');
      return false;
    }
  }
  
  /// Clean up resources
  Future<void> dispose() async {
    try {
      _httpClient?.close();
      await _web3Client?.dispose();
    } catch (e) {
      debugPrint('[BlockchainService] Error during cleanup: $e');
    } finally {
      _httpClient = null;
      _web3Client = null;
    }
    debugPrint('[BlockchainService] Service disposed');
  }
} 