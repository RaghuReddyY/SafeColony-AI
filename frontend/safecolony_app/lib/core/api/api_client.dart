import 'package:dio/dio.dart';

import '../../services/storage_service.dart';

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

  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;

    _initialized = true;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (
          options,
          handler,
        ) async {
          final token =
              await StorageService().getToken();

          if (token != null &&
              token.isNotEmpty) {
            options.headers["Authorization"] =
                "Bearer $token";
          }

          handler.next(options);
        },

        onError: (
          error,
          handler,
        ) {
          if (error.response?.statusCode ==
              401) {
            // Later:
            // Refresh token / Logout automatically
          }

          handler.next(error);
        },
      ),
    );
  }
}