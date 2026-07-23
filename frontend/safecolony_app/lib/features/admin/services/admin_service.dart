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