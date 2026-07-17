import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PlatformFileService {
  PlatformFileService._();

  static Future<String> saveFile(
    Uint8List bytes,
    String fileName,
  ) async {
    final dir = await getTemporaryDirectory();

    final file = File("${dir.path}/$fileName");

    await file.writeAsBytes(bytes);

    return file.path;
  }

  static Future<void> shareFile(
    Uint8List bytes,
    String fileName,
  ) async {
    final path = await saveFile(bytes, fileName);

    await Share.shareXFiles(
      [XFile(path)],
      text: "Visitor QR Code",
    );
  }
}