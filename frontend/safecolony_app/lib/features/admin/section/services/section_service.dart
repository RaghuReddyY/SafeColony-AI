import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/section.dart';
import '../models/section_request.dart';

class SectionService {

  /// Get all sections
  Future<List<Section>> getSections() async {
    final Response response =
        await ApiClient.dio.get("/sections");

    return (response.data as List)
        .map((e) => Section.fromJson(e))
        .toList();
  }

  /// Get section
  Future<Section> getSection(
      int sectionId) async {

    final Response response =
        await ApiClient.dio.get(
      "/sections/$sectionId",
    );

    return Section.fromJson(response.data);
  }

  /// Get sections by property
  Future<List<Section>> getSectionsByProperty(
      int propertyId) async {

    final Response response =
        await ApiClient.dio.get(
      "/sections/property/$propertyId",
    );

    return (response.data as List)
        .map((e) => Section.fromJson(e))
        .toList();
  }

  /// Create section
  Future<Section> createSection(
      SectionRequest request) async {

    final Response response =
        await ApiClient.dio.post(
      "/sections",
      data: request.toJson(),
    );

    return Section.fromJson(response.data);
  }

  /// Update section
  Future<Section> updateSection(
      int sectionId,
      SectionRequest request) async {

    final Response response =
        await ApiClient.dio.put(
      "/sections/$sectionId",
      data: request.toJson(),
    );

    return Section.fromJson(response.data);
  }

  /// Delete section
  Future<void> deleteSection(
      int sectionId) async {

    await ApiClient.dio.delete(
      "/sections/$sectionId",
    );
  }
}

Future<Section> getSection(int sectionId) async {
  final response = await ApiClient.dio.get(
    '/sections/$sectionId',
  );

  return Section.fromJson(response.data);
}

Future<List<Section>> getSectionsByProperty(int propertyId) async {
  final response = await ApiClient.dio.get(
    '/sections/property/$propertyId',
  );

  return (response.data as List)
      .map((e) => Section.fromJson(e))
      .toList();
}