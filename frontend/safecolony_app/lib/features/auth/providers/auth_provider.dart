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



  Future<bool> login({
    required String email,
    required String password,
  }) async {

    try {

      state = state.copyWith(
        isLoading: true,
        error: null,
      );


      final loginResponse =
          await _authService.login(
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
      );


      print(
        "ROLE = ${user.role}",
      );

      print(
        "RESIDENT STATUS = ${loginResponse.residentStatus}",
      );


      return true;


    } catch(e) {


      state = state.copyWith(

        isLoading: false,

        error: e.toString(),

      );


      return false;
    }
  }



  Future<bool> register({
  required String organizationCode,
  required int sectionId,
  required String unitNumber,
  required String residentType,
  required String fullName,
  required String email,
  required String phone,
  required String password,
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
      ),
    );

    state = state.copyWith(
      isLoading: false,
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

Future<OrganizationRegisterResponse?> registerOrganization({
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

    final response = await _authService.registerOrganization(
      OrganizationRegisterRequest(
        organization: OrganizationInfo(
          name: organizationName,
          organizationType: organizationType,
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


  Future<void> checkLogin() async {


    final token =
        await _storage.getToken();



    if(token == null || token.isEmpty){

      state =
          const AuthState();

      return;

    }


    try{


      final user =
          await _authService.getCurrentUser();



      state = AuthState(

        isLoggedIn:true,

        token:token,

        user:user,

      );


    }
    catch(e){

      await logout();

    }

  }





  Future<void> logout() async {

    await _storage.logout();

    state =
        const AuthState();

  }

}