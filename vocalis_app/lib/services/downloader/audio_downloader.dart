import 'audio_downloader_stub.dart'
    if (dart.library.html) 'audio_downloader_web.dart'
    if (dart.library.io) 'audio_downloader_io.dart';

class AudioDownloader {
  /// Salva ou baixa o arquivo de áudio gravado no dispositivo do usuário.
  /// No navegador Web, dispara o download automático pelo browser (ex: gravacao_vocalis.wav).
  /// No Android/iOS/Desktop, grava na pasta de Downloads / armazenamento acessível.
  /// Retorna o nome ou caminho do arquivo salvo, ou null em caso de falha.
  static Future<String?> download(List<int> bytes, {String? filename}) async {
    if (bytes.isEmpty) return null;
    final name = filename ?? 'vocalis_gravacao_${DateTime.now().millisecondsSinceEpoch}.wav';
    return downloadAudioBytes(bytes, name);
  }
}
