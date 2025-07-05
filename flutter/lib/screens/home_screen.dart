import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/proof_result.dart';
import '../services/wallet_service.dart';
import '../widgets/wallet_connect_button.dart';
import '../widgets/proof_form.dart';
import '../widgets/proof_results.dart';

/// Main home screen of the application
class HomeScreen extends StatefulWidget {
  final String? title;

  const HomeScreen({
    Key? key,
    this.title,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WalletService _walletService = WalletService.instance;
  ProofResult _currentProofResult = ProofResult();
  String? _statusMessage;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    // Set up listeners for wallet connection changes
    _setupWalletListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setupWalletListeners() {
    // Listen for wallet connection state changes
    // This will help update the UI when connection state changes
    if (_walletService.appKitModal != null) {
      // The ReownAppKit has internal state management
      // We'll rely on the callbacks from WalletConnectButton to update UI
    }
  }

  void _onWalletConnectionChanged() {
    // Force UI update when wallet connection changes
    if (mounted) {
      setState(() {
        // This will trigger a rebuild with updated connection state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? AppConfig.appName),
        backgroundColor: _walletService.isConnected ? Colors.green.shade600 : Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: WalletConnectButton(
              showAccountInfo: false,
              onConnected: () {
                setState(() {
                  _statusMessage = 'Wallet connected successfully!';
                });
                _showStatusMessage();
                _onWalletConnectionChanged();
              },
              onDisconnected: () {
                setState(() {
                  _statusMessage = 'Wallet disconnected';
                });
                _showStatusMessage();
                _onWalletConnectionChanged();
              },
              onError: () {
                setState(() {
                  _statusMessage = 'Wallet connection failed';
                });
                _showStatusMessage();
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection Status Banner
                _buildConnectionStatusBanner(),
                
                const SizedBox(height: 16),
                
                _buildWelcomeSection(),
                
                const SizedBox(height: 24),
                
                _buildProofFormSection(),
                
                const SizedBox(height: 24),
                
                if (_showResults) ...[
                  _buildResultsSection(),
                  const SizedBox(height: 24),
                ],
                
                if (_statusMessage != null) ...[
                  _buildStatusMessage(),
                  const SizedBox(height: 24),
                ],
                
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatusBanner() {
    if (!_walletService.isConnected) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange.shade700,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Connect your wallet to generate and verify proofs on-chain',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_up,
              color: Colors.orange.shade700,
              size: 16,
            ),
          ],
        ),
      );
    }

    final walletAddress = _walletService.walletAddress;
    final networkName = _walletService.selectedChain?.name ?? 'Unknown Network';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Connected indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              
              Text(
                'Wallet Connected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const Spacer(),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  networkName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          if (walletAddress != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white.withOpacity(0.9),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Address: ${walletAddress.substring(0, 8)}...${walletAddress.substring(walletAddress.length - 6)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 8),
          
          Text(
            'You can now generate proofs and verify them on-chain',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.security,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'ZK Proof Generator',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Generate and verify proofs on-chain',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProofFormSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Proof',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          ProofForm(
            onProofGenerated: (result) {
              setState(() {
                _currentProofResult = result;
                _showResults = true;
                _statusMessage = 'Proof generated successfully!';
              });
              _showStatusMessage();
            },
            onProofVerified: (result) {
              setState(() {
                _currentProofResult = result;
                _statusMessage = 'Proof verified locally!';
              });
              _showStatusMessage();
            },
            onOnChainVerified: (result) {
              setState(() {
                _currentProofResult = result;
                _statusMessage = result.isOnChainVerified 
                    ? 'Proof verified on-chain successfully!' 
                    : 'On-chain verification failed';
              });
              _showStatusMessage();
            },
            onError: (error) {
              setState(() {
                _statusMessage = 'Error: $error';
              });
              _showStatusMessage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Results',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showResults = false;
                    _currentProofResult = ProofResult();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ProofResults(
            proofResult: _currentProofResult,
            onCopyProof: () {
              setState(() {
                _statusMessage = 'Proof copied to clipboard!';
              });
              _showStatusMessage();
            },
            onViewContract: () {
              setState(() {
                _statusMessage = 'Contract URL copied to clipboard!';
              });
              _showStatusMessage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    final isError = _statusMessage?.startsWith('Error:') ?? false;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? Colors.red.shade300 : Colors.green.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error : Icons.check_circle,
            color: isError ? Colors.red.shade700 : Colors.green.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: isError ? Colors.red.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _statusMessage = null;
              });
            },
            color: isError ? Colors.red.shade700 : Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Built with Mopro & Reown AppKit',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFooterLink('Mopro', 'https://zkmopro.org'),
              const SizedBox(width: 16),
              _buildFooterLink('Reown', 'https://reown.com'),
              const SizedBox(width: 16),
              _buildFooterLink('Circom', 'https://circom.io'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text, String url) {
    return InkWell(
      onTap: () {
        setState(() {
          _statusMessage = 'Link copied: $url';
        });
        _showStatusMessage();
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue.shade600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  void _showStatusMessage() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = null;
        });
      }
    });
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _statusMessage = 'Data refreshed';
    });
    _showStatusMessage();
  }
}

/// Loading screen for initialization
class LoadingScreen extends StatelessWidget {
  final String? message;

  const LoadingScreen({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              message ?? 'Loading...',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 