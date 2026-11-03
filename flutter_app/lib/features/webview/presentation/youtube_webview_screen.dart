import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../injection/injection_builder.dart';
import '../../player_overlay/presentation/floating_player_bar.dart';
import '../../subscription/domain/quota_manager.dart';
import '../../subscription/presentation/pro_modal.dart';

/// YouTube Mobile WebView Container with Luxury Synchronized Floating Control Dock
class YouTubeWebViewScreen extends StatefulWidget {
  const YouTubeWebViewScreen({super.key});

  @override
  State<YouTubeWebViewScreen> createState() => _YouTubeWebViewScreenState();
}

class _YouTubeWebViewScreenState extends State<YouTubeWebViewScreen> with WidgetsBindingObserver {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _loadProgress = 0.0;

  // Floating Bar State
  bool _isPlayerBarVisible = true;
  bool _isDubbingEnabled = true;
  String _activeVoice = AppConstants.voiceMadina; // Default: Madina Neural HD
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Inject the obfuscated engine into the loaded page
  Future<void> _injectUzDubEngine() async {
    if (_webViewController == null) return;
    try {
      await InjectionBuilder.injectIntoWebView(_webViewController!);
      // Sync initial settings
      _syncSettingsToEngine();
    } catch (e) {
      debugPrint('[UzDub Injection Error] $e');
    }
  }

  void _syncSettingsToEngine() {
    if (_webViewController == null) return;
    _webViewController!.evaluateJavascript(
      source: '''
        if (window.UzDubController) {
          window.UzDubController.setEnabled($_isDubbingEnabled);
          window.UzDubController.setVoice("$_activeVoice");
          window.UzDubController.setSpeed($_playbackSpeed);
        }
      ''',
    );
  }

  void _toggleDubbing() {
    setState(() {
      _isDubbingEnabled = !_isDubbingEnabled;
    });
    _syncSettingsToEngine();
  }

  void _onVoiceChanged(String newVoice) {
    final quota = QuotaManager();
    if (!quota.canUseVoice(newVoice)) {
      ProModal.show(context);
      return;
    }

    setState(() {
      _activeVoice = newVoice;
    });
    _syncSettingsToEngine();
  }

  void _onSpeedChanged(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _syncSettingsToEngine();
  }

  /// Toggle bar visibility when user taps the player area
  void _toggleBarVisibility() {
    setState(() {
      _isPlayerBarVisible = !_isPlayerBarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidianBlack,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. YouTube Mobile InAppWebView
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleBarVisibility,
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(AppConstants.youtubeMobileUrl),
                ),
                initialSettings: InAppWebViewSettings(
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  javaScriptEnabled: true,
                  cacheEnabled: true,
                  supportZoom: false,
                  transparentBackground: true,
                  useShouldOverrideUrlLoading: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  _registerJavaScriptHandlers(controller);
                },
                onLoadStart: (controller, url) {
                  setState(() => _isLoading = true);
                },
                onProgressChanged: (controller, progress) {
                  setState(() => _loadProgress = progress / 100);
                },
                onLoadStop: (controller, url) async {
                  setState(() => _isLoading = false);
                  await _injectUzDubEngine();
                },
              ),
            ),

            // 2. Loading Indicator (Luxury Neon Progress)
            if (_isLoading && _loadProgress < 1.0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _loadProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonRed),
                  minHeight: 2.5,
                ),
              ),

            // 3. Floating Player Bar (Synchronized Luxury Glass Dock)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: FloatingPlayerBar(
                isVisible: _isPlayerBarVisible,
                isDubbingEnabled: _isDubbingEnabled,
                activeVoice: _activeVoice,
                playbackSpeed: _playbackSpeed,
                onToggleDubbing: _toggleDubbing,
                onVoiceChanged: _onVoiceChanged,
                onSpeedChanged: _onSpeedChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Register bi-directional JavaScript Handlers for the InAppWebView bridge
  void _registerJavaScriptHandlers(InAppWebViewController controller) {
    // A. Subtitle captured event
    controller.addJavaScriptHandler(
      handlerName: 'onSubtitleCaptured',
      callback: (args) {
        if (args.isNotEmpty) {
          debugPrint('[UzDub Subtitle] ${args[0]}');
        }
      },
    );

    // B. Subtitle translated to Uzbek
    controller.addJavaScriptHandler(
      handlerName: 'onSubtitleTranslated',
      callback: (args) {
        if (args.isNotEmpty) {
          debugPrint('[UzDub Uzbek] ${args[0]}');
        }
      },
    );

    // C. Quota consumption callback
    controller.addJavaScriptHandler(
      handlerName: 'onQuotaConsumed',
      callback: (args) async {
        if (args.isNotEmpty) {
          try {
            final data = jsonDecode(args[0]);
            final seconds = (data['seconds'] as num?)?.toInt() ?? 2;
            final voice = (data['voiceType'] as String?) ?? _activeVoice;

            final allowed = await QuotaManager().consumeQuota(
              voiceType: voice,
              seconds: seconds,
            );

            if (!allowed && mounted) {
              // Quota exhausted! Prompt user to upgrade to PRO
              _webViewController?.evaluateJavascript(
                source: 'if (window.UzDubController) window.UzDubController.triggerDuckingRestore();',
              );
              ProModal.show(context);
            }
          } catch (_) {}
        }
      },
    );

    // D. Audio ducking state change
    controller.addJavaScriptHandler(
      handlerName: 'onDuckingStateChanged',
      callback: (args) {
        // Log or update ducking HUD if desired
      },
    );

    // E. Neural audio speech request (communicates with Backend / Edge TTS WebSocket)
    controller.addJavaScriptHandler(
      handlerName: 'onSpeakNeuralAudio',
      callback: (args) async {
        if (args.isNotEmpty) {
          try {
            final data = jsonDecode(args[0]);
            final text = data['text'] as String? ?? '';
            final voice = data['voice'] as String? ?? _activeVoice;

            // Enforce quota check
            final quota = QuotaManager();
            if (!quota.canUseVoice(voice)) {
              if (mounted) ProModal.show(context);
              return {'status': 'quota_exceeded'};
            }

            // In production, dispatches text to Edge TTS / backend WebSocket
            debugPrint('[UzDub Neural TTS Request] $voice: $text');
            return {'status': 'success'};
          } catch (e) {
            return {'status': 'error', 'message': e.toString()};
          }
        }
        return {'status': 'invalid_arguments'};
      },
    );
  }
}
