import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/property.dart';
import '../models/property_request.dart';

class PropertyService {

  /// Get all properties
  Future<List<Property>> getProperties() async {
    final Response response =
        await ApiClient.dio.get("/properties");

    return (response.data as List)
        .map((e) => Property.fromJson(e))
        .toList();
  }

  /// Get property
  Future<Property> getProperty(
      int propertyId) async {

    final Response response =
        await ApiClient.dio.get(
      "/properties/$propertyId",
    );

    return Property.fromJson(response.data);
  }

  /// Create property
  Future<Property> createProperty(
      PropertyRequest request) async {

    final Response response =
        await ApiClient.dio.post(
      "/properties",
      data: request.toJson(),
    );

    return Property.fromJson(response.data);
  }

  /// Update property
  Future<Property> updateProperty(
      int propertyId,
      PropertyRequest request) async {

    final Response response =
        await ApiClient.dio.put(
      "/properties/$propertyId",
      data: request.toJson(),
    );

    return Property.fromJson(response.data);
  }

  /// Delete property
  Future<void> deleteProperty(
      int propertyId) async {

    await ApiClient.dio.delete(
      "/properties/$propertyId",
    );
  }
}