import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/proof_result.dart';
import '../config/network_config.dart';
import '../services/blockchain_service.dart';

/// Displays proof results and verification status
class ProofResults extends StatelessWidget {
  final ProofResult proofResult;
  final bool showProofDetails;
  final bool showBlockchainLinks;
  final VoidCallback? onCopyProof;
  final VoidCallback? onViewContract;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final Color? borderColor;

  const ProofResults({
    Key? key,
    required this.proofResult,
    this.showProofDetails = true,
    this.showBlockchainLinks = true,
    this.onCopyProof,
    this.onViewContract,
    this.padding = const EdgeInsets.all(16.0),
    this.backgroundColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!proofResult.hasProof) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: borderColor ?? Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proof Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          
          const SizedBox(height: 12),
          
          _buildVerificationStatus(),
          
          const SizedBox(height: 12),
          
          _buildPublicInputs(),
          
          if (showProofDetails) ...[
            const SizedBox(height: 12),
            _buildProofDetails(),
          ],
          
          if (showBlockchainLinks) ...[
            const SizedBox(height: 12),
            _buildBlockchainLinks(),
          ],
          
          const SizedBox(height: 12),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusItem(
          'Local Verification',
          proofResult.localVerification,
          Icons.verified_user,
        ),
        const SizedBox(height: 4),
        _buildStatusItem(
          'On-Chain Verification',
          proofResult.onChainVerification,
          Icons.link,
        ),
      ],
    );
  }

  Widget _buildStatusItem(String label, bool? status, IconData icon) {
    Color color;
    String statusText;
    
    if (status == null) {
      color = Colors.grey.shade600;
      statusText = 'Not verified';
    } else if (status) {
      color = Colors.green.shade700;
      statusText = 'Verified ✓';
    } else {
      color = Colors.red.shade700;
      statusText = 'Failed ✗';
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.green.shade700,
          ),
        ),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPublicInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Public Inputs:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            proofResult.publicInputs.toString(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProofDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proof Details:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 8),
        
        _buildDetailItem(
          'Generated',
          _formatTimestamp(proofResult.timestamp),
        ),
        
        if (proofResult.proofData != null) ...[
          _buildDetailItem(
            'Proof A',
            _formatProofComponent(proofResult.proofData!.a),
          ),
          _buildDetailItem(
            'Proof B',
            _formatProofComponent(proofResult.proofData!.b),
          ),
          _buildDetailItem(
            'Proof C',
            _formatProofComponent(proofResult.proofData!.c),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.green.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Blockchain Info:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 8),
        
        _buildDetailItem(
          'Network',
          'Sepolia Testnet',
        ),
        _buildDetailItem(
          'Contract',
          NetworkConfig.verifierContractAddress,
        ),
        
        const SizedBox(height: 8),
        
        InkWell(
          onTap: onViewContract,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_new, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  'View Contract on Etherscan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _copyProofToClipboard(context),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Proof'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _copyPublicInputsToClipboard(context),
                icon: const Icon(Icons.content_copy, size: 16),
                label: const Text('Copy Inputs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _copyContractUrl(context),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Copy Contract URL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  void _copyProofToClipboard(BuildContext context) {
    if (proofResult.circomProof != null) {
      final proofJson = proofResult.circomProof!.proof.toString();
      Clipboard.setData(ClipboardData(text: proofJson));
      onCopyProof?.call();
    }
  }

  void _copyPublicInputsToClipboard(BuildContext context) {
    final inputsJson = proofResult.publicInputs.toString();
    Clipboard.setData(ClipboardData(text: inputsJson));
  }

  void _copyContractUrl(BuildContext context) {
    final contractUrl = 'https://sepolia.etherscan.io/address/${NetworkConfig.verifierContractAddress}';
    Clipboard.setData(ClipboardData(text: contractUrl));
    onViewContract?.call();
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown';
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  String _formatProofComponent(dynamic component) {
    if (component == null) return 'Unknown';
    String str = component.toString();
    return str.length > 20 ? '${str.substring(0, 20)}...' : str;
  }
}

/// A compact version of the proof results widget
class ProofResultsCompact extends StatelessWidget {
  final ProofResult proofResult;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final Color? borderColor;

  const ProofResultsCompact({
    Key? key,
    required this.proofResult,
    this.padding = const EdgeInsets.all(12.0),
    this.backgroundColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!proofResult.hasProof) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: borderColor ?? Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proof Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                proofResult.isLocallyVerified ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: proofResult.isLocallyVerified ? Colors.green.shade700 : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'Local',
                style: TextStyle(fontSize: 12, color: Colors.green.shade700),
              ),
              const SizedBox(width: 16),
              Icon(
                proofResult.isOnChainVerified ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: proofResult.isOnChainVerified ? Colors.green.shade700 : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'On-Chain',
                style: TextStyle(fontSize: 12, color: Colors.green.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 