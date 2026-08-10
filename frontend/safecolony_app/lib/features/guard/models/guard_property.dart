class GuardProperty {
  final int id;
  final String name;

  const GuardProperty({
    required this.id,
    required this.name,
  });

  factory GuardProperty.fromJson(
    Map<String, dynamic> json,
  ) {
    return GuardProperty(
      id: json["id"],
      name: json["name"],
    );
  }
}