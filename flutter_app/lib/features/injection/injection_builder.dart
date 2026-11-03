import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../core/security/security_guard.dart';

/// Prepares and injects the hardened, obfuscated JavaScript engine
/// into the YouTube Mobile WebView.
class InjectionBuilder {
  static String? _cachedScript;

  /// Loads and prepares the JavaScript injection script with security credentials
  static Future<String> prepareInjectionScript() async {
    if (_cachedScript == null) {
      try {
        _cachedScript = await rootBundle.loadString(
          'lib/features/injection/assets/obfuscated_injection.js'
        );
      } catch (_) {
        // Fallback for testing environments
        _cachedScript = '''
          console.log("[UzDub] Core Injection Engine Active");
        ''';
      }
    }

    final contract = SecurityGuard().generateWebViewInjectionContract();
    final contractJson = jsonEncode(contract);

    // Bootstrap header that passes the cryptographic handshake before executing the protected payload
    final bootstrapCode = '''
      window.__UZDUB_SECURITY_CONTRACT__ = $contractJson;
      window.UzDubSecurityToken = "${contract['sig']}";
      $_cachedScript
    ''';

    return bootstrapCode;
  }

  /// Injects the core engine into the active InAppWebViewController
  static Future<void> injectIntoWebView(InAppWebViewController controller) async {
    final script = await prepareInjectionScript();
    await controller.evaluateJavascript(source: script);
  }
}
