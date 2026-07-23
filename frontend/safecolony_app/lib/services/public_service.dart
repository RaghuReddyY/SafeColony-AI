import '../core/api/api_client.dart';

import '../features/auth/models/organization_lookup.dart';
import '../features/auth/models/section_lookup.dart';

class PublicService {
  Future<OrganizationLookup> getOrganization(
    String organizationCode,
  ) async {
    final response = await ApiClient.dio.get(
      "/public/organization/$organizationCode",
    );

    return OrganizationLookup.fromJson(
      response.data,
    );
  }

  Future<List<SectionLookup>> getSections(
    int propertyId,
  ) async {
    final response = await ApiClient.dio.get(
      "/public/properties/$propertyId/sections",
    );

    return (response.data as List)
        .map(
          (e) => SectionLookup.fromJson(e),
        )
        .toList();
  }
}