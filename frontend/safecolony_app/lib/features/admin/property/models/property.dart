class Property {
  final int id;
  final String name;
  final String propertyType;
  final bool hasMultipleSections;
  final int organizationId;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;

  Property({
    required this.id,
    required this.name,
    required this.propertyType,
    required this.hasMultipleSections,
    required this.organizationId,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json["id"],
      name: json["name"],
      propertyType: json["property_type"],
      hasMultipleSections: json["has_multiple_sections"] ?? false,
      organizationId: json["organization_id"],
      address: json["address"],
      city: json["city"],
      state: json["state"],
      country: json["country"],
      pincode: json["pincode"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "property_type": propertyType,
      "has_multiple_sections": hasMultipleSections,
      "organization_id": organizationId,
      "address": address,
      "city": city,
      "state": state,
      "country": country,
      "pincode": pincode,
    };
  }
}