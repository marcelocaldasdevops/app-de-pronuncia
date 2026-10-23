import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pronunciation_result.dart';
import '../services/audio_player_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../theme/phonetic_theme_extension.dart';
import '../utils/wav_slicer.dart';

class FeedbackModal extends StatefulWidget {
  final PronunciationResult result;
  final TtsService tts;
  final List<int>? recordedAudioBytes;
  final VoidCallback onRetry;
  final VoidCallback? onNext;

  const FeedbackModal({
    super.key,
    required this.result,
    required this.tts,
    this.recordedAudioBytes,
    required this.onRetry,
    this.onNext,
  });

  static Future<void> show(
    BuildContext context, {
    required PronunciationResult result,
    required TtsService tts,
    List<int>? recordedAudioBytes,
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
        recordedAudioBytes: recordedAudioBytes,
        onRetry: onRetry,
        onNext: onNext,
      ),
    );
  }

  @override
  State<FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends State<FeedbackModal> {
  final _audioPlayer = AudioPlayerService();
  WordEvaluation? _selectedWord;
  bool _isPlayingComparison = false;

  @override
  void initState() {
    super.initState();
    // Auto-seleciona a palavra com menor pontuação para feedback imediato
    if (widget.result.words.isNotEmpty) {
      final weakWord = widget.result.words.firstWhere(
        (w) => w.status == WordStatus.needsWork,
        orElse: () => widget.result.words.firstWhere(
          (w) => w.status == WordStatus.near,
          orElse: () => widget.result.words.first,
        ),
      );
      _selectedWord = weakWord;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Color _getStatusColor(WordStatus status, PhoneticThemeExtension? ext) {
    if (ext != null) {
      switch (status) {
        case WordStatus.mastered:
          return ext.masteredColor;
        case WordStatus.near:
          return ext.nearColor;
        case WordStatus.needsWork:
          return ext.needsWorkColor;
      }
    }
    switch (status) {
      case WordStatus.mastered:
        return AppTheme.success;
      case WordStatus.near:
        return AppTheme.warning;
      case WordStatus.needsWork:
        return AppTheme.danger;
    }
  }

  Color _getStatusBg(WordStatus status, PhoneticThemeExtension? ext) {
    if (ext != null) {
      switch (status) {
        case WordStatus.mastered:
          return ext.masteredBg;
        case WordStatus.near:
          return ext.nearBg;
        case WordStatus.needsWork:
          return ext.needsWorkBg;
      }
    }
    switch (status) {
      case WordStatus.mastered:
        return AppTheme.successContainer;
      case WordStatus.near:
        return AppTheme.warningContainer;
      case WordStatus.needsWork:
        return AppTheme.dangerContainer;
    }
  }

  Future<void> _playComparison() async {
    final word = _selectedWord;
    final recorded = widget.recordedAudioBytes;
    if (word == null || recorded == null || recorded.isEmpty) {
      // Se não houver bytes gravados, reproduz apenas a referência
      if (word != null) widget.tts.speak(word.word);
      return;
    }

    setState(() => _isPlayingComparison = true);

    try {
      // 1. Tenta recortar a palavra exata usando timestamps se fornecidos pelo alinhador
      Uint8List? userAudioSlice;
      if (word.startMs != null && word.endMs != null && word.endMs! > word.startMs!) {
        userAudioSlice = WavSlicer.slicePcm16Wav(
          sourceWav: Uint8List.fromList(recorded),
          startMs: word.startMs!,
          endMs: word.endMs!,
        );
      }

      // Toca a voz do usuário (recortada ou completa como fallback)
      if (userAudioSlice != null) {
        await _audioPlayer.playBytes(userAudioSlice, mimeType: 'audio/wav');
      } else {
        await _audioPlayer.playBytes(recorded, mimeType: 'audio/wav');
      }

      // Pequena pausa natural de 350ms entre a voz do usuário e a do nativo
      await Future.delayed(const Duration(milliseconds: 350));

      // 2. Toca a referência nativa correta
      await widget.tts.speak(word.word);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isPlayingComparison = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final phoneticTheme = Theme.of(context).extension<PhoneticThemeExtension>();

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
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 14),

            // Banner informativo de Fallback ou Modo de Compatibilidade
            if (result.isFallback || result.feedbackSummary.contains('modo de compatibilidade'))
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.isFallback
                            ? 'Modo Offline: Avaliação estimada localmente por texto.'
                            : 'Modo de Compatibilidade: Servidor em fallback sem inferência acústica completa.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Header com Pontuação Geral
            Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: result.overallScore >= 85
                        ? _getStatusBg(WordStatus.mastered, phoneticTheme)
                        : (result.overallScore >= 65
                            ? _getStatusBg(WordStatus.near, phoneticTheme)
                            : _getStatusBg(WordStatus.needsWork, phoneticTheme)),
                  ),
                  child: Center(
                    child: Text(
                      '${result.overallScore.round()}%',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: result.overallScore >= 85
                            ? _getStatusColor(WordStatus.mastered, phoneticTheme)
                            : (result.overallScore >= 65
                                ? _getStatusColor(WordStatus.near, phoneticTheme)
                                : _getStatusColor(WordStatus.needsWork, phoneticTheme)),
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
                        (result.isFallback || result.feedbackSummary.contains('modo de compatibilidade'))
                            ? (result.overallScore >= 75 ? 'Avaliação em Compatibilidade' : 'Pronúncia Divergente')
                            : (result.overallScore >= 85
                                ? 'Excelente Pronúncia!'
                                : (result.overallScore >= 70
                                    ? 'Boa Pronúncia!'
                                    : (result.overallScore >= 50 ? 'Em Evolução!' : 'Continue Praticando!'))),
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
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Métricas Detalhadas (Acurácia, Fluência, Completude)
            Row(
              children: [
                _buildMetricCard('Acurácia', result.accuracyScore),
                const SizedBox(width: 8),
                _buildMetricCard('Fluência', result.fluencyScore),
                const SizedBox(width: 8),
                _buildMetricCard('Completude', result.completenessScore),
              ],
            ),

            const SizedBox(height: 16),

            // Mapa Interativo de Palavras da Frase
            Text(
              'Toque em uma palavra para analisar:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.words.map((w) {
                final isSelected = _selectedWord?.word == w.word;
                final statusColor = _getStatusColor(w.status, phoneticTheme);
                final statusBg = _getStatusBg(w.status, phoneticTheme);

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedWord = w);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0F172A) : statusColor,
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
                            fontSize: 14,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${w.score.round()}%',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // Detalhes da Palavra Selecionada (com Biomecânica e Comparador A/B)
            if (_selectedWord != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedWord!.ipa,
                              style: phoneticTheme?.ipaTextStyle ??
                                  GoogleFonts.jetBrainsMono(
                                    fontSize: 14,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),

                        // Ações de Reprodução (Nativo e Comparativo A/B)
                        Row(
                          children: [
                            if (widget.recordedAudioBytes != null)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _isPlayingComparison ? null : _playComparison,
                                icon: _isPlayingComparison
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.compare_arrows_rounded, size: 16),
                                label: Text(
                                  'Comparar',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded, color: AppTheme.primary),
                              tooltip: 'Ouvir referência',
                              onPressed: () {
                                widget.tts.speak(_selectedWord!.word);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (_selectedWord!.tip != null && _selectedWord!.tip!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _selectedWord!.tip!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF475569),
                          height: 1.3,
                        ),
                      ),
                    ],

                    // Decomposição dos Fonemas Individuais
                    if (_selectedWord!.phonemes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _selectedWord!.phonemes.map((ph) {
                          final phColor = _getStatusColor(ph.status, phoneticTheme);
                          final hasConfusion = ph.actualPhoneme != null &&
                              ph.actualPhoneme!.isNotEmpty &&
                              ph.actualPhoneme != ph.phoneme;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusBg(ph.status, phoneticTheme),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hasConfusion
                                      ? '/${ph.phoneme}/ → /${ph.actualPhoneme}/'
                                      : '/${ph.phoneme}/',
                                  style: phoneticTheme?.ipaTextStyle.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: phColor,
                                      ) ??
                                      GoogleFonts.jetBrainsMono(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: phColor,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${ph.score.round()}%',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: phColor,
                                  ),
                                ),
                              ],
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

            // Ações Finais
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onRetry();
                    },
                    icon: const Icon(Icons.replay_rounded),
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
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Próxima Frase'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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
