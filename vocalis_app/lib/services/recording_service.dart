import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordingResult {
  final String path;
  final List<int> bytes;
  final Duration duration;

  const RecordingResult({
    required this.path,
    required this.bytes,
    required this.duration,
  });
}

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _startedAt;

  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (_) {
      return false;
    }
  }

  Future<bool> start() async {
    try {
      if (!await _recorder.hasPermission()) return false;

      var path = '';
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/vocalis_${DateTime.now().millisecondsSinceEpoch}.wav';
      }

      // No Web, 44.100 Hz previne buffer underrun e distorções no AudioWorklet.
      // No nativo (mobile), 16.000 Hz envia na frequência padrão do modelo acústico.
      final targetSampleRate = kIsWeb ? 44100 : 16000;

      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: targetSampleRate,
          numChannels: 1,
          noiseSuppress: true,
          echoCancel: true,
          autoGain: true,
        ),
        path: path,
      );
      _startedAt = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('RecordingService.start failed: $e');
      return false;
    }
  }

  Future<RecordingResult?> stop() async {
    final startedAt = _startedAt;
    _startedAt = null;
    try {
      final path = await _recorder.stop();
      if (path == null || path.isEmpty) return null;

      final bytes = await _readBytes(path);
      if (bytes.isEmpty) return null;

      return RecordingResult(
        path: path,
        bytes: bytes,
        duration: startedAt != null
            ? DateTime.now().difference(startedAt)
            : Duration.zero,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> cancel() async {
    _startedAt = null;
    try {
      await _recorder.cancel();
    } catch (_) {}
  }

  Future<List<int>> _readBytes(String path) async {
    if (kIsWeb) {
      // No web o recorder retorna uma URL Blob (blob:http://...).
      try {
        final res = await http.get(Uri.parse(path)).timeout(
              const Duration(seconds: 5),
            );
        return res.bodyBytes;
      } catch (_) {
        return [];
      }
    }
    return File(path).readAsBytes();
  }

  Future<void> dispose() async {
    try {
      await _recorder.dispose();
    } catch (_) {}
  }
}
