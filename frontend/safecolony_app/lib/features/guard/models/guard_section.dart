class GuardSection {
  final int id;
  final String name;

  const GuardSection({
    required this.id,
    required this.name,
  });

  factory GuardSection.fromJson(
    Map<String, dynamic> json,
  ) {
    return GuardSection(
      id: json["id"],
      name: json["name"],
    );
  }
}