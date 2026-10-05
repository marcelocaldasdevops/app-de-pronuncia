import 'package:flutter_test/flutter_test.dart';
import 'package:vocalis_app/services/downloader/audio_downloader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioDownloader', () {
    test('retorna null se a lista de bytes for vazia', () async {
      final res = await AudioDownloader.download([]);
      expect(res, isNull);
    });

    test('salva arquivo com nome personalizado ou padrão quando há bytes', () async {
      final dummyBytes = [0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00];
      final res = await AudioDownloader.download(dummyBytes, filename: 'teste_audio.wav');
      // No ambiente de teste em Linux, grava em diretório temporário/downloads
      expect(res, isNotNull);
      expect(res, contains('teste_audio.wav'));
    });
  });
}
