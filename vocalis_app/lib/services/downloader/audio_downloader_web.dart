// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<String?> downloadAudioBytes(List<int> bytes, String filename) async {
  try {
    final blob = html.Blob([bytes], 'audio/wav');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
    return filename;
  } catch (e) {
    return null;
  }
}
