import 'property_lookup.dart';

class OrganizationLookup {
  final int organizationId;
  final String organizationName;
  final String organizationCode;
  final String? organizationType;

  final List<PropertyLookup> properties;

  const OrganizationLookup({
    required this.organizationId,
    required this.organizationName,
    required this.organizationCode,
    this.organizationType,
    required this.properties,
  });

  factory OrganizationLookup.fromJson(
    Map<String, dynamic> json,
  ) {
    return OrganizationLookup(
      organizationId: json["organization_id"],
      organizationName: json["organization_name"],
      organizationCode: json["organization_code"],
      organizationType: json["organization_type"] ?? "",
      properties: (json["properties"] as List)
          .map(
            (e) => PropertyLookup.fromJson(e),
          )
          .toList(),
    );
  }
}