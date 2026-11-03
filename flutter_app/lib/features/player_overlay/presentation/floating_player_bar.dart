import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../subscription/domain/quota_manager.dart';
import '../../subscription/presentation/pro_modal.dart';
import 'voice_selector_sheet.dart';

/// YouTube Synchronized Luxury Glassmorphic Floating Player Bar
/// Appears and hides seamlessly with YouTube player controls via animated transitions
class FloatingPlayerBar extends StatelessWidget {
  final bool isVisible;
  final bool isDubbingEnabled;
  final String activeVoice;
  final double playbackSpeed;
  final VoidCallback onToggleDubbing;
  final ValueChanged<String> onVoiceChanged;
  final ValueChanged<double> onSpeedChanged;

  const FloatingPlayerBar({
    super.key,
    required this.isVisible,
    required this.isDubbingEnabled,
    required this.activeVoice,
    required this.playbackSpeed,
    required this.onToggleDubbing,
    required this.onVoiceChanged,
    required this.onSpeedChanged,
  });

  String _formatVoiceLabel(String voiceId) {
    if (voiceId.contains('Madina')) return 'Madina (HD)';
    if (voiceId.contains('Sardor')) return 'Sardor (HD)';
    return 'Robot';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      offset: isVisible ? Offset.zero : const Offset(0, 1.4),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        opacity: isVisible ? 1.0 : 0.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xE6141418), Color(0xCC0E0E12)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDubbingEnabled ? AppTheme.borderGlowing : AppTheme.borderFrosted,
                    width: isDubbingEnabled ? 1.4 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.65),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                    if (isDubbingEnabled)
                      BoxShadow(
                        color: AppTheme.neonRed.withOpacity(0.3),
                        blurRadius: 24,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: ListenableBuilder(
                  listenable: QuotaManager(),
                  builder: (context, _) {
                    final quota = QuotaManager();
                    final remainingMinutes = (quota.totalRemainingSeconds / 60).clamp(0, 60).toStringAsFixed(0);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: Main Controls
                        Row(
                          children: [
                            // Play/Pause Dubbing Button
                            _buildDubbingToggleButton(),
                            const SizedBox(width: 12),

                            // Voice Selector Chip
                            Expanded(
                              child: _buildVoiceSelectorChip(context),
                            ),
                            const SizedBox(width: 10),

                            // Speed Selector Button
                            _buildSpeedSelectorButton(context),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Row 2: Quota Progress Indicator & PRO Banner
                        Row(
                          children: [
                            // Quota gauge
                            Icon(
                              quota.isPro ? Icons.verified : Icons.timer_outlined,
                              color: quota.isPro ? Colors.greenAccent : AppTheme.textMuted,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              quota.isPro ? 'PRO Rejim: Cheksiz Dublyaj' : 'Kunlik Limit: $remainingMinutes/60 daq',
                              style: TextStyle(
                                color: quota.isPro ? Colors.greenAccent : AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Progress bar
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: quota.quotaProgressPercentage,
                                  minHeight: 4,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    quota.isPro
                                        ? Colors.greenAccent
                                        : (quota.totalRemainingSeconds < 300
                                            ? Colors.redAccent
                                            : AppTheme.neonRed),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // PRO Upgrade Chip
                            if (!quota.isPro)
                              GestureDetector(
                                onTap: () => ProModal.show(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.proBadgeGradient,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.neonRed.withOpacity(0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDubbingToggleButton() {
    return GestureDetector(
      onTap: onToggleDubbing,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDubbingEnabled ? AppTheme.neonRed : const Color(0xFF222228),
          shape: BoxShape.circle,
          boxShadow: isDubbingEnabled
              ? [
                  BoxShadow(
                    color: AppTheme.neonRed.withOpacity(0.6),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ]
              : null,
          border: Border.all(
            color: isDubbingEnabled ? Colors.white70 : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Icon(
          isDubbingEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildVoiceSelectorChip(BuildContext context) {
    return GestureDetector(
      onTap: () {
        VoiceSelectorSheet.show(
          context: context,
          currentVoice: activeVoice,
          onVoiceSelected: onVoiceChanged,
        );
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(
              activeVoice.contains('Neural') ? Icons.record_voice_over : Icons.smart_toy_outlined,
              color: AppTheme.neonRed,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('OVOZ', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                  Text(
                    _formatVoiceLabel(activeVoice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedSelectorButton(BuildContext context) {
    return PopupMenuButton<double>(
      initialValue: playbackSpeed,
      color: const Color(0xFF18181D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderFrosted),
      ),
      onSelected: onSpeedChanged,
      itemBuilder: (context) => [
        _buildSpeedItem(1.0),
        _buildSpeedItem(1.25),
        _buildSpeedItem(1.5),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        alignment: Alignment.center,
        child: Text(
          '${playbackSpeed.toStringAsFixed(1)}x',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<double> _buildSpeedItem(double speed) {
    final isSelected = playbackSpeed == speed;
    return PopupMenuItem<double>(
      value: speed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${speed.toStringAsFixed(2)}x Tezlik',
            style: TextStyle(
              color: isSelected ? AppTheme.neonRed : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected) const Icon(Icons.check, color: AppTheme.neonRed, size: 18),
        ],
      ),
    );
  }
}
