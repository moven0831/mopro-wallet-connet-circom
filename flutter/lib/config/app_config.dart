/// Configuration for app-wide settings and constants
class AppConfig {
  // App Information
  static const String appName = 'Mopro Wallet Connect';
  static const String appDescription = 'Zero-Knowledge Proof Generator with Wallet Connect';
  static const String appUrl = 'https://mopro.org/';
  static const List<String> appIcons = ['https://avatars.githubusercontent.com/u/37784886'];
  
  // Deep Link Configuration
  static const String nativeScheme = 'moprowallet://';
  static const String universalLink = 'https://mopro.org/moprowallet';
  
  // Circuit Configuration
  static const String circuitName = 'Multiplier Circuit';
  static const String circuitDescription = 'This circuit proves you know two numbers (a, b) that multiply to a specific result.';
  static const String zkeyPath = 'assets/multiplier2_final.zkey';
  
  // Default Input Values
  static const String defaultInputA = '5';
  static const String defaultInputB = '3';
  
  // UI Configuration
  static const bool debugMode = false;
  static const int connectionTimeoutSeconds = 15;
  
  /// Get the project ID from environment variables (required)
  static String get projectId {
    const projectId = String.fromEnvironment('PROJECT_ID');
    if (projectId.isEmpty) {
      throw Exception('PROJECT_ID is required. Please run with: flutter run --dart-define=PROJECT_ID=YOUR_REOWN_PROJECT_ID');
    }
    return projectId;
  }
  
  /// Check if app is in debug mode
  static bool get isDebugMode => 
      const bool.fromEnvironment('DEBUG_MODE', defaultValue: debugMode);
} 