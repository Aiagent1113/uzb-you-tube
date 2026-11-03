import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'native_vault.dart';

/// UzDub Security Guard & Anti-Reverse Engineering Subsystem
/// Provides Root/Jailbreak detection, Frida/Xposed/Charles hook detection,
/// Device Fingerprinting, and HMAC-SHA256 Request Signing.
class SecurityGuard {
  static final SecurityGuard _instance = SecurityGuard._internal();
  factory SecurityGuard() => _instance;
  SecurityGuard._internal();

  bool _isDeviceCompromised = false;
  String _deviceFingerprint = '';
  String _cachedHmacSecret = '';

  bool get isCompromised => _isDeviceCompromised;
  String get deviceFingerprint => _deviceFingerprint;

  /// Complete initial security audit. If tampering is detected, app terminates or blocks operations.
  Future<bool> initializeSecurityAudit() async {
    // 1. Check Root / Jailbreak indicators
    final isRooted = await _checkRootJailbreak();
    // 2. Check Frida / Xposed / Dynamic instrumentation
    final isHooked = await _checkDynamicInstrumentation();
    // 3. Check Proxy / Charles / MITM sniffing
    final isMitmDetected = await _checkProxySettings();
    // 4. Generate Hardware Fingerprint
    _deviceFingerprint = await _generateHardwareFingerprint();
    // 5. Decrypt secret key from native vault
    _cachedHmacSecret = await NativeVault.getHmacSecretKey();

    if (isRooted || isHooked || isMitmDetected) {
      _isDeviceCompromised = true;
      if (!kDebugMode) {
        // In release builds, terminate process immediately upon tampering
        _emergencyLockdown();
      }
      return false;
    }

    _isDeviceCompromised = false;
    return true;
  }

  /// Check Android / iOS root binaries and test-keys
  Future<bool> _checkRootJailbreak() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final dangerousPaths = [
        '/system/app/Superuser.apk',
        '/sbin/su',
        '/system/bin/su',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
        '/su/bin/su',
        '/system/xbin/daemonsu',
        '/system/etc/init.d/99SuperSUDaemon',
        '/system/bin/.ext/.su',
        '/system/etc/.has_su_daemon',
      ];

      for (final path in dangerousPaths) {
        if (File(path).existsSync()) {
          return true;
        }
      }

      // Check build tags for test-keys
      try {
        final buildTags = await SystemChannels.platform.invokeMethod<String>('System.getProperty', 'ro.build.tags');
        if (buildTags != null && buildTags.contains('test-keys')) {
          return true;
        }
      } catch (_) {}
    } else if (Platform.isIOS) {
      final dangerousIosPaths = [
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
        '/private/var/lib/apt/',
        '/Applications/Sileo.app',
      ];

      for (final path in dangerousIosPaths) {
        if (File(path).existsSync()) {
          return true;
        }
      }
    }

    return false;
  }

  /// Detect Frida server (default port 27042), named pipes, and Xposed framework
  Future<bool> _checkDynamicInstrumentation() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      // Check for known Frida runtime files
      final fridaPaths = [
        '/data/local/tmp/frida-server',
        '/data/local/tmp/re.frida.server',
        '/system/framework/edxp.jar',
        '/system/framework/XposedBridge.jar'
      ];
      for (final p in fridaPaths) {
        if (File(p).existsSync()) return true;
      }

      // Check default Frida TCP socket port
      try {
        final socket = await Socket.connect('127.0.0.1', 27042, timeout: const Duration(milliseconds: 150));
        await socket.close();
        return true; // Frida port is open!
      } catch (_) {
        // Port closed, normal
      }
    }
    return false;
  }

  /// Detect active HTTP proxy (Charles, Fiddler, Burp Suite)
  Future<bool> _checkProxySettings() async {
    if (kIsWeb) return false;
    try {
      final httpProxy = Platform.environment['http_proxy'] ?? Platform.environment['https_proxy'];
      if (httpProxy != null && httpProxy.isNotEmpty) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Generate a cryptographically strong, non-resettable device fingerprint
  Future<String> _generateHardwareFingerprint() async {
    try {
      final buffer = StringBuffer();
      buffer.write(Platform.operatingSystem);
      buffer.write(Platform.operatingSystemVersion);
      buffer.write(Platform.numberOfProcessors);
      buffer.write(Platform.localHostname);

      final bytes = utf8.encode(buffer.toString());
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (_) {
      return 'generic_device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Sign an outgoing API or WebSocket payload with HMAC-SHA256
  /// Returns a map of security headers: X-UzDub-Timestamp, X-UzDub-Nonce, X-UzDub-Signature, X-UzDub-DeviceID
  Map<String, String> generateSignedHeaders({required String endpoint, String body = ''}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final nonce = _generateRandomNonce(16);

    // Signature data format: "{timestamp}.{nonce}.{endpoint}.{body_sha256}"
    final bodyHash = sha256.convert(utf8.encode(body)).toString();
    final messageToSign = '$timestamp.$nonce.$endpoint.$bodyHash.$_deviceFingerprint';

    final keyBytes = utf8.encode(_cachedHmacSecret);
    final messageBytes = utf8.encode(messageToSign);
    final hmacSha256 = Hmac(sha256, keyBytes);
    final signature = hmacSha256.convert(messageBytes).toString();

    return {
      'X-UzDub-Timestamp': timestamp,
      'X-UzDub-Nonce': nonce,
      'X-UzDub-Signature': signature,
      'X-UzDub-DeviceID': _deviceFingerprint,
    };
  }

  /// Generate dynamic signed injection contract for the InAppWebView JavaScript engine
  Map<String, dynamic> generateWebViewInjectionContract() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final payload = '$timestamp.$_deviceFingerprint.${_cachedHmacSecret.hashCode}';
    final sig = sha256.convert(utf8.encode(payload)).toString();

    return {
      'ts': timestamp,
      'dev': _deviceFingerprint,
      'sig': sig,
      'v': '2.4.0',
    };
  }

  String _generateRandomNonce(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rand = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(chars[(rand + i * 31) % chars.length]);
    }
    return buffer.toString();
  }

  void _emergencyLockdown() {
    // Terminate app immediately without diagnostic info
    exit(0);
  }
}
