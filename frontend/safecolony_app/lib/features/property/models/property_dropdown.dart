class PropertyDropdown {
  final int id;
  final String name;

  PropertyDropdown({
    required this.id,
    required this.name,
  });

  factory PropertyDropdown.fromJson(Map<String, dynamic> json) {
    return PropertyDropdown(
      id: json["id"],
      name: json["name"],
    );
  }
}