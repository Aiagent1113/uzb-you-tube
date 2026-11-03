import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/security/security_guard.dart';
import 'core/theme/app_theme.dart';
import 'features/subscription/domain/quota_manager.dart';
import 'features/webview/presentation/youtube_webview_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure immersive Android / iOS system chrome
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.obsidianBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 1. Execute Anti-Tampering & Anti-Reverse Engineering Security Audit
  final securityOk = await SecurityGuard().initializeSecurityAudit();

  // 2. Initialize Freemium Quota Storage & Licensing
  await QuotaManager().initialize();

  runApp(UzDubApp(isSecurityPassed: securityOk));
}

class UzDubApp extends StatelessWidget {
  final bool isSecurityPassed;

  const UzDubApp({super.key, required this.isSecurityPassed});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UzDub YouTube AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: isSecurityPassed
          ? const YouTubeWebViewScreen()
          : const SecurityLockdownScreen(),
    );
  }
}

/// Screen displayed if root, Frida, or debugger tampering is detected
class SecurityLockdownScreen extends StatelessWidget {
  const SecurityLockdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidianBlack,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.neonRed.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.neonRed, width: 2),
                ),
                child: const Icon(Icons.shield_outlined, color: AppTheme.neonRed, size: 60),
              ),
              const SizedBox(height: 24),
              const Text(
                'XAVFSIZLIK TAHDIDI ANIQLANDI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Qurilmada Root, Debugger yoki xavfli modifikatsiyalar (Frida/Xposed) aniqlandi. Xavfsizlik siyosati tufayli ilovadan foydalanish cheklandi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => SystemNavigator.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceBlack,
                  side: const BorderSide(color: Colors.white24),
                ),
                child: const Text('Ilovadan Chiqish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
