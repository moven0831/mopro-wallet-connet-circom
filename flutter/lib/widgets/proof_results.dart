import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/proof_result.dart';
import '../config/network_config.dart';
import '../services/blockchain_service.dart';

/// A widget that displays proof results and verification status
/// 
/// This widget provides a comprehensive view of the proof generation
/// and verification results, making it easy for users to understand
/// the status of their ZK proofs.
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
          // Title
          Text(
            'Proof Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Verification Status
          _buildVerificationStatus(),
          
          const SizedBox(height: 12),
          
          // Public Inputs
          _buildPublicInputs(),
          
          if (showProofDetails) ...[
            const SizedBox(height: 12),
            _buildProofDetails(),
          ],
          
          if (showBlockchainLinks) ...[
            const SizedBox(height: 12),
            _buildBlockchainLinks(),
          ],
          
          // Action buttons
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
        
        // Proof timestamp
        _buildDetailItem(
          'Generated',
          _formatTimestamp(proofResult.timestamp),
        ),
        
        // Proof components
        if (proofResult.proofData != null) ...[
          _buildDetailItem(
            'Proof System',
            'Groth16',
          ),
          _buildDetailItem(
            'Curve',
            'BN254',
          ),
        ],
        
        const SizedBox(height: 8),
        
        // Proof data (collapsible)
        ExpansionTile(
          title: const Text(
            'Raw Proof Data',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                proofResult.proofData?.toString() ?? 'No proof data',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
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
            width: 100,
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
        
        // Contract link
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Copy proof button
        ElevatedButton.icon(
          onPressed: () => _copyProofToClipboard(context),
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy Proof'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: Colors.grey.shade800,
            elevation: 0,
          ),
        ),
        
        // Share button
        ElevatedButton.icon(
          onPressed: () => _shareProof(context),
          icon: const Icon(Icons.share, size: 16),
          label: const Text('Share'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: Colors.grey.shade800,
            elevation: 0,
          ),
        ),
        
        // View contract button
        if (showBlockchainLinks)
          ElevatedButton.icon(
            onPressed: () => _viewContract(context),
            icon: const Icon(Icons.link, size: 16),
            label: const Text('Contract'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade100,
              foregroundColor: Colors.blue.shade800,
              elevation: 0,
            ),
          ),
      ],
    );
  }

  void _copyProofToClipboard(BuildContext context) {
    final proofText = '''
Proof Results:
- Local Verification: ${proofResult.localVerification ?? 'Not verified'}
- On-Chain Verification: ${proofResult.onChainVerification ?? 'Not verified'}
- Public Inputs: ${proofResult.publicInputs}
- Generated: ${_formatTimestamp(proofResult.timestamp)}
- Network: Sepolia Testnet
- Contract: ${NetworkConfig.verifierContractAddress}
''';

    Clipboard.setData(ClipboardData(text: proofText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proof details copied to clipboard')),
    );
    
    onCopyProof?.call();
  }

  void _shareProof(BuildContext context) {
    // This would typically integrate with platform sharing
    // For now, just copy to clipboard
    _copyProofToClipboard(context);
  }

  void _viewContract(BuildContext context) {
    final url = BlockchainService.instance.getContractExplorerUrl(
      NetworkConfig.verifierContractAddress,
    );
    
    // This would typically open the URL in a browser
    // For now, just copy to clipboard
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contract URL copied: $url')),
    );
    
    onViewContract?.call();
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
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