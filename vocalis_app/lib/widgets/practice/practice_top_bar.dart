import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Barra superior de navegação da sessão de treino.
/// Exibe o progresso no catálogo, seletor de sotaque (US/UK) e ação de fechar.
class PracticeTopBar extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final String accent; // 'US' ou 'UK'
  final bool isCustomMode;
  final VoidCallback onClose;
  final Function(String newAccent) onAccentChanged;

  const PracticeTopBar({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.accent,
    required this.isCustomMode,
    required this.onClose,
    required this.onAccentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? (currentIndex + 1) / totalCount : 0.0;

    return Row(
      children: [
        // Botão Fechar / Voltar
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF334155),
          tooltip: 'Voltar ao painel',
        ),

        // Barra Central de Progresso
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isCustomMode ? 'Frase Própria' : 'Treino Guiado',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  if (!isCustomMode)
                    Text(
                      '${currentIndex + 1} de $totalCount',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: isCustomMode ? 1.0 : progress,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 14),

        // Seletor de Sotaque (US / UK)
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAccentChip('US', '🇺🇸'),
              _buildAccentChip('UK', '🇬🇧'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccentChip(String code, String flag) {
    final isSelected = accent == code;
    return GestureDetector(
      onTap: () => onAccentChanged(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              code,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppTheme.primary : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
