import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/proof_service.dart';

/// Displays information about the current circuit
class CircuitInfo extends StatelessWidget {
  final Map<String, dynamic>? customCircuitInfo;
  final bool showTechnicalDetails;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final Color? borderColor;

  const CircuitInfo({
    Key? key,
    this.customCircuitInfo,
    this.showTechnicalDetails = false,
    this.padding = const EdgeInsets.all(16.0),
    this.backgroundColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final circuitInfo = customCircuitInfo ?? ProofService.instance.getCircuitInfo();
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: borderColor ?? Colors.blue.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            circuitInfo['name'] ?? AppConfig.circuitName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Proves you know two numbers that multiply to a result',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
            ),
          ),
          
          const SizedBox(height: 12),
          
          _buildIOInfo(circuitInfo),
          
          if (showTechnicalDetails) ...[
            const SizedBox(height: 12),
            _buildTechnicalInfo(circuitInfo),
          ],
        ],
      ),
    );
  }

  Widget _buildIOInfo(Map<String, dynamic> circuitInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inputs:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'a (public), b (private)',
          style: TextStyle(
            fontSize: 13,
            color: Colors.blue.shade700,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Output:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'result = a × b',
          style: TextStyle(
            fontSize: 13,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalInfo(Map<String, dynamic> circuitInfo) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Technical Details:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildTechnicalItem(
            'Proof System',
            circuitInfo['proofSystem'] ?? 'Groth16',
          ),
          _buildTechnicalItem(
            'Curve',
            circuitInfo['curve'] ?? 'bn128',
          ),
          _buildTechnicalItem(
            'Circuit File',
            circuitInfo['zkeyPath'] ?? AppConfig.zkeyPath,
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalItem(String label, String value) {
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
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version of circuit info widget
class CircuitInfoCompact extends StatelessWidget {
  final String title;
  final String description;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final Color? borderColor;

  const CircuitInfoCompact({
    Key? key,
    this.title = '',
    this.description = '',
    this.padding = const EdgeInsets.all(12.0),
    this.backgroundColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: borderColor ?? Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }
} 