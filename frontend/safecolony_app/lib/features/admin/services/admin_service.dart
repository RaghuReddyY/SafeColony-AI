import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/pending_resident.dart';

class AdminService {
  Future<List<PendingResident>> getPendingResidents() async {
    final response = await ApiClient.dio.get("/residents/pending");

    final List data = response.data;

    return data
        .map((e) => PendingResident.fromJson(e))
        .toList();
  }

  Future<void> updateResident({
    required int residentId,
    String? fullName,
    String? email,
    String? phone,
    String? residentType,
  }) async {
    await ApiClient.dio.put(
      "/residents/$residentId",
      data: {
        if (fullName != null) "full_name": fullName.trim(),
        if (email != null) "email": email.trim().toLowerCase(),
        if (phone != null) "phone": phone.trim(),
        if (residentType != null) "resident_type": residentType,
      },
    );
  }

  Future<void> approveResident(int residentId) async {
    await ApiClient.dio.post(
      "/residents/$residentId/approve",
    );
  }

  Future<void> rejectResident(int residentId) async {
    await ApiClient.dio.post(
      "/residents/$residentId/reject",
    );
  }
}