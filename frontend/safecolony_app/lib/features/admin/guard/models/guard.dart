class Guard {
  final int id;
  final String fullName;
  final String email;
  final String phone;

  const Guard({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory Guard.fromJson(Map<String, dynamic> json) {
    return Guard(
      id: json["id"],
      fullName: json["full_name"],
      email: json["email"],
      phone: json["phone"],
    );
  }
}