import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Deck ergonômico de áudio fixado na Thumb Zone (zona inferior do polegar).
/// Agrupa o controle de velocidade, o gatilho central de gravação (72x72) e o player nativo.
class UnifiedAudioDeck extends StatelessWidget {
  final bool isRecording;
  final bool isPlayingReference;
  final bool isAssessing;
  final double playbackRate;
  final VoidCallback onToggleRecording;
  final VoidCallback onToggleReference;
  final VoidCallback onToggleSpeed;

  const UnifiedAudioDeck({
    super.key,
    required this.isRecording,
    required this.isPlayingReference,
    required this.isAssessing,
    required this.playbackRate,
    required this.onToggleRecording,
    required this.onToggleReference,
    required this.onToggleSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Botão 1: Velocidade de Reprodução (0.75x / 1.0x)
            InkWell(
              onTap: isRecording || isAssessing ? null : onToggleSpeed,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: playbackRate < 0.9 ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: playbackRate < 0.9 ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      playbackRate < 0.9 ? '🐢' : '⚡',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${playbackRate.toStringAsFixed(playbackRate == 1.0 ? 0 : 2)}x',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: playbackRate < 0.9 ? const Color(0xFF92400E) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botão 2: Gatilho Primário de Microfone (72x72)
            GestureDetector(
              onTap: isAssessing
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      onToggleRecording();
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording
                      ? AppTheme.danger
                      : (isAssessing ? const Color(0xFF0F172A) : AppTheme.primary),
                  boxShadow: [
                    BoxShadow(
                      color: isRecording
                          ? AppTheme.danger.withValues(alpha: 0.40)
                          : AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: isRecording ? 24 : 16,
                      spreadRadius: isRecording ? 4 : 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: isAssessing
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                ),
              ),
            ),

            // Botão 3: Ouvir Áudio Nativo de Referência
            InkWell(
              onTap: isRecording || isAssessing ? null : onToggleReference,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isPlayingReference ? AppTheme.primaryContainer : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPlayingReference ? AppTheme.primary : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Center(
                  child: Icon(
                    isPlayingReference ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                    color: isPlayingReference ? AppTheme.primary : const Color(0xFF334155),
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
