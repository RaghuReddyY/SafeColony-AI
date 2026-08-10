class GuardUnit {
  final int id;
  final String unitNumber;

  const GuardUnit({
    required this.id,
    required this.unitNumber,
  });

  factory GuardUnit.fromJson(
    Map<String, dynamic> json,
  ) {
    return GuardUnit(
      id: json["id"],
      unitNumber: json["unit_number"],
    );
  }
}