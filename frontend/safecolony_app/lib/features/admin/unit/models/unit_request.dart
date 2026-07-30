class UnitRequest {
  final int propertyId;
  final int sectionId;
  final String unitNumber;
  final String unitType;
  final String floor;
  final String ownerName;
  final String intercomNumber;

  UnitRequest({
    required this.propertyId,
    required this.sectionId,
    required this.unitNumber,
    required this.unitType,
    required this.floor,
    required this.ownerName,
    required this.intercomNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      "property_id": propertyId,
      "section_id": sectionId,
      "unit_number": unitNumber,
      "unit_type": unitType,
      "floor": floor,
      "owner_name": ownerName,
      "intercom_number": intercomNumber,
    };
  }
}