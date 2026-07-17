import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

class QRService {
  QRService._();

  static final Dio _dio = Dio();

  static String qrUrl(String relativePath) {
    return "${ApiConstants.baseUrl}/$relativePath";
  }

  static Future<Uint8List> downloadQR(String relativePath) async {
    final response = await _dio.get<List<int>>(
      qrUrl(relativePath),
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );

    return Uint8List.fromList(response.data!);
  }
}