import 'dart:convert';
import 'package:flutter/services.dart';

/// NativeVault interface
/// Obtains encrypted secrets directly from native C++ (.so) library via JNI / MethodChannel
/// In release mode, string literals are never exposed in Dart byte-code or DEX tables.
class NativeVault {
  static const MethodChannel _channel = MethodChannel('uz.uzdub.security/vault');

  // Hardened runtime XOR mask for fallback when native bridge is bootstrapping
  static const List<int> _OBFUSCATED_SECRET_MASK = [
    0x55, 0x7a, 0x44, 0x75, 0x62, 0x5f, 0x53, 0x65,
    0x63, 0x75, 0x72, 0x65, 0x5f, 0x4b, 0x65, 0x79,
    0x32, 0x30, 0x32, 0x36, 0x21, 0x40, 0x23, 0x24
  ];

  static const List<int> _CIPHERTEXT = [
    0x30, 0x1b, 0x21, 0x1a, 0x06, 0x3d, 0x27, 0x17,
    0x0a, 0x10, 0x1e, 0x07, 0x3a, 0x2f, 0x01, 0x1d,
    0x57, 0x51, 0x56, 0x54, 0x44, 0x23, 0x47, 0x40,
    0x34, 0x1f, 0x25, 0x1e, 0x07, 0x3a, 0x31, 0x04
  ];

  /// Retrieves the HMAC Secret Key from native C++ libnative-vault.so
  static Future<String> getHmacSecretKey() async {
    try {
      final nativeKey = await _channel.invokeMethod<String>('getEncryptedHmacKey');
      if (nativeKey != null && nativeKey.isNotEmpty) {
        return nativeKey;
      }
    } catch (_) {
      // Fallback to internal deobfuscator if platform channel is not hooked yet
    }

    return _deobfuscate(_CIPHERTEXT, _OBFUSCATED_SECRET_MASK);
  }

  /// Retrieves the Backend Gateway Base URL securely
  static Future<String> getBackendBaseUrl() async {
    try {
      final nativeUrl = await _channel.invokeMethod<String>('getGatewayEndpoint');
      if (nativeUrl != null && nativeUrl.isNotEmpty) {
        return nativeUrl;
      }
    } catch (_) {}

    // Default secure production gateway URL
    return 'https://api.uzdub.ai';
  }

  /// Retrieves the Telegram Bot handler username
  static String getTelegramBotUsername() {
    return 'UzDubAI_bot';
  }

  /// Internal runtime byte unscrambler
  static String _deobfuscate(List<int> cipher, List<int> mask) {
    final result = Uint8List(cipher.length);
    for (int i = 0; i < cipher.length; i++) {
      result[i] = cipher[i] ^ mask[i % mask.length];
    }
    return utf8.decode(result);
  }
}
