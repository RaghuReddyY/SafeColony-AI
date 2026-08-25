import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';

import '../../../models/login_request.dart';
import '../../../models/register_request.dart';
import '../../../models/organization_register_request.dart';
import '../../../models/organization_register_response.dart';

import '../models/auth_state.dart';

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();

  // ============================================================
  // EMAIL + PASSWORD LOGIN
  // ============================================================

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
          email: email.trim().toLowerCase(),
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
        residentStatus:
            loginResponse.residentStatus,
        error: null,
      );

      print('ROLE = ${user.role}');
      print(
        'RESIDENT STATUS = ${loginResponse.residentStatus}',
      );

      return true;
    } catch (e) {
      final errorMessage = e.toString();

      print(
        'SafeColony LOGIN ERROR = $errorMessage',
      );

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      return false;
    }
  }

  // ============================================================
  // RESEND EMAIL VERIFICATION
  // ============================================================

  Future<bool> resendEmailVerification(
    String email,
  ) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      await _authService.resendEmailVerification(
        email.trim().toLowerCase(),
      );

      state = state.copyWith(
        isLoading: false,
        error: null,
      );

      return true;
    } catch (e) {
      final errorMessage = e.toString();

      print(
        'SafeColony RESEND VERIFICATION ERROR = $errorMessage',
      );

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      return false;
    }
  }

  // ============================================================
  // MOBILE OTP LOGIN
  // ============================================================

  Future<String?> requestOtp(
    String phone,
  ) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final devOtp =
          await _authService.requestOtp(
        phone.trim(),
      );

      state = state.copyWith(
        isLoading: false,
        error: null,
      );

      return devOtp;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return null;
    }
  }

  Future<bool> loginWithOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final loginResponse =
          await _authService.verifyOtp(
        phone: phone.trim(),
        otp: otp.trim(),
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
        residentStatus:
            loginResponse.residentStatus,
        error: null,
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

  // ============================================================
  // RESIDENT REGISTRATION
  // ============================================================

  Future<bool> register({
    required String organizationCode,
    int? sectionId,
    required String unitNumber,
    required String residentType,
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? familyJoinCode,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      await _authService.register(
        RegisterRequest(
          organizationCode: organizationCode,
          sectionId: sectionId,
          unitNumber: unitNumber.trim(),
          residentType: residentType,
          fullName: fullName.trim(),
          email: email.trim().toLowerCase(),
          phone: phone.trim(),
          password: password,
          familyJoinCode: familyJoinCode,
        ),
      );

      state = state.copyWith(
        isLoading: false,
        error: null,
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

  // ============================================================
  // ORGANIZATION REGISTRATION
  // ============================================================

  Future<OrganizationRegisterResponse?>
      registerOrganization({
    required String organizationName,
    required String organizationType,
    required String organizationEmail,
    required String organizationPhone,
    required String address,
    required String city,
    required String stateName,
    required String country,
    required String pincode,
    required String adminName,
    required String adminEmail,
    required String adminPhone,
    required String password,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final response =
          await _authService.registerOrganization(
        OrganizationRegisterRequest(
          organization: OrganizationInfo(
            name: organizationName,
            organizationType:
                organizationType,
            email: organizationEmail,
            phone: organizationPhone,
            address: address,
            city: city,
            state: stateName,
            country: country,
            pincode: pincode,
          ),
          admin: AdminInfo(
            fullName: adminName,
            email: adminEmail,
            phone: adminPhone,
            password: password,
          ),
        ),
      );

      state = state.copyWith(
        isLoading: false,
        error: null,
      );

      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return null;
    }
  }

  // ============================================================
  // CHECK EXISTING LOGIN
  // ============================================================

  Future<void> checkLogin() async {
    final token = await _storage.getToken();

    if (token == null || token.isEmpty) {
      state = const AuthState();
      return;
    }

    try {
      final user =
          await _authService.getCurrentUser();

      state = AuthState(
        isLoggedIn: true,
        token: token,
        user: user,
      );
    } catch (e) {
      await logout();
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _storage.logout();

    state = const AuthState();
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<String?> forgotPassword(
    String email,
  ) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final devToken =
          await _authService.forgotPassword(
        email.trim().toLowerCase(),
      );

      state = state.copyWith(
        isLoading: false,
        error: null,
      );

      return devToken;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return null;
    }
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      await _authService.resetPassword(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        newPassword: newPassword,
      );

      state = state.copyWith(
        isLoading: false,
        error: null,
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
}