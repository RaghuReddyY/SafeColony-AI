class Section {
  final int id;
  final int propertyId;
  final String name;
  final String description;

  Section({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.description,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json["id"],
      propertyId: json["property_id"],
      name: json["name"],
      description: json["description"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "property_id": propertyId,
      "name": name,
      "description": description,
    };
  }
}