class Unit {
  final int id;
  final int propertyId;
  final int sectionId;
  final String unitNumber;
  final String unitType;
  final String floor;
  final String ownerName;
  final String occupancyStatus;
  final String intercomNumber;
  final bool isActive;

  Unit({
    required this.id,
    required this.propertyId,
    required this.sectionId,
    required this.unitNumber,
    required this.unitType,
    required this.floor,
    required this.ownerName,
    required this.occupancyStatus,
    required this.intercomNumber,
    required this.isActive,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json["id"],
      propertyId: json["property_id"],
      sectionId: json["section_id"],
      unitNumber: json["unit_number"],
      unitType: json["unit_type"],
      floor: json["floor"] ?? "",
      ownerName: json["owner_name"] ?? "",
      occupancyStatus: json["occupancy_status"] ?? "",
      intercomNumber: json["intercom_number"] ?? "",
      isActive: json["is_active"] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "property_id": propertyId,
      "section_id": sectionId,
      "unit_number": unitNumber,
      "unit_type": unitType,
      "floor": floor,
      "owner_name": ownerName,
      "occupancy_status": occupancyStatus,
      "intercom_number": intercomNumber,
      "is_active": isActive,
    };
  }
}