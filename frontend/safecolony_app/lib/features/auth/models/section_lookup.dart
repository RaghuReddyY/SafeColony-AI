class SectionLookup {
  final int id;
  final String name;

  const SectionLookup({
    required this.id,
    required this.name,
  });

  factory SectionLookup.fromJson(
    Map<String, dynamic> json,
  ) {
    return SectionLookup(
      id: json["id"],
      name: json["name"],
    );
  }
}