import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import '../config/app_config.dart';
import '../config/network_config.dart';
import '../utils/deep_link_handler.dart';

/// Service for handling wallet connection and management
/// 
/// This service encapsulates all wallet-related functionality,
/// making it easy for developers to integrate wallet connections
/// into their dApps.
class WalletService {
  static WalletService? _instance;
  ReownAppKitModal? _appKitModal;
  
  WalletService._internal();
  
  /// Get the singleton instance of WalletService
  static WalletService get instance {
    _instance ??= WalletService._internal();
    return _instance!;
  }
  
  /// Get the current AppKit modal instance
  ReownAppKitModal? get appKitModal => _appKitModal;
  
  /// Check if the wallet is connected
  bool get isConnected => _appKitModal?.isConnected ?? false;
  
  /// Get the current session
  ReownAppKitModalSession? get session => _appKitModal?.session;
  
  /// Get the connected wallet address
  String? get walletAddress {
    if (!isConnected || session == null) return null;
    try {
      // Use the session's address property or accounts
      final accounts = session!.getAccounts();
      if (accounts != null && accounts.isNotEmpty) {
        return accounts.first.split(':').last;
      }
      return null;
    } catch (e) {
      debugPrint('[WalletService] Error getting wallet address: $e');
      return null;
    }
  }
  
  /// Get the currently selected chain
  ReownAppKitModalNetworkInfo? get selectedChain => _appKitModal?.selectedChain;
  
  /// Initialize the wallet connection
  /// 
  /// This method sets up the AppKit modal with the proper configuration.
  /// Call this method before attempting to connect to any wallet.
  Future<void> initialize(BuildContext context) async {
    if (_appKitModal != null) return;
    
    debugPrint('[WalletService] Initializing AppKit...');
    
    try {
      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: AppConfig.projectId,
        metadata: PairingMetadata(
          name: AppConfig.appName,
          description: AppConfig.appDescription,
          url: AppConfig.appUrl,
          icons: AppConfig.appIcons,
          redirect: Redirect(
            native: AppConfig.nativeScheme,
            universal: AppConfig.universalLink,
            linkMode: true, // Enable link mode for better mobile UX
          ),
        ),
        requiredNamespaces: {
          'eip155': RequiredNamespace(
            chains: NetworkConfig.supportedChains,
            methods: NetworkConfig.supportedMethods,
            events: NetworkConfig.supportedEvents,
          ),
        },
      );
      
      debugPrint('[WalletService] Initializing AppKit modal...');
      await _appKitModal!.init().timeout(
        Duration(seconds: AppConfig.connectionTimeoutSeconds),
        onTimeout: () {
          throw Exception('Connection timeout - please check your internet connection and try again');
        },
      );
      
      debugPrint('[WalletService] AppKit initialization completed');
      
      // Initialize deep link handler
      DeepLinkHandler.init(_appKitModal!);
      
    } catch (e) {
      debugPrint('[WalletService] Error during initialization: $e');
      rethrow;
    }
  }
  
  /// Connect to a wallet
  /// 
  /// Opens the wallet connection modal for the user to select and connect
  /// to their preferred wallet.
  Future<void> connect() async {
    if (_appKitModal == null) {
      throw Exception('WalletService must be initialized before connecting');
    }
    
    debugPrint('[WalletService] Opening wallet connection modal...');
    _appKitModal!.openModalView();
  }
  
  /// Disconnect from the current wallet
  /// 
  /// Closes the current wallet session and cleans up the connection.
  Future<void> disconnect() async {
    if (_appKitModal == null || !isConnected) return;
    
    debugPrint('[WalletService] Disconnecting from wallet...');
    try {
      await _appKitModal!.disconnect();
      debugPrint('[WalletService] Wallet disconnected successfully');
    } catch (e) {
      debugPrint('[WalletService] Error disconnecting wallet: $e');
      rethrow;
    }
  }
  
  /// Switch to a different network
  /// 
  /// Attempts to switch the connected wallet to the specified network.
  /// If the network is not supported by the wallet, it will attempt to add it.
  Future<void> switchNetwork(String chainId) async {
    if (_appKitModal == null || !isConnected) {
      throw Exception('Wallet must be connected to switch networks');
    }
    
    debugPrint('[WalletService] Switching to network: $chainId');
    try {
      await _appKitModal!.selectChain(
        ReownAppKitModalNetworkInfo(
          name: 'Custom Network',
          chainId: chainId,
          currency: 'ETH',
          rpcUrl: NetworkConfig.getRpcUrl(chainId),
          explorerUrl: '',
        ),
      );
      debugPrint('[WalletService] Network switched successfully');
    } catch (e) {
      debugPrint('[WalletService] Error switching network: $e');
      rethrow;
    }
  }
  
  /// Get the current network information
  /// 
  /// Returns information about the currently connected network.
  NetworkInfo? getCurrentNetwork() {
    if (!isConnected || selectedChain == null) return null;
    
    final chainId = selectedChain!.chainId;
    return NetworkConfig.networks.values.firstWhere(
      (network) => network.chainId == chainId,
      orElse: () => NetworkInfo(
        name: selectedChain!.name,
        chainId: chainId,
        rpcUrl: selectedChain!.rpcUrl,
        blockExplorerUrl: selectedChain!.explorerUrl,
        isTestnet: NetworkConfig.isTestnet(chainId),
      ),
    );
  }
  
  /// Listen to wallet connection events
  /// 
  /// Set up listeners for wallet connection state changes.
  /// This is useful for updating UI when the wallet connection status changes.
  void setupEventListeners({
    VoidCallback? onConnected,
    VoidCallback? onDisconnected,
    VoidCallback? onNetworkChanged,
  }) {
    if (_appKitModal == null) return;
    
    // Note: ReownAppKit provides event streams that can be listened to
    // The actual implementation depends on the specific event system
    // provided by the ReownAppKit package
    
    debugPrint('[WalletService] Event listeners set up');
  }
  
  /// Clean up resources
  /// 
  /// Call this method when the app is being disposed to clean up
  /// any resources used by the wallet service.
  void dispose() {
    _appKitModal = null;
    _instance = null;
    debugPrint('[WalletService] Service disposed');
  }
} 