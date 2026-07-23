class PropertyLookup {
  final int id;
  final String name;

  const PropertyLookup({
    required this.id,
    required this.name,
  });

  factory PropertyLookup.fromJson(
    Map<String, dynamic> json,
  ) {
    return PropertyLookup(
      id: json["id"],
      name: json["name"],
    );
  }
}