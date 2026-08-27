import '../../../../core/api/api_client.dart';
import '../models/guard.dart';

class GuardService {

  Future<List<Guard>> getGuards() async {

    final response =
        await ApiClient.dio.get(
      "/organizations/guards",
    );

    final List list = response.data;

    return list
        .map((e) => Guard.fromJson(e))
        .toList();
  }

  Future<void> updateGuard({
    required int userId,
    required String fullName,
    required String email,
    required String phone,
    String? password,
  }) async {
    await ApiClient.dio.put(
      '/organizations/guards/$userId',
      data: {
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        if (password != null && password.isNotEmpty) 'password': password,
      },
    );
  }

  Future<void> createGuard({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {

    await ApiClient.dio.post(
      "/organizations/guards",
      data: {
        "full_name": fullName,
        "email": email,
        "phone": phone,
        "password": password,
      },
    );
  }
}