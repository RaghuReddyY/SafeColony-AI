import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthService {
  Future<LoginResponse> login(
    LoginRequest request,
  ) async {
    final response = await ApiClient.dio.post(
      "/auth/login",
      data: {
        "username": request.email,
        "password": request.password,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    return LoginResponse.fromJson(
      response.data,
    );
  }
}