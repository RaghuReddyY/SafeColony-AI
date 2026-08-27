import '../../../core/api/api_client.dart';

class BlockAdminService {
  Future<List<Map<String, dynamic>>> getBlocks() async {
    final r = await ApiClient.dio.get('/organizations/blocks');
    return List<Map<String, dynamic>>.from(r.data);
  }

  Future<List<Map<String, dynamic>>> getAdmins() async {
    final r = await ApiClient.dio.get('/organizations/scoped-admins');
    return List<Map<String, dynamic>>.from(r.data);
  }


  Future<void> updateAdmin({
    required int userId,
    required String fullName,
    required String email,
    required String phone,
    required List<int> sectionIds,
    String? password,
  }) async {
    await ApiClient.dio.put('/organizations/scoped-admins/$userId', data: {
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'section_ids': sectionIds,
      if (password != null && password.isNotEmpty) 'password': password,
    });
  }

  Future<void> createBlockAdmin({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required List<int> sectionIds,
  }) async {
    await ApiClient.dio.post('/organizations/block-admins', data: {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'section_ids': sectionIds,
    });
  }

  Future<void> createFinanceAdmin({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await ApiClient.dio.post('/organizations/finance-admins', data: {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
    });
  }
}
