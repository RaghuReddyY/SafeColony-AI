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