import 'package:speech_to_text/speech_to_text.dart';

/// Live speech recognition used to build the transcript that feeds the
/// offline pronunciation scorer while the user is recording.
class LiveTranscriptService {
  final SpeechToText _stt = SpeechToText();
  String _transcript = '';
  bool _listening = false;

  String get transcript => _transcript;

  Future<bool> start({void Function(String transcript)? onResult}) async {
    if (_listening) return true;
    try {
      final available = await _stt.initialize();
      if (!available) return false;

      _transcript = '';
      _listening = true;
      await _stt.listen(
        listenOptions: SpeechListenOptions(localeId: 'en_US'),
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _transcript = result.recognizedWords;
            onResult?.call(_transcript);
          }
        },
      );
      return true;
    } catch (_) {
      _listening = false;
      return false;
    }
  }

  Future<String> stop() async {
    if (_listening) {
      try {
        await _stt.stop();
      } catch (_) {}
      _listening = false;
    }
    return _transcript;
  }

  Future<void> cancel() async {
    if (_listening) {
      try {
        await _stt.cancel();
      } catch (_) {}
      _listening = false;
    }
    _transcript = '';
  }

  Future<void> dispose() async {
    try {
      await _stt.cancel();
    } catch (_) {}
    _listening = false;
  }
}
