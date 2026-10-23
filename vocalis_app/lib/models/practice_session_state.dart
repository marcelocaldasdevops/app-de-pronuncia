import 'dart:typed_data';
import 'pronunciation_result.dart';

/// Máquina de estados finita da sessão de treino fonético.
/// Garante transições determinísticas entre reprodução de referência,
/// gravação de voz e inspeção de diagnóstico acústico.
sealed class PracticeAudioState {
  const PracticeAudioState();
}

/// Estado ocioso: Frase carregada, pronta para treino.
class PracticeIdle extends PracticeAudioState {
  const PracticeIdle();
}

/// Reproduzindo áudio de referência nativo (TTS neural ou local).
class PracticePlayingReference extends PracticeAudioState {
  final double playbackRate; // 0.75, 1.0, 1.25
  final String? isolatedWord;
  const PracticePlayingReference({this.playbackRate = 1.0, this.isolatedWord});
}

/// Gravando voz do usuário com foco exclusivo no microfone (WAV 16kHz).
class PracticeRecording extends PracticeAudioState {
  final Duration elapsed;
  final double normalizedAmplitude; // 0.0 a 1.0
  final bool isTooQuiet;
  const PracticeRecording({
    required this.elapsed,
    required this.normalizedAmplitude,
    this.isTooQuiet = false,
  });
}

/// Processamento e alinhamento acústico via backend FastAPI / Wav2Vec2.
class PracticeEvaluating extends PracticeAudioState {
  final Uint8List recordedWavBytes;
  const PracticeEvaluating(this.recordedWavBytes);
}

/// Diagnóstico acústico pronto com inspeção interativa por palavra e fonema.
class PracticeFeedbackReady extends PracticeAudioState {
  final PronunciationResult result;
  final Uint8List? recordedWavBytes;
  final int selectedWordIndex;

  const PracticeFeedbackReady({
    required this.result,
    this.recordedWavBytes,
    required this.selectedWordIndex,
  });
}
