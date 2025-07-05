import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import '../services/wallet_service.dart';

/// A reusable wallet connect button widget
/// 
/// This widget provides a clean interface for wallet connection functionality.
/// It automatically handles the connection state and provides appropriate UI feedback.
class WalletConnectButton extends StatefulWidget {
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final VoidCallback? onError;
  final String? customText;
  final ButtonStyle? customStyle;
  final Widget? customIcon;
  final bool showAccountInfo;

  const WalletConnectButton({
    Key? key,
    this.onConnected,
    this.onDisconnected,
    this.onError,
    this.customText,
    this.customStyle,
    this.customIcon,
    this.showAccountInfo = true,
  }) : super(key: key);

  @override
  State<WalletConnectButton> createState() => _WalletConnectButtonState();
}

class _WalletConnectButtonState extends State<WalletConnectButton> {
  final WalletService _walletService = WalletService.instance;
  bool _isInitializing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Wallet Connection Button
        _buildConnectionButton(),
        
        // Account Information (if connected and enabled)
        if (widget.showAccountInfo && _walletService.isConnected) ...[
          const SizedBox(height: 8),
          _buildAccountInfo(),
        ],
        
        // Error Message
        if (_error != null) ...[
          const SizedBox(height: 8),
          _buildErrorMessage(),
        ],
      ],
    );
  }

  Widget _buildConnectionButton() {
    if (_walletService.appKitModal == null) {
      return ElevatedButton.icon(
        onPressed: _isInitializing ? null : _initializeWallet,
        icon: _isInitializing 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : widget.customIcon ?? const Icon(Icons.account_balance_wallet),
        label: Text(
          _isInitializing 
              ? 'Connecting...' 
              : widget.customText ?? 'Connect Wallet',
        ),
        style: widget.customStyle ?? ElevatedButton.styleFrom(
          backgroundColor: _isInitializing ? Colors.grey : Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }

    return AppKitModalConnectButton(
      appKit: _walletService.appKitModal!,
      custom: ElevatedButton.icon(
        onPressed: _connectWallet,
        icon: widget.customIcon ?? const Icon(Icons.account_balance_wallet),
        label: Text(widget.customText ?? 'Connect Wallet'),
        style: widget.customStyle ?? ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountInfo() {
    if (_walletService.appKitModal == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: AppKitModalAccountButton(
        appKitModal: _walletService.appKitModal!,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade700, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _error = null),
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  Future<void> _initializeWallet() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      await _walletService.initialize(context);
      widget.onConnected?.call();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      widget.onError?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _connectWallet() async {
    try {
      await _walletService.connect();
      widget.onConnected?.call();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      widget.onError?.call();
    }
  }
} 