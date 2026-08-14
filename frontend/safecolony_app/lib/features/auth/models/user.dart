class User {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final int? organizationId;
  final String? organizationCode;
  final String? organizationName;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.organizationId,
    this.organizationCode,
    this.organizationName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],
      fullName: json["full_name"],
      email: json["email"],
      phone: json["phone"],
      role: json["role"],
      organizationId: (json["organization_id"] as num?)?.toInt(),
      organizationCode: json["organization_code"],
      organizationName: json["organization_name"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "full_name": fullName,
        "email": email,
        "phone": phone,
        "role": role,
        "organization_id": organizationId,
        "organization_code": organizationCode,
        "organization_name": organizationName,
      };
}