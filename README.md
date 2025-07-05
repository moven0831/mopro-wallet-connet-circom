# Mopro Mobile dApp Template (Circom)

A Flutter template for building mobile dApps with zero-knowledge proofs and on-chain verification.

## ✨ Features

- **🔐 ZK Proof Generation**: Generate Groth16 proofs on mobile using Circom circuits
- **⛓️ On-Chain Verification**: Verify proofs on Ethereum-compatible networks
- **👛 Wallet Connect**: Connect to 300+ wallets via Reown AppKit (WalletConnect v2)
- **📱 Mobile-First**: Optimized for iOS and Android
- **🛠️ Developer-Friendly**: Modular architecture for easy customization

## 🚀 Quick Start

Before you begin, ensure you have:

1. **Flutter Development Environment**: [Flutter installation guide](https://docs.flutter.dev/get-started/install)
2. **Mopro Setup**: Follow the [mopro prerequisites](https://zkmopro.org/docs/prerequisites) to install Mopro CLI
3. **Reown AppKit Project ID**: Create an Appkit project at [Reown Cloud](https://cloud.reown.com/) to get your `PROJECT_ID`

## 🛠 Setup

### 1. Clone and Setup

```bash
cd mopro-wallet-connect-circom
cd flutter/
flutter pub get
```

### 2. Configure

Edit `flutter/lib/config/network_config.dart`:
```dart
static const String verifierContractAddress = 'YOUR_CONTRACT_ADDRESS';
```

### 3. Run

**Important**: You must provide your Reown Appkit's `PROJECT_ID` when running the app:

```bash
flutter run --dart-define=PROJECT_ID=YOUR_REOWN_PROJECT_ID
```

## 🏗️ Architecture

```
flutter/lib/
├── config/           # App and network configuration
├── models/           # Data models (CircuitInputs, ProofResult)
├── services/         # Business logic (WalletService, ProofService, BlockchainService)
├── widgets/          # UI components (ProofForm, WalletConnectButton, etc.)
├── screens/          # App screens (HomeScreen)
└── utils/            # Utilities (DeepLinkHandler)
```

## 🎨 UI Design

The template features a minimalist design with:

- **Clean Input Fields**: Simple `a` and `b` labels without verbose descriptions
- **Dynamic Result Display**: Real-time `a × b = result` calculation
- **Streamlined Status Messages**: Concise feedback without unnecessary text
- **Essential Actions Only**: Core functionality without clutter

## 🔧 Adding Your Circuit

### 1. Replace Circuit Files

```bash
# Add your .zkey file
cp your_circuit.zkey flutter/assets/

# Update pubspec.yaml
flutter:
  assets:
    - assets/your_circuit.zkey
```

### 2. Update Configuration

```dart
// flutter/lib/config/app_config.dart
static const String zkeyPath = 'assets/your_circuit.zkey';
static const String circuitName = 'Your Circuit Name';
```

### 3. Modify Input Model

```dart
// flutter/lib/models/proof_result.dart
class CircuitInputs {
  final String input1;
  final String input2;
  // Add your circuit inputs
  
  String toJson() {
    return '{"input1":["$input1"],"input2":["$input2"]}';
  }
}
```

### 4. Update UI

```dart
// flutter/lib/widgets/proof_form.dart
// Modify _buildInputForm() to match your circuit inputs
```

### 5. Add Rust Witness

```rust
// src/lib.rs
rust_witness::witness!(your_circuit);

mopro_ffi::set_circom_circuits! {
    ("your_circuit.zkey", mopro_ffi::witness::WitnessFn::RustWitness(your_circuit_witness))
}
```

## 📄 Deploy Verifier Contract

### 1. Generate Solidity Verifier
Check the "[Verifying from a smart contract](https://docs.circom.io/getting-started/proving-circuits/#verifying-from-a-smart-contract)" from Circom docs.

```bash
snarkjs zkey export solidityverifier your_circuit.zkey verifier.sol
```

### 2. Deploy Contract

Deploy the `Groth16Verifier` contract to your target network.

### 3. Update Configuration

```dart
// flutter/lib/config/network_config.dart
static const String verifierContractAddress = 'YOUR_DEPLOYED_CONTRACT_ADDRESS';
```

## 🔗 Adding Networks

```dart
// flutter/lib/config/network_config.dart
static const List<String> supportedChains = [
  'eip155:1',        // Ethereum Mainnet
  'eip155:137',      // Polygon
  'eip155:11155111', // Sepolia Testnet
  'eip155:YOUR_CHAIN_ID', // Your network
];

static const Map<String, NetworkInfo> networks = {
  'your_network': NetworkInfo(
    name: 'Your Network',
    chainId: 'eip155:YOUR_CHAIN_ID',
    rpcUrl: 'https://your-rpc-url.com',
    blockExplorerUrl: 'https://your-explorer.com',
    isTestnet: false,
  ),
};
```

## 🧪 Example: Multiplier Circuit

This template includes a simple multiplier circuit that proves you know two numbers `a` and `b` such that `a * b = result`.

**Circuit inputs:**
- `a`: First number
- `b`: Second number

**Public output:**
- `result`: The product `a * b`

**Use case:** Prove you know the factors of a number without revealing them.

## 🏢 Common Use Cases

### Private Authentication
```dart
CircuitInputs(secret: hashedSecret, nullifier: randomNullifier)
```

### Asset Verification
```dart
CircuitInputs(balance: userBalance, threshold: minRequired)
```

### Anonymous Voting
```dart
CircuitInputs(voterID: hashedID, merkleProof: eligibilityProof)
```

## 🔧 Key Services

- **`ProofService`**: Generates and verifies ZK proofs using Mopro
- **`WalletService`**: Handles wallet connections via Reown AppKit
- **`BlockchainService`**: Manages on-chain verification and contract calls

## 📱 Build for Production

```bash
# iOS
flutter build ios --dart-define=PROJECT_ID=YOUR_PROJECT_ID

# Android
flutter build apk --dart-define=PROJECT_ID=YOUR_PROJECT_ID
```

## 🆘 Common Issues

**Wallet Connection Fails:**
- Check your `PROJECT_ID` is correct and provided via `--dart-define`
- Verify network connectivity

**Proof Generation Fails:**
- Ensure `.zkey` file is in `flutter/assets/`
- Check circuit inputs match expected format

**On-Chain Verification Fails:**
- Verify contract is deployed at correct address
- Check you're connected to the right network
- Check if the inputs format is correct

## 📚 Resources

- [Mopro Documentation](https://zkmopro.org/docs)
- [Reown AppKit](https://docs.reown.com/appkit)
- [Circom Documentation](https://docs.circom.io)
