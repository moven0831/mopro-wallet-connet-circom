# ZKP Mobile dApp Template using Mopro

A modular Flutter application template for building decentralized applications with ZKP, built on top of the Mopro stack for mobile proving and Reown's AppKit for seamless wallet connectivity.

## 🚀 Features

- **Zero-Knowledge Proof Generation**: Generate and verify Groth16 proofs using Circom circuits
- **On-Chain Verification**: Verify proofs on Ethereum-compatible networks using Solidity verifier contracts
- **Wallet Integration**: Connect to multiple wallets using Reown AppKit (WalletConnect v2)
- **Modular Architecture**: Clean, maintainable code structure for easy customization
- **Mobile-First**: Optimized for iOS and Android with responsive design
- **Developer-Friendly**: Well-documented, reusable components and services

## 📋 Prerequisites

Before you begin, ensure you have:

1. **Flutter Development Environment**: [Flutter installation guide](https://docs.flutter.dev/get-started/install)
2. **Mopro Setup**: Follow the [mopro prerequisites](https://zkmopro.org/docs/prerequisites)
3. **Reown AppKit Account**: Create a project at [Reown Cloud](https://cloud.reown.com/)
4. **Basic Knowledge**: Familiarity with Flutter, Dart, and blockchain concepts

## 🛠 Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd mopro-wallet-connect-circom
cd flutter/
flutter pub get
```

### 2. Configure Your Project

#### Update App Configuration
Edit `lib/config/app_config.dart`:

```dart
class AppConfig {
  // Replace with your app information
  static const String appName = 'Your dApp Name';
  static const String appDescription = 'Your dApp description';
  static const String appUrl = 'https://yourdapp.com/';
  
  // Replace with your Reown AppKit Project ID
  static const String defaultProjectId = 'YOUR_REOWN_PROJECT_ID';
  
  // Update your circuit configuration
  static const String circuitName = 'Your Circuit Name';
  static const String circuitDescription = 'Your circuit description';
  static const String zkeyPath = 'assets/your_circuit.zkey';
}
```

#### Update Network Configuration
Edit `lib/config/network_config.dart`:

```dart
class NetworkConfig {
  // Update with your verifier contract address
  static const String verifierContractAddress = 'YOUR_CONTRACT_ADDRESS';
  
  // Add/remove networks as needed
  static const List<String> supportedChains = [
    'eip155:1',        // Ethereum Mainnet
    'eip155:137',      // Polygon
    'eip155:11155111', // Sepolia Testnet
    // Add your networks here
  ];
}
```

### 3. Add Your Circuit Files

1. Place your `.zkey` file in `flutter/assets/`
2. Update `flutter/pubspec.yaml` to include your assets:

```yaml
flutter:
  assets:
    - assets/your_circuit.zkey
```

### 4. Run Your dApp

```bash
flutter run --dart-define=PROJECT_ID=YOUR_REOWN_PROJECT_ID
```

## 🏗 Architecture Overview

The codebase is organized into clear, modular components:

```
lib/
├── main.dart                     # App entry point
├── config/                       # Configuration files
│   ├── app_config.dart          # App-wide settings
│   └── network_config.dart      # Blockchain network settings
├── models/                       # Data models
│   └── proof_result.dart        # Proof and state models
├── services/                     # Business logic services
│   ├── wallet_service.dart      # Wallet connection logic
│   ├── proof_service.dart       # ZK proof operations
│   └── blockchain_service.dart  # On-chain verification
├── widgets/                      # Reusable UI components
│   ├── wallet_connect_button.dart
│   ├── circuit_info.dart
│   ├── proof_form.dart
│   └── proof_results.dart
├── screens/                      # App screens
│   └── home_screen.dart
└── utils/                        # Utility classes
    └── deep_link_handler.dart
```

## 🔧 Customization Guide

### Adding Your Own Circuit

1. **Replace the Circuit Files**:
   ```bash
   # Add your .zkey file to assets/
   cp your_circuit.zkey flutter/assets/
   ```

2. **Update Circuit Configuration**:
   ```dart
   // In lib/config/app_config.dart
   static const String zkeyPath = 'assets/your_circuit.zkey';
   static const String circuitName = 'Your Circuit Name';
   ```

3. **Modify Input Models**:
   ```dart
   // In lib/models/proof_result.dart
   class CircuitInputs {
     final String yourInput1;
     final String yourInput2;
     // Add your circuit inputs
     
     String toJson() {
       return '{"input1":["$yourInput1"],"input2":["$yourInput2"]}';
     }
   }
   ```

4. **Update the UI**:
   ```dart
   // In lib/widgets/proof_form.dart
   // Modify _buildInputForm() to match your circuit inputs
   ```

### Deploying Your Verifier Contract

1. **Generate Solidity Verifier**:
   ```bash
   snarkjs zkey export solidityverifier your_circuit.zkey verifier.sol
   ```

2. **Deploy to Your Network**:
   - Deploy the `Verifier.sol` contract
   - Update the contract address in `network_config.dart`

3. **Update ABI if Needed**:
   - If your verifier has different function signatures, update the ABI in `network_config.dart`

### Adding New Networks

```dart
// In lib/config/network_config.dart
static const Map<String, NetworkInfo> networks = {
  'your_network': NetworkInfo(
    name: 'Your Network',
    chainId: 'eip155:YOUR_CHAIN_ID',
    rpcUrl: 'https://your-rpc-url.com',
    blockExplorerUrl: 'https://your-explorer.com',
    isTestnet: false,
  ),
  // ... other networks
};
```

### Customizing the UI

The UI components are modular and easily customizable:

```dart
// Example: Custom wallet button
WalletConnectButton(
  customText: 'Connect Your Wallet',
  customIcon: Icon(Icons.account_balance),
  showAccountInfo: true,
  onConnected: () => print('Connected!'),
)

// Example: Custom circuit info
CircuitInfo(
  showTechnicalDetails: true,
  backgroundColor: Colors.blue.shade50,
)
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run widget tests
flutter test test/widget_test.dart
```

### Testing Your Circuit

```dart
// Example test for your circuit
void main() {
  testWidgets('Circuit generates valid proof', (WidgetTester tester) async {
    final proofService = ProofService.instance;
    final inputs = CircuitInputs(a: '5', b: '3');
    
    final result = await proofService.generateProof(inputs);
    
    expect(result.hasProof, true);
    expect(result.hasError, false);
  });
}
```

## 📱 Building for Production

### iOS Build

```bash
cd flutter/
flutter build ios --dart-define=PROJECT_ID=YOUR_PROJECT_ID
```

### Android Build

```bash
cd flutter/
flutter build apk --dart-define=PROJECT_ID=YOUR_PROJECT_ID
```

### Environment Variables

For production, consider using environment-specific configurations:

```bash
# Development
flutter run --dart-define=PROJECT_ID=dev_project_id

# Production
flutter build apk --dart-define=PROJECT_ID=prod_project_id
```

## 🔍 Common Use Cases

### 1. Privacy-Preserving Authentication
```dart
// Circuit proving knowledge of a secret without revealing it
final inputs = CircuitInputs(
  secret: hashedSecret,
  nullifier: randomNullifier,
);
```

### 2. Zero-Knowledge Asset Verification
```dart
// Proving ownership of assets above threshold without revealing amount
final inputs = CircuitInputs(
  balance: userBalance,
  threshold: requiredThreshold,
);
```

### 3. Anonymous Voting
```dart
// Proving voting eligibility without revealing identity
final inputs = CircuitInputs(
  voterID: hashedVoterID,
  merkleProof: merkleTreeProof,
);
```

## 🛠 Advanced Configuration

### Custom Proof Libraries

```dart
// Use different proof libraries if needed
await proofService.generateProof(
  inputs,
  proofLib: ProofLib.rapidsnark, // or ProofLib.arkworks
);
```

### Network-Specific Settings

```dart
// Different settings per network
if (NetworkConfig.isTestnet('sepolia')) {
  // Use test contract addresses
} else {
  // Use production addresses
}
```

### Error Handling

```dart
try {
  final result = await proofService.generateProof(inputs);
  if (result.hasError) {
    // Handle proof generation error
    showError(result.error);
  }
} catch (e) {
  // Handle unexpected errors
  showError('Unexpected error: $e');
}
```

## 📚 API Reference

### Key Services

- **`WalletService`**: Handles wallet connections and network management
- **`ProofService`**: Manages ZK proof generation and local verification
- **`BlockchainService`**: Handles on-chain verification and contract interactions

### Key Models

- **`CircuitInputs`**: Represents circuit input parameters
- **`ProofResult`**: Contains proof data and verification results
- **`AppState`**: Manages application state

### Key Widgets

- **`ProofForm`**: Input form for circuit parameters
- **`ProofResults`**: Displays proof results and verification status
- **`WalletConnectButton`**: Wallet connection interface

## 🆘 Troubleshooting

### Common Issues

**Wallet Connection Fails**:
- Ensure your PROJECT_ID is correct
- Check network connectivity
- Verify supported chains in your configuration

**Proof Generation Fails**:
- Verify your .zkey file is correctly placed in assets/
- Check that circuit inputs match expected format
- Ensure sufficient device memory for proof generation

**On-Chain Verification Fails**:
- Confirm contract is deployed at the specified address
- Verify you're on the correct network
- Check that the proof format matches contract expectations

### Debug Mode

Enable debug logging:

```dart
// In lib/config/app_config.dart
static const bool debugMode = true;
```

## References

- **Mopro Documentation**: [https://zkmopro.org/docs](https://zkmopro.org/docs)
- **Reown AppKit**: [https://docs.reown.com/appkit](https://docs.reown.com/appkit)
- **Circom Documentation**: [https://docs.circom.io](https://docs.circom.io)
