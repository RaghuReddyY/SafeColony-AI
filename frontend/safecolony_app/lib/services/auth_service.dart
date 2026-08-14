import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../features/auth/models/user.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/organization_register_request.dart';
import '../models/organization_register_response.dart';

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

  Future<String?> requestOtp(String phone) async {
    final response = await ApiClient.dio.post(
      "/auth/otp/request",
      data: {"phone": phone.trim()},
    );
    return response.data["dev_otp"] as String?;
  }

  Future<LoginResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await ApiClient.dio.post(
      "/auth/otp/verify",
      data: {"phone": phone.trim(), "otp": otp.trim()},
    );
    return LoginResponse.fromJson(response.data);
  }

Future<OrganizationRegisterResponse> registerOrganization(
  OrganizationRegisterRequest request,
) async {
  final response = await ApiClient.dio.post(
    "/organizations/register",
    data: request.toJson(),
  );

  return OrganizationRegisterResponse.fromJson(
    response.data,
  );
}

Future<void> register(
  RegisterRequest request,
) async {
  try {
    print("REGISTER REQUEST:");
    print(request.toJson());

    final response = await ApiClient.dio.post(
      "/auth/register",
      data: request.toJson(),
    );

    print("REGISTER RESPONSE:");
    print(response.data);
  } on DioException catch (e) {
    print("STATUS CODE: ${e.response?.statusCode}");
    print("ERROR BODY: ${e.response?.data}");
    rethrow;
  }
}
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.dio.post(
      "/auth/change-password",
      data: {
        "current_password": currentPassword,
        "new_password": newPassword,
      },
    );
  }

  Future<User> getCurrentUser() async {
    final response = await ApiClient.dio.get(
      "/auth/me",
    );

    return User.fromJson(
      response.data,
    );
  }
}