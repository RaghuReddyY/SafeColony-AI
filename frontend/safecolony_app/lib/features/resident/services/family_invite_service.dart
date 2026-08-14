import '../../../core/api/api_client.dart';

class FamilyInviteService {
  Future<Map<String, dynamic>> getInvite() async {
    final response = await ApiClient.dio.get('/residents/me/family-invite');
    return Map<String, dynamic>.from(response.data);
  }
}
