import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/login_request.dart';
import '../../../models/login_response.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';

final authProvider =
    Provider<AuthProvider>((ref) {
  return AuthProvider();
});

class AuthProvider {
  final AuthService _service =
      AuthService();

  final StorageService _storage =
      StorageService();

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _service.login(
      LoginRequest(
        email: email,
        password: password,
      ),
    );

    await _storage.saveToken(
      response.accessToken,
    );

    return response;
  }

  Future<void> logout() async {
    await _storage.logout();
  }

  Future<String?> getToken() async {
    return await _storage.getToken();
  }
}