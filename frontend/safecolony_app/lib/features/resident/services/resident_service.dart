import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/resident_dropdown.dart';

class ResidentService {
  Future<List<ResidentDropdown>> getResidents() async {
    final Response response =
        await ApiClient.dio.get(
      "/residents/dropdown",
    );

    return (response.data as List)
        .map(
          (e) => ResidentDropdown.fromJson(e),
        )
        .toList();
  }
}