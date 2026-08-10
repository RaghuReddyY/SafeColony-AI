import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

import '../models/guard_property.dart';
import '../models/guard_section.dart';
import '../models/guard_unit.dart';
import '../models/guard_resident.dart';

class GuardLookupService {
  // --------------------------------------------------------
  // Properties
  // --------------------------------------------------------

  Future<List<GuardProperty>> getProperties() async {
    final Response response = await ApiClient.dio.get(
      "/guard/properties",
    );

    return (response.data as List)
        .map(
          (e) => GuardProperty.fromJson(e),
        )
        .toList();
  }

  // --------------------------------------------------------
  // Sections
  // --------------------------------------------------------

  Future<List<GuardSection>> getSections(
    int propertyId,
  ) async {
    final Response response = await ApiClient.dio.get(
      "/guard/sections/$propertyId",
    );

    return (response.data as List)
        .map(
          (e) => GuardSection.fromJson(e),
        )
        .toList();
  }

  // --------------------------------------------------------
  // Units
  // --------------------------------------------------------

  Future<List<GuardUnit>> getUnits(
    int sectionId,
  ) async {
    final Response response = await ApiClient.dio.get(
      "/guard/units/$sectionId",
    );

    return (response.data as List)
        .map(
          (e) => GuardUnit.fromJson(e),
        )
        .toList();
  }

  // --------------------------------------------------------
  // Residents
  // --------------------------------------------------------

  Future<List<GuardResident>> getResidents(
    int unitId,
  ) async {
    final Response response = await ApiClient.dio.get(
      "/guard/residents/$unitId",
    );

    return (response.data as List)
        .map(
          (e) => GuardResident.fromJson(e),
        )
        .toList();
  }
}