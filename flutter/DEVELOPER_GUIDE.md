# Developer Guide

## 🏗 Architecture Overview

This codebase follows a clean, modular architecture that separates concerns into distinct layers:

### 📁 Directory Structure

```
lib/
├── main.dart                     # App entry point (minimal)
├── config/                       # Configuration layer
│   ├── app_config.dart          # App-wide constants
│   └── network_config.dart      # Blockchain settings
├── models/                       # Data layer
│   └── proof_result.dart        # Data models & state
├── services/                     # Business logic layer
│   ├── wallet_service.dart      # Wallet operations
│   ├── proof_service.dart       # ZK proof operations
│   └── blockchain_service.dart  # Blockchain operations
├── widgets/                      # Presentation layer (reusable)
│   ├── wallet_connect_button.dart
│   ├── circuit_info.dart
│   ├── proof_form.dart
│   └── proof_results.dart
├── screens/                      # Presentation layer (screens)
│   └── home_screen.dart
└── utils/                        # Utility layer
    └── deep_link_handler.dart
```

## 🔧 Key Design Patterns

### 1. Singleton Services
All services use the singleton pattern for global state management:

```dart
// Services are accessed via static instances
final walletService = WalletService.instance;
final proofService = ProofService.instance;
final blockchainService = BlockchainService.instance;
```

### 2. Configuration-Driven
All app constants are centralized in config files:

```dart
// Easy to customize without touching business logic
AppConfig.projectId;
NetworkConfig.verifierContractAddress;
```

### 3. Model-Based State
Immutable data models with copy methods:

```dart
// Clean state updates
final updatedResult = proofResult.copyWith(
  localVerification: true,
);
```

## 🛠 Common Customization Tasks

### Adding a New Circuit Input

1. **Update the Model**:
```dart
// In models/proof_result.dart
class CircuitInputs {
  final String a;
  final String b;
  final String newInput; // Add here
  
  String toJson() {
    return '{"a":["$a"],"b":["$b"],"newInput":["$newInput"]}';
  }
}
```

2. **Update the UI**:
```dart
// In widgets/proof_form.dart
Widget _buildInputForm() {
  return Column(
    children: [
      // Existing inputs...
      TextFormField(
        controller: _newInputController,
        decoration: const InputDecoration(
          labelText: "New Input",
        ),
      ),
    ],
  );
}
```

### Adding a New Service

1. **Create the Service**:
```dart
// services/your_service.dart
class YourService {
  static YourService? _instance;
  
  static YourService get instance {
    _instance ??= YourService._internal();
    return _instance!;
  }
  
  YourService._internal();
  
  Future<void> doSomething() async {
    // Your logic here
  }
}
```

2. **Use in Widgets**:
```dart
final yourService = YourService.instance;
await yourService.doSomething();
```

### Adding a New Network

1. **Update Configuration**:
```dart
// In config/network_config.dart
static const Map<String, NetworkInfo> networks = {
  'your_network': NetworkInfo(
    name: 'Your Network',
    chainId: 'eip155:12345',
    rpcUrl: 'https://your-rpc.com',
    blockExplorerUrl: 'https://your-explorer.com',
    isTestnet: false,
  ),
};
```

2. **Add to Supported Chains**:
```dart
static const List<String> supportedChains = [
  'eip155:1',
  'eip155:12345', // Your chain ID
];
```

## 🧪 Testing Strategy

### Unit Tests
Test business logic in isolation:

```dart
// test/services/proof_service_test.dart
void main() {
  group('ProofService', () {
    test('generates valid proof', () async {
      final service = ProofService.instance;
      final inputs = CircuitInputs(a: '5', b: '3');
      
      final result = await service.generateProof(inputs);
      
      expect(result.hasProof, true);
    });
  });
}
```

### Widget Tests
Test UI components:

```dart
// test/widgets/proof_form_test.dart
void main() {
  testWidgets('ProofForm shows input fields', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ProofForm()),
    ));
    
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
```

## 🔄 State Management

### Current Approach
- **Local State**: `setState()` for widget-specific state
- **Global State**: Singleton services for shared state
- **Configuration**: Static constants in config files

### For Larger Apps
Consider adding a state management solution:

```dart
// Example with Provider
class AppStateNotifier extends ChangeNotifier {
  ProofResult _proofResult = ProofResult();
  
  ProofResult get proofResult => _proofResult;
  
  void updateProofResult(ProofResult result) {
    _proofResult = result;
    notifyListeners();
  }
}
```

## 📦 Adding Dependencies

### 1. Update pubspec.yaml
```yaml
dependencies:
  your_package: ^1.0.0
```

### 2. Create Service Wrapper
```dart
// services/your_package_service.dart
class YourPackageService {
  static YourPackageService? _instance;
  final YourPackage _package = YourPackage();
  
  static YourPackageService get instance {
    _instance ??= YourPackageService._internal();
    return _instance!;
  }
  
  YourPackageService._internal();
  
  Future<void> usePackage() async {
    return await _package.doSomething();
  }
}
```

## 🔧 Performance Considerations

### Lazy Loading
Services use lazy initialization:

```dart
// Only created when first accessed
static YourService get instance {
  _instance ??= YourService._internal();
  return _instance!;
}
```

### Memory Management
Proper disposal in services:

```dart
void dispose() {
  _someResource?.dispose();
  _instance = null;
}
```

### Async Operations
Use proper error handling:

```dart
try {
  final result = await heavyOperation();
  return successResult(result);
} catch (e) {
  debugPrint('Error: $e');
  return errorResult(e);
}
```

## 🐛 Debugging

### Enable Debug Mode
```dart
// In config/app_config.dart
static const bool debugMode = true;
```

### Service Logging
All services include debug prints:

```dart
debugPrint('[ServiceName] Operation started');
// Your code here
debugPrint('[ServiceName] Operation completed');
```

### Error Tracking
Centralized error handling in services:

```dart
try {
  // Operation
} catch (e) {
  debugPrint('[Service] Error: $e');
  return errorResult(e);
}
```

## 🚀 Deployment Checklist

### Before Release
1. Set `debugMode = false` in AppConfig
2. Update PROJECT_ID for production
3. Verify contract addresses for target networks
4. Test on actual devices
5. Update app version in pubspec.yaml

### Build Commands
```bash
# Development
flutter run --dart-define=PROJECT_ID=dev_id

# Production
flutter build apk --dart-define=PROJECT_ID=prod_id
```

## 📚 Further Reading

- **Flutter Architecture**: [Official Guide](https://docs.flutter.dev/development/data-and-backend/state-mgmt)
- **Clean Architecture**: [Robert Martin's Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- **Mopro Documentation**: [https://zkmopro.org/docs](https://zkmopro.org/docs)

---

Happy coding! 🎉 