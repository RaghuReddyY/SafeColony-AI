class User {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String role;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],
      fullName: json["full_name"],
      email: json["email"],
      phone: json["phone"],
      role: json["role"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "full_name": fullName,
        "email": email,
        "phone": phone,
        "role": role,
      };
}