import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pronunciation_result.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class FeedbackModal extends StatefulWidget {
  final PronunciationResult result;
  final TtsService tts;
  final VoidCallback onRetry;
  final VoidCallback? onNext;

  const FeedbackModal({
    super.key,
    required this.result,
    required this.tts,
    required this.onRetry,
    this.onNext,
  });

  static Future<void> show(
    BuildContext context, {
    required PronunciationResult result,
    required TtsService tts,
    required VoidCallback onRetry,
    VoidCallback? onNext,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FeedbackModal(
        result: result,
        tts: tts,
        onRetry: onRetry,
        onNext: onNext,
      ),
    );
  }

  @override
  State<FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends State<FeedbackModal> {
  WordEvaluation? _selectedWord;

  Color _getStatusColor(WordStatus status) {
    switch (status) {
      case WordStatus.mastered:
        return AppTheme.success;
      case WordStatus.near:
        return AppTheme.warning;
      case WordStatus.needsWork:
        return AppTheme.danger;
    }
  }

  Color _getStatusBg(WordStatus status) {
    switch (status) {
      case WordStatus.mastered:
        return AppTheme.successContainer;
      case WordStatus.near:
        return AppTheme.warningContainer;
      case WordStatus.needsWork:
        return AppTheme.dangerContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Overall Score
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: result.overallScore >= 80
                      ? AppTheme.successContainer
                      : (result.overallScore >= 60 ? AppTheme.warningContainer : AppTheme.dangerContainer),
                ),
                child: Center(
                  child: Text(
                    '${result.overallScore.round()}%',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: result.overallScore >= 80
                          ? AppTheme.success
                          : (result.overallScore >= 60 ? AppTheme.warning : AppTheme.danger),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.overallScore >= 80
                          ? 'Excelente Pronúncia!'
                          : (result.overallScore >= 60 ? 'Bom Progresso!' : 'Continue Praticando!'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.feedbackSummary,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3 Metrics: Accuracy, Fluency, Completeness
          Row(
            children: [
              _buildMetricCard('Acurácia', result.accuracyScore),
              const SizedBox(width: 8),
              _buildMetricCard('Fluência', result.fluencyScore),
              const SizedBox(width: 8),
              _buildMetricCard('Completude', result.completenessScore),
            ],
          ),

          const SizedBox(height: 20),

          // Color-coded Interactive Words
          Text(
            'Toque nas palavras para ver fonemas e dicas:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.words.map((w) {
              final isSelected = _selectedWord?.word == w.word;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedWord = isSelected ? null : w;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusBg(w.status),
                    border: Border.all(
                      color: isSelected ? Colors.black87 : _getStatusColor(w.status),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        w.word,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _getStatusColor(w.status),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${w.score.round()}%',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: _getStatusColor(w.status),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Selected Word Details
          if (_selectedWord != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            _selectedWord!.word,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedWord!.ipa,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: AppTheme.primary),
                        tooltip: 'Ouvir palavra',
                        onPressed: () {
                          widget.tts.speak(_selectedWord!.word);
                        },
                      ),
                    ],
                  ),
                  if (_selectedWord!.tip != null && _selectedWord!.tip!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _selectedWord!.tip!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                  if (_selectedWord!.phonemes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: _selectedWord!.phonemes.map((ph) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            ph.phoneme,
                            style: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.w700,
                              color: _getStatusColor(ph.status),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onRetry();
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('Tentar Novamente'),
                ),
              ),
              if (widget.onNext != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onNext!();
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Próxima Frase'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, double value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${value.round()}%',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
