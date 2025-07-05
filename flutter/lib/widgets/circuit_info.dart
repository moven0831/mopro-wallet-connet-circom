import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/proof_service.dart';

/// A widget that displays information about the current circuit
/// 
/// This widget provides a clear explanation of what the circuit does
/// and how it works, making it easier for users to understand.
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
          // Circuit Title
          Text(
            circuitInfo['name'] ?? AppConfig.circuitName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          
          // Circuit Description
          Text(
            circuitInfo['description'] ?? AppConfig.circuitDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Input/Output Information
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
        // Input Information
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
          'Public: a (first number)',
          style: TextStyle(
            fontSize: 13,
            color: Colors.blue.shade700,
          ),
        ),
        Text(
          'Private: b (second number)',
          style: TextStyle(
            fontSize: 13,
            color: Colors.blue.shade700,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Output Information
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
          'Public: result = a × b (revealed to verifier)',
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
            circuitInfo['proofSystem'] ?? 'Unknown',
          ),
          _buildTechnicalItem(
            'Curve',
            circuitInfo['curve'] ?? 'Unknown',
          ),
          _buildTechnicalItem(
            'Circuit File',
            circuitInfo['zkeyPath'] ?? 'Unknown',
          ),
          _buildTechnicalItem(
            'Input Fields',
            (circuitInfo['inputFields'] as List<dynamic>?)?.join(', ') ?? 'Unknown',
          ),
          _buildTechnicalItem(
            'Output Fields',
            (circuitInfo['outputFields'] as List<dynamic>?)?.join(', ') ?? 'Unknown',
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

/// A compact version of the circuit info widget
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