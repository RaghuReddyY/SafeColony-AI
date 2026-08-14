import '../../../core/api/api_client.dart';

class OrganizationUserService {
  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await ApiClient.dio.get('/organizations/users');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    List<int> sectionIds = const [],
  }) async {
    await ApiClient.dio.post(
      '/organizations/users',
      data: {
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
        'role': role,
        'section_ids': sectionIds,
      },
    );
  }

  Future<void> deleteUser(int userId) async {
    await ApiClient.dio.delete('/organizations/users/$userId');
  }

  Future<void> restoreUser(int userId) async {
    await ApiClient.dio.post('/organizations/users/$userId/restore');
  }
}
