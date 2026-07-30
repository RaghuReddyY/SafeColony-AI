class PropertyRequest {
  final String name;
  final String propertyType;
  final bool hasMultipleSections;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;

  PropertyRequest({
    required this.name,
    required this.propertyType,
    required this.hasMultipleSections,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "property_type": propertyType,
      "has_multiple_sections": hasMultipleSections,
      "address": address,
      "city": city,
      "state": state,
      "country": country,
      "pincode": pincode,
    };
  }
}