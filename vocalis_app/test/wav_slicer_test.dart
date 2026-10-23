import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocalis_app/utils/wav_slicer.dart';
import 'package:vocalis_app/services/recording_service.dart';

void main() {
  group('WavSlicer Tests', () {
    Uint8List createDummyWav({required int durationSeconds, int sampleRate = 16000}) {
      final totalSamples = sampleRate * durationSeconds;
      final pcmBytesLength = totalSamples * 2; // 16-bit
      final totalFileLength = 44 + pcmBytesLength;

      final data = Uint8List(totalFileLength);
      final view = ByteData.sublistView(data);

      // 'RIFF'
      data[0] = 0x52; data[1] = 0x49; data[2] = 0x46; data[3] = 0x46;
      view.setUint32(4, 36 + pcmBytesLength, Endian.little);
      // 'WAVE'
      data[8] = 0x57; data[9] = 0x41; data[10] = 0x56; data[11] = 0x45;
      // 'fmt '
      data[12] = 0x66; data[13] = 0x6D; data[14] = 0x74; data[15] = 0x20;
      view.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
      view.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
      view.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
      view.setUint32(24, sampleRate, Endian.little);
      view.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
      view.setUint16(32, 2, Endian.little);  // BlockAlign
      view.setUint16(34, 16, Endian.little); // BitsPerSample
      // 'data'
      data[36] = 0x64; data[37] = 0x61; data[38] = 0x74; data[39] = 0x61;
      view.setUint32(40, pcmBytesLength, Endian.little);

      // Fill with dummy sine/ramp values (amplitude ~ 2000)
      for (int i = 0; i < totalSamples; i++) {
        view.setInt16(44 + i * 2, 2000, Endian.little);
      }

      return data;
    }

    test('Recorta fatia válida de áudio entre 200ms e 600ms', () {
      final wav = createDummyWav(durationSeconds: 2);
      final slice = WavSlicer.slicePcm16Wav(
        sourceWav: wav,
        startMs: 200,
        endMs: 600,
        sampleRate: 16000,
      );

      expect(slice, isNotNull);
      expect(slice!.length, greaterThan(44));

      // 400ms a 16kHz mono 16-bit = 0.4 * 16000 * 2 = 12800 bytes de payload + 44 header = 12844
      final payloadSize = ByteData.sublistView(slice).getUint32(40, Endian.little);
      expect(payloadSize, equals(12800));
      expect(slice.length, equals(12844));
    });

    test('Retorna null se endMs for menor ou igual a startMs', () {
      final wav = createDummyWav(durationSeconds: 1);
      final slice = WavSlicer.slicePcm16Wav(
        sourceWav: wav,
        startMs: 500,
        endMs: 400,
      );
      expect(slice, isNull);
    });

    test('Retorna null se áudio for muito curto para conter cabeçalho WAV', () {
      final slice = WavSlicer.slicePcm16Wav(
        sourceWav: Uint8List(20),
        startMs: 0,
        endMs: 200,
      );
      expect(slice, isNull);
    });
  });

  group('RecordingService.validateRecording Tests', () {
    test('Rejeita gravação nula ou vazia', () {
      expect(RecordingService.validateRecording(null), isNotNull);
      final empty = const RecordingResult(
        path: '',
        bytes: [],
        duration: Duration(seconds: 1),
      );
      expect(RecordingService.validateRecording(empty), contains('Nenhum áudio'));
    });

    test('Rejeita gravação com duração inferior a 450ms', () {
      final shortRec = const RecordingResult(
        path: 'test.wav',
        bytes: [1, 2, 3, 4],
        duration: Duration(milliseconds: 300),
      );
      expect(RecordingService.validateRecording(shortRec), contains('muito curto'));
    });
  });
}
