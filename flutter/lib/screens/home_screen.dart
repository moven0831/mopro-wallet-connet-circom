import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/proof_result.dart';
import '../widgets/wallet_connect_button.dart';
import '../widgets/proof_form.dart';
import '../widgets/proof_results.dart';

/// The main home screen of the application
/// 
/// This screen combines all the components into a cohesive user interface,
/// providing the main entry point for users to interact with the dApp.
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
  ProofResult _currentProofResult = ProofResult();
  String? _statusMessage;
  bool _showResults = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? AppConfig.appName),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Wallet connect button in the app bar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: WalletConnectButton(
              showAccountInfo: false,
              onConnected: () {
                setState(() {
                  _statusMessage = 'Wallet connected successfully!';
                });
                _showStatusMessage();
              },
              onDisconnected: () {
                setState(() {
                  _statusMessage = 'Wallet disconnected';
                });
                _showStatusMessage();
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
                // Welcome section
                _buildWelcomeSection(),
                
                const SizedBox(height: 24),
                
                // Proof form section
                _buildProofFormSection(),
                
                const SizedBox(height: 24),
                
                // Results section
                if (_showResults) ...[
                  _buildResultsSection(),
                  const SizedBox(height: 24),
                ],
                
                // Status message
                if (_statusMessage != null) ...[
                  _buildStatusMessage(),
                  const SizedBox(height: 24),
                ],
                
                // Footer
                _buildFooter(),
              ],
            ),
          ),
        ),
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
            'Zero-Knowledge Proof Generator',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Generate and verify cryptographic proofs on-chain',
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
        // In a real app, this would open the URL
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
    // Auto-hide status message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = null;
        });
      }
    });
  }

  Future<void> _refreshData() async {
    // Simulate refresh delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _statusMessage = 'Data refreshed';
    });
    _showStatusMessage();
  }
}

/// A loading screen that can be shown while initializing
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