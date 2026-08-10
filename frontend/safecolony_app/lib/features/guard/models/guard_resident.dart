class GuardResident {
  final int id;
  final String fullName;

  const GuardResident({
    required this.id,
    required this.fullName,
  });

  factory GuardResident.fromJson(
    Map<String, dynamic> json,
  ) {
    return GuardResident(
      id: json["id"],
      fullName: json["full_name"],
    );
  }
}