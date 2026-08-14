import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../services/storage_service.dart';
import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  /// Converts Dio/backend failures into messages that are safe and understandable
  /// for residents and administrators. Raw DioException text is intentionally
  /// never shown in the UI.
  static String errorMessage(Object error) {
    if (error is ApiException) return error.message;

    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;

      String? serverMessage;
      if (data is Map) {
        final value = data['message'] ?? data['detail'] ?? data['error'];
        if (value is String && value.trim().isNotEmpty) {
          serverMessage = value.trim();
        } else if (value is List) {
          final messages = value
              .map((item) => item is Map && item['msg'] != null ? item['msg'].toString() : item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList();
          if (messages.isNotEmpty) serverMessage = messages.join(' ');
        }
      }

      if (serverMessage != null) return serverMessage;

      switch (status) {
        case 400:
          return 'The request could not be completed. Please check the details and try again.';
        case 401:
          return 'Your session has expired. Please log in again.';
        case 403:
          return 'You do not have permission to perform this action.';
        case 404:
          return 'The requested information was not found.';
        case 409:
          return 'This action conflicts with existing information. Please review and try again.';
        case 422:
          return 'Some information is invalid. Please check the fields and try again.';
        case 429:
          return 'Too many requests. Please wait a moment and try again.';
        case 500:
        case 502:
        case 503:
        case 504:
          return 'SafeColony is temporarily unavailable. Please try again shortly.';
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'The server is taking too long to respond. Please try again.';
        case DioExceptionType.connectionError:
          return 'Cannot connect to SafeColony. Check your internet connection and try again.';
        case DioExceptionType.badCertificate:
          return 'A secure connection to SafeColony could not be established.';
        case DioExceptionType.cancel:
          return 'The request was cancelled.';
        default:
          return 'Something went wrong while contacting SafeColony. Please try again.';
      }
    }

    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  static void logError(Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('SafeColony API error: ${errorMessage(error)}');
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }
  }

  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
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