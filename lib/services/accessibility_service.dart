import 'package:flutter/services.dart';

class AccessibilityService {
  static const MethodChannel _channel =
      MethodChannel('com.clientai.app/accessibility');

  static const List<String> supportedApps = [
    'com.whatsapp',
    'org.telegram.messenger',
    'com.instagram.android',
    'com.facebook.orca', // Messenger
    'com.linkedin.android',
  ];

  static Future<bool> isAccessibilityEnabled() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      // ignore
    }
  }

  static Future<String?> getLastMessage() async {
    try {
      final result = await _channel.invokeMethod<String>('getLastMessage');
      return result;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getActiveApp() async {
    try {
      final result = await _channel.invokeMethod<String>('getActiveApp');
      return result;
    } catch (e) {
      return null;
    }
  }

  // Stream of incoming messages from native side
  static Stream<Map<String, String>> get messageStream {
    const EventChannel eventChannel =
        EventChannel('com.clientai.app/message_stream');
    return eventChannel.receiveBroadcastStream().map((event) {
      final map = Map<String, dynamic>.from(event as Map);
      return {
        'message': map['message']?.toString() ?? '',
        'app': map['app']?.toString() ?? '',
        'sender': map['sender']?.toString() ?? '',
      };
    });
  }
}
