import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../theme/phonetic_theme_extension.dart';

/// Card central de estímulo cognitivo e fonético.
/// Exibe a frase em inglês com palavras destacáveis, transcrição IPA,
/// guia fonético amigável em PT-BR e tradução contextual.
class PhoneticPromptCard extends StatelessWidget {
  final String sentence;
  final String phoneticIpa;
  final String friendlyPhonetic;
  final String translation;
  final bool showFriendlyPhonetic;
  final int? activeCharStart;
  final int? activeCharEnd;
  final VoidCallback onToggleFriendlyPhonetic;
  final Function(String word)? onWordTap;

  const PhoneticPromptCard({
    super.key,
    required this.sentence,
    required this.phoneticIpa,
    required this.friendlyPhonetic,
    required this.translation,
    required this.showFriendlyPhonetic,
    this.activeCharStart,
    this.activeCharEnd,
    required this.onToggleFriendlyPhonetic,
    this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    final phoneticTheme = Theme.of(context).extension<PhoneticThemeExtension>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Frase em Inglês (com palavras tocáveis e destaque dinâmico de áudio)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _buildWordChips(context),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // 2. Transcrição Fonética IPA (Tipografia com cobertura completa de glifos)
          if (phoneticIpa.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'IPA',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    phoneticIpa,
                    style: phoneticTheme?.ipaTextStyle ??
                        const TextStyle(
                          fontFamily: 'Noto Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                  ),
                ),
              ],
            ),

          // 3. Guia Fonético Amigável PT-BR (com toggle de exibição)
          if (friendlyPhonetic.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: onToggleFriendlyPhonetic,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          showFriendlyPhonetic
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 14,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Guia PT-BR',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (showFriendlyPhonetic)
                  Expanded(
                    child: Text(
                      '[$friendlyPhonetic]',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // 4. Tradução Contextual
          if (translation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              translation,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildWordChips(BuildContext context) {
    final words = sentence.split(' ');
    int charCursor = 0;

    return words.map((word) {
      final start = charCursor;
      final end = start + word.length;
      charCursor = end + 1; // +1 pelo espaço

      final isWordActive = activeCharStart != null &&
          activeCharEnd != null &&
          start >= activeCharStart! &&
          end <= activeCharEnd!;

      return GestureDetector(
        onTap: () => onWordTap?.call(word),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isWordActive ? const Color(0xFFE0E7FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isWordActive ? AppTheme.primary : Colors.transparent,
            ),
          ),
          child: Text(
            word,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isWordActive ? AppTheme.primary : const Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
        ),
      );
    }).toList();
  }
}
