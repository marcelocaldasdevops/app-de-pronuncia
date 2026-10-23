import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsProgress {
  final String text;
  final int start;
  final int end;
  final String word;

  const TtsProgress({
    required this.text,
    required this.start,
    required this.end,
    required this.word,
  });
}

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  String _currentLanguage = 'en-US';

  // Taxas normalizadas por plataforma:
  // No Web a Web Speech API tem 1.0 como normal; valores abaixo de 0.6 distorcem o áudio.
  // No Android/iOS o flutter_tts usa 0.5 como velocidade normal.
  double get _normalRate => kIsWeb ? 0.90 : 0.48;
  double get _slowRate => kIsWeb ? 0.72 : 0.35;

  bool get isPlaying => _isPlaying;
  String get currentLanguage => _currentLanguage;

  final _completionController = StreamController<void>.broadcast();
  Stream<void> get onComplete => _completionController.stream;

  final _progressController = StreamController<TtsProgress>.broadcast();
  Stream<TtsProgress> get onProgress => _progressController.stream;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage(_currentLanguage);
      await _flutterTts.setSpeechRate(_normalRate);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      if (kIsWeb) {
        await _configureWebVoice();
      }
    } catch (_) {
      // TTS indisponível nesta plataforma; chamadas falharão silenciosamente.
      return;
    }

    _flutterTts.setStartHandler(() {
      _isPlaying = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      _completionController.add(null);
    });

    _flutterTts.setCancelHandler(() {
      _isPlaying = false;
      _completionController.add(null);
    });

    _flutterTts.setErrorHandler((dynamic message) {
      _isPlaying = false;
      _completionController.add(null);
    });

    _flutterTts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      _progressController.add(
        TtsProgress(
          text: text,
          start: startOffset,
          end: endOffset,
          word: word,
        ),
      );
    });
  }

  Future<void> _configureWebVoice({String? targetLang}) async {
    try {
      final desired = (targetLang ?? _currentLanguage).toLowerCase();
      final targetLangPrefix = desired.split('-').first;

      dynamic rawVoices = await _flutterTts.getVoices;
      // No navegador, getVoices é assíncrono e frequentemente vazio na carga inicial
      if (rawVoices is! List || rawVoices.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 250));
        rawVoices = await _flutterTts.getVoices;
      }

      if (rawVoices is List && rawVoices.isNotEmpty) {
        final voices = rawVoices.cast<Map>();

        final preferred = voices.firstWhere(
          (v) {
            final name = (v['name'] ?? '').toString();
            final locale = (v['locale'] ?? '').toString().toLowerCase();
            final isTargetPrefix = locale.startsWith(targetLangPrefix);
            final isEnglishName = name.toLowerCase().contains('english') ||
                name.toLowerCase().contains('united states') ||
                name.toLowerCase().contains('us') ||
                name.toLowerCase().contains('uk');

            if (!isTargetPrefix && !isEnglishName) return false;

            return name.contains('Natural') ||
                name.contains('Google') ||
                name.contains('Samantha') ||
                name.contains('Daniel') ||
                name.contains('Jenny') ||
                name.contains('Guy') ||
                name.contains('Alex') ||
                name.contains('Victoria') ||
                name.contains('Fred');
          },
          orElse: () => voices.firstWhere(
            (v) {
              final name = (v['name'] ?? '').toString();
              final locale = (v['locale'] ?? '').toString().toLowerCase();
              return locale.startsWith(targetLangPrefix) || name.toLowerCase().contains('english');
            },
            orElse: () => const {},
          ),
        );

        if (preferred.isNotEmpty && preferred['name'] != null && preferred['locale'] != null) {
          final voiceLocale = preferred['locale'].toString();
          await _flutterTts.setVoice({
            'name': preferred['name'].toString(),
            'locale': voiceLocale,
          });
          await _flutterTts.setLanguage(voiceLocale);
        }
      }
    } catch (_) {}
  }

  Future<void> setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> setLanguage(String lang) async {
    _currentLanguage = lang;
    try {
      await _flutterTts.setLanguage(lang);
      if (kIsWeb) {
        await _configureWebVoice(targetLang: lang);
      }
    } catch (_) {}
  }

  Future<void> speak(String text, {bool slow = false, String? lang}) async {
    try {
      await stop();
      final desiredLang = lang ?? _currentLanguage;
      if (desiredLang != _currentLanguage) {
        await setLanguage(desiredLang);
      } else if (kIsWeb) {
        await _configureWebVoice(targetLang: desiredLang);
      }
      final targetRate = slow ? _slowRate : _normalRate;
      await _flutterTts.setSpeechRate(targetRate);
      _isPlaying = true;
      await _flutterTts.speak(text);
    } catch (_) {
      _isPlaying = false;
    }
  }

  Future<void> stop() async {
    if (_isPlaying) {
      try {
        await _flutterTts.stop();
      } catch (_) {}
      _isPlaying = false;
    }
  }

  void dispose() {
    _completionController.close();
    _progressController.close();
    _flutterTts.stop();
  }
}
