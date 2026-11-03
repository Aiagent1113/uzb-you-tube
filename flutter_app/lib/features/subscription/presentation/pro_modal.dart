import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/quota_manager.dart';

/// Luxury Glassmorphic PRO Subscription & Activation Modal
class ProModal extends StatefulWidget {
  const ProModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProModal(),
    );
  }

  @override
  State<ProModal> createState() => _ProModalState();
}

class _ProModalState extends State<ProModal> {
  final TextEditingController _keyController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _openTelegramBot() async {
    final uri = Uri.parse(AppConstants.telegramBotUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Telegram bot ochilmadi: @UzDubAI_bot ga murojaat qiling'),
            backgroundColor: AppTheme.neonRed,
          ),
        );
      }
    }
  }

  Future<void> _activateLicense() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _errorMessage = 'Iltimos, aktivatsiya kalitini kiriting');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await QuotaManager().activateProLicense(key);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.verified, color: Colors.greenAccent),
              SizedBox(width: 10),
              Text('PRO status muvaffaqiyatli faollashtirildi!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: const Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Kalit noto‘g‘ri yoki yaroqsiz! Botdan qayta oling.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: const Color(0xE6101014),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTheme.borderGlowing, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonRed.withOpacity(0.35),
              blurRadius: 36,
              spreadRadius: 2,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header with PRO Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.proBadgeGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'UzDub Premium AI',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Cheksiz tabiiy o‘zbek ovozlari va yuqori tezlikdagi sinxron dublyaj',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Feature perks cards
            _buildPerkItem(
              icon: Icons.record_voice_over_rounded,
              title: 'Cheksiz HD Neural Ovozlar',
              desc: 'Madina va Sardor tabiiy diktor ovozlaridan cheklovlarsiz foydalaning.',
            ),
            const SizedBox(height: 10),
            _buildPerkItem(
              icon: Icons.bolt_rounded,
              title: '0.1s Zero-Latency Audio Ducking',
              desc: 'Video ovozini avtomatik pasaytirib, dublyajni toza yetkazish.',
            ),
            const SizedBox(height: 10),
            _buildPerkItem(
              icon: Icons.all_inclusive_rounded,
              title: 'Kunlik 60 daqiqalik to‘siq yo‘q',
              desc: 'Istalgan uzunlikdagi darslik va filmlarni to‘liq tomosha qiling.',
            ),
            const SizedBox(height: 22),

            // Telegram Bot Purchase Button
            ElevatedButton(
              onPressed: _openTelegramBot,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonRed,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 10,
                shadowColor: AppTheme.neonRed.withOpacity(0.6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Telegram Bot Orqali Xarid Qilish',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Divider with "Yoki Kalitni Kiriting"
            Row(
              children: const [
                Expanded(child: Divider(color: Colors.white12)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('YOKI KALIT BILAN', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Divider(color: Colors.white12)),
              ],
            ),
            const SizedBox(height: 14),

            // License Key Input Field
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.key_rounded, color: AppTheme.neonRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _keyController,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: 'UZDUB-PRO-XXXX-XXXX',
                        hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _activateLicense,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.neonRed,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonRed))
                        : const Text('Faollashtirish', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerkItem({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.neonRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.neonRed, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
