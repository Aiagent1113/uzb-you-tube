import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../subscription/domain/quota_manager.dart';
import '../../subscription/presentation/pro_modal.dart';

/// Voice Selector Bottom Sheet with Luxury Glassmorphism
class VoiceSelectorSheet extends StatelessWidget {
  final String currentVoice;
  final Function(String voice) onVoiceSelected;

  const VoiceSelectorSheet({
    super.key,
    required this.currentVoice,
    required this.onVoiceSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String currentVoice,
    required Function(String) onVoiceSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceSelectorSheet(
        currentVoice: currentVoice,
        onVoiceSelected: onVoiceSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quota = QuotaManager();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xF2121216),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTheme.borderGlowing, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonRed.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.mic_external_on_rounded, color: AppTheme.neonRed, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Dublyaj Ovozini Tanlang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Tabiiy o‘zbek neyron diktorlari yoki standart robot ovozi',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Voice 1: Madina Neural (HD)
            _buildVoiceOption(
              context: context,
              voiceId: AppConstants.voiceMadina,
              title: 'Madina Neural (HD)',
              subtitle: 'Mayin, tabiiy ayol diktor ovozi',
              badge: 'NEURAL HD',
              isNeural: true,
              isSelected: currentVoice == AppConstants.voiceMadina,
              quotaRemainingSeconds: quota.hdRemainingSeconds,
            ),
            const SizedBox(height: 12),

            // Voice 2: Sardor Neural (HD)
            _buildVoiceOption(
              context: context,
              voiceId: AppConstants.voiceSardor,
              title: 'Sardor Neural (HD)',
              subtitle: 'Jiddiy, professional erkak diktor ovozi',
              badge: 'NEURAL HD',
              isNeural: true,
              isSelected: currentVoice == AppConstants.voiceSardor,
              quotaRemainingSeconds: quota.hdRemainingSeconds,
            ),
            const SizedBox(height: 12),

            // Voice 3: Standart Robot
            _buildVoiceOption(
              context: context,
              voiceId: AppConstants.voiceRobot,
              title: 'Standart Robot Ovozi',
              subtitle: 'Qurilma ichki sintezatori (Cheksiz bepul)',
              badge: 'STANDART',
              isNeural: false,
              isSelected: currentVoice == AppConstants.voiceRobot,
              quotaRemainingSeconds: quota.robotRemainingSeconds,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceOption({
    required BuildContext context,
    required String voiceId,
    required String title,
    required String subtitle,
    required String badge,
    required bool isNeural,
    required bool isSelected,
    required int quotaRemainingSeconds,
  }) {
    final quota = QuotaManager();
    final isLocked = isNeural && !quota.isPro && quotaRemainingSeconds <= 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isLocked) {
            Navigator.pop(context);
            ProModal.show(context);
            return;
          }
          onVoiceSelected(voiceId);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.neonRed.withOpacity(0.12) : const Color(0xFF1B1B20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.neonRed : Colors.white.withOpacity(0.08),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.neonRed : Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isNeural ? Icons.record_voice_over : Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isNeural ? AppTheme.neonRed.withOpacity(0.2) : Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isNeural ? AppTheme.neonRed : Colors.white24,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: isNeural ? AppTheme.neonRed : Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    if (isNeural && !quota.isPro) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Qolgan HD limit: ${(quotaRemainingSeconds / 60).toStringAsFixed(1)} daqiqa',
                        style: TextStyle(
                          color: isLocked ? Colors.redAccent : Colors.amberAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, color: Colors.amber, size: 18),
                )
              else if (isSelected)
                const Icon(Icons.check_circle_rounded, color: AppTheme.neonRed, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
