import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:reown_appkit/reown_appkit.dart';

/// Deep link handler for wallet connection responses
/// 
/// This utility class handles deep links from wallets when they respond
/// to connection requests, making the wallet integration seamless.
class DeepLinkHandler {
  static const _eventChannel = EventChannel('com.example.moprowallet/events');
  static late ReownAppKitModal _appKitModal;

  /// Initialize the deep link handler
  /// 
  /// This method sets up the event channel listener for deep links.
  /// Call this after initializing the AppKit modal.
  /// 
  /// [appKitModal] - The initialized AppKit modal instance
  static void init(ReownAppKitModal appKitModal) {
    // Skip initialization on web platform
    if (kIsWeb) return;

    try {
      _appKitModal = appKitModal;
      _eventChannel.receiveBroadcastStream().listen(_onLink, onError: _onError);
      debugPrint('[DeepLinkHandler] Deep link handler initialized');
    } catch (e) {
      debugPrint('[DeepLinkHandler] Error initializing deep link handler: $e');
    }
  }

  /// Handle incoming deep links
  /// 
  /// This method processes deep links received from wallets
  /// and dispatches them to the AppKit modal for handling.
  static void _onLink(dynamic link) async {
    try {
      debugPrint('[DeepLinkHandler] Received deep link: $link');
      await _appKitModal.dispatchEnvelope(link);
      debugPrint('[DeepLinkHandler] Deep link processed successfully');
    } catch (e) {
      debugPrint('[DeepLinkHandler] Error processing deep link: $e');
    }
  }

  /// Handle deep link errors
  /// 
  /// This method handles errors that occur during deep link processing.
  static void _onError(dynamic error) {
    debugPrint('[DeepLinkHandler] Deep link error: $error');
  }
} 