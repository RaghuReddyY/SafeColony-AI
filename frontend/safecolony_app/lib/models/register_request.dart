class RegisterRequest {
  final String organizationCode;
  final int sectionId;
  final String unitNumber;
  final String residentType;

  final String fullName;
  final String email;
  final String phone;
  final String password;

  const RegisterRequest({
    required this.organizationCode,
    required this.sectionId,
    required this.unitNumber,
    this.residentType = "OWNER",
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      "organization_code": organizationCode,
      "section_id": sectionId,
      "unit_number": unitNumber,
      "resident_type": residentType,
      "full_name": fullName,
      "email": email,
      "phone": phone,
      "password": password,
    };
  }
}