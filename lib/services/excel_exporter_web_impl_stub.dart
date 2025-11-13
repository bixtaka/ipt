// Stub implementation for non-web or when HTML library is unavailable.
import 'dart:typed_data';

Future<void> downloadBytesForWeb(
  Uint8List bytes,
  String filename, {
  String mimeType = 'application/octet-stream',
}) async {
  throw UnsupportedError('downloadBytesForWeb is not available on this platform');
}

