import 'package:dio/dio.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://127.0.0.1:8000",

      connectTimeout: const Duration(seconds: 20),

      receiveTimeout: const Duration(seconds: 20),

      headers: {
        "Accept": "application/json",
      },
    ),
  );
}