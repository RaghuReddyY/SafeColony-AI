class SectionRequest {
  final int propertyId;
  final String name;
  final String description;

  SectionRequest({
    required this.propertyId,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      "property_id": propertyId,
      "name": name,
      "description": description,
    };
  }
}