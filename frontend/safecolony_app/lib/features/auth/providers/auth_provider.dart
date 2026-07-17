import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';
import '../../../models/login_request.dart';
import '../models/auth_state.dart';
import '../models/user.dart';


final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final loginResponse = await _authService.login(
        LoginRequest(
          email: email,
          password: password,
        ),
      );

      await _storage.saveToken(
        loginResponse.accessToken,
      );

      final user =
          await _authService.getCurrentUser();

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        token: loginResponse.accessToken,
        user: user,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return false;
    }
  }

  Future<void> checkLogin() async {
  final token = await _storage.getToken();

  print("========== CHECK LOGIN ==========");
  print("Stored Token: $token");

  if (token == null || token.isEmpty) {
    print("No token found.");

    state = const AuthState();
    return;
  }

  try {
    print("Calling /auth/me ...");

    final user = await _authService.getCurrentUser();

    print("User restored successfully.");
    print("User Email: ${user.email}");

    state = AuthState(
      isLoggedIn: true,
      token: token,
      user: user,
    );
  } catch (e, stackTrace) {
    print("========== CHECK LOGIN FAILED ==========");
    print(e);
    print(stackTrace);

    await logout();
  }
}

  Future<void> logout() async {
    await _storage.logout();

    state = const AuthState();
  }
}