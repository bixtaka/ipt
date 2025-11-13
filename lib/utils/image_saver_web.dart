// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> savePng(Uint8List bytes, String filename, {String? mimeType}) async {
  final blob = html.Blob([bytes], mimeType ?? 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final a = html.AnchorElement(href: url)..download = filename;
  a.click();
  html.Url.revokeObjectUrl(url);
}

