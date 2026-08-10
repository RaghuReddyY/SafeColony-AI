import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/property_dropdown.dart';

class PropertyService {

  Future<List<PropertyDropdown>> dropdown() async {

    final Response response =
        await ApiClient.dio.get(
      "/properties/dropdown",
    );

    return (response.data as List)
        .map((e) => PropertyDropdown.fromJson(e))
        .toList();
  }
}