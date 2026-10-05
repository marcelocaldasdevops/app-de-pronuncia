import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String?> downloadAudioBytes(List<int> bytes, String filename) async {
  try {
    Directory? targetDir;

    if (Platform.isAndroid) {
      // Tenta salvar na pasta Downloads pública padrão do Android
      final publicDownloads = Directory('/storage/emulated/0/Download');
      if (publicDownloads.existsSync()) {
        targetDir = publicDownloads;
      } else {
        try {
          targetDir = await getExternalStorageDirectory();
        } catch (_) {}
      }
    } else if (Platform.isIOS) {
      try {
        targetDir = await getApplicationDocumentsDirectory();
      } catch (_) {}
    } else {
      // Linux, macOS, Windows
      try {
        targetDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      } catch (_) {}
    }

    targetDir ??= Directory.systemTemp;

    final file = File('${targetDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  } catch (e) {
    return null;
  }
}
