import 'dart:convert';
import 'dart:typed_data';

class PlatformFileService {
  PlatformFileService._();

  static Future<String> saveFile(
    Uint8List bytes,
    String fileName,
  ) async {
    final base64Data = base64Encode(bytes);

    return "data:image/png;base64,$base64Data";
  }

  static Future<void> shareFile(
    Uint8List bytes,
    String fileName,
  ) async {
    // Web share will be added later.
  }
}