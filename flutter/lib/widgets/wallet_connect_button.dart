import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import '../services/wallet_service.dart';

/// Wallet connection button widget
class WalletConnectButton extends StatefulWidget {
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final VoidCallback? onError;
  final bool showAccountInfo;
  final Widget? customIcon;
  final String? customText;
  final ButtonStyle? customStyle;

  const WalletConnectButton({
    Key? key,
    this.onConnected,
    this.onDisconnected,
    this.onError,
    this.showAccountInfo = true,
    this.customIcon,
    this.customText,
    this.customStyle,
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
        _buildConnectionButton(),
        
        if (widget.showAccountInfo && _walletService.isConnected) ...[
          const SizedBox(height: 8),
          _buildAccountInfo(),
        ],
        
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

    // Show connected state with wallet info
    if (_walletService.isConnected) {
      return _buildConnectedState();
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

  Widget _buildConnectedState() {
    final walletAddress = _walletService.walletAddress;
    final networkName = _walletService.selectedChain?.name ?? 'Unknown';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Connected indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          
          // Wallet icon
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 6),
          
          // Connected text and address
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Connected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (walletAddress != null) ...[
                Text(
                  '${walletAddress.substring(0, 6)}...${walletAddress.substring(walletAddress.length - 4)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(width: 8),
          
          // Network indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              networkName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Disconnect button
          GestureDetector(
            onTap: _disconnectWallet,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
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
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      await _walletService.initialize(context);
      setState(() {
        _isInitializing = false;
      });
      widget.onConnected?.call();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isInitializing = false;
      });
      widget.onError?.call();
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

  Future<void> _disconnectWallet() async {
    try {
      await _walletService.disconnect();
      widget.onDisconnected?.call();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      widget.onError?.call();
    }
  }
} 