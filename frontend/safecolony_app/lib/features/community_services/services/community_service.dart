import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/community_service.dart';

class CommunityServicesApi {
  Future<List<CommunityServiceEntry>> list({String? category}) async {
    final response = await ApiClient.dio.get(
      '/community-services',
      queryParameters: category == null || category.trim().isEmpty
          ? null
          : {'category': category},
    );

    return (response.data as List)
        .map((item) => CommunityServiceEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CommunityServiceEntry> create({
    required String name,
    required String category,
    required String phone,
    required String workDescription,
    String? notes,
  }) async {
    final Response response = await ApiClient.dio.post(
      '/community-services',
      data: {
        'name': name,
        'category': category,
        'phone': phone,
        'work_description': workDescription,
        'notes': notes,
      },
    );
    return CommunityServiceEntry.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<CommunityServiceEntry> update(
    int id, {
    String? name,
    String? category,
    String? phone,
    String? workDescription,
    String? notes,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (category != null) data['category'] = category;
    if (phone != null) data['phone'] = phone;
    if (workDescription != null) data['work_description'] = workDescription;
    if (notes != null) data['notes'] = notes;
    if (isActive != null) data['is_active'] = isActive;

    final Response response = await ApiClient.dio.patch(
      '/community-services/$id',
      data: data,
    );
    return CommunityServiceEntry.fromJson(Map<String, dynamic>.from(response.data));
  }
}
