/// Configuration file for blockchain network settings
/// 
/// This file contains all the network-related configuration values
/// that developers can easily modify to use different chains or contracts.
class NetworkConfig {
  // Supported Chains
  static const List<String> supportedChains = [
    'eip155:1',        // Ethereum Mainnet
    'eip155:137',      // Polygon
    'eip155:11155111', // Sepolia Testnet
  ];
  
  // RPC URLs
  static const String sepoliaRpcUrl = 'https://ethereum-sepolia-rpc.publicnode.com';
  static const String mainnetRpcUrl = 'https://ethereum-rpc.publicnode.com';
  static const String polygonRpcUrl = 'https://polygon-rpc.com';
  
  // Smart Contract Configuration
  static const String verifierContractAddress = '0x01AfBba5fB7D57a37D2B8CE1CCA4DC696ed358FE';
  static const String verifierContractAbi = '''[
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
  
  // Supported Wallet Methods
  static const List<String> supportedMethods = [
    'eth_sendTransaction',
    'eth_signTransaction',
    'eth_sign',
    'personal_sign',
    'eth_signTypedData',
  ];
  
  // Supported Events
  static const List<String> supportedEvents = [
    'chainChanged',
    'accountsChanged',
  ];
  
  // Network Information
  static const Map<String, NetworkInfo> networks = {
    'sepolia': NetworkInfo(
      name: 'Sepolia',
      chainId: 'eip155:11155111',
      rpcUrl: sepoliaRpcUrl,
      blockExplorerUrl: 'https://sepolia.etherscan.io',
      isTestnet: true,
    ),
    'mainnet': NetworkInfo(
      name: 'Ethereum',
      chainId: 'eip155:1',
      rpcUrl: mainnetRpcUrl,
      blockExplorerUrl: 'https://etherscan.io',
      isTestnet: false,
    ),
    'polygon': NetworkInfo(
      name: 'Polygon',
      chainId: 'eip155:137',
      rpcUrl: polygonRpcUrl,
      blockExplorerUrl: 'https://polygonscan.com',
      isTestnet: false,
    ),
  };
  
  /// Get the default network (Sepolia for testing)
  static NetworkInfo get defaultNetwork => networks['sepolia']!;
  
  /// Get RPC URL for a specific network
  static String getRpcUrl(String network) {
    return networks[network]?.rpcUrl ?? sepoliaRpcUrl;
  }
  
  /// Check if a network is a testnet
  static bool isTestnet(String network) {
    return networks[network]?.isTestnet ?? true;
  }
}

/// Network information data class
class NetworkInfo {
  final String name;
  final String chainId;
  final String rpcUrl;
  final String blockExplorerUrl;
  final bool isTestnet;
  
  const NetworkInfo({
    required this.name,
    required this.chainId,
    required this.rpcUrl,
    required this.blockExplorerUrl,
    required this.isTestnet,
  });
} 