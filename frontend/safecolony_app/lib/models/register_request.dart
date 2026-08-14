class RegisterRequest {
  final String organizationCode;
  final int? sectionId;
  final String unitNumber;
  final String residentType;

  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String? familyJoinCode;

  const RegisterRequest({
    required this.organizationCode,
    this.sectionId,
    required this.unitNumber,
    this.residentType = "OWNER",
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    this.familyJoinCode,
  });

  Map<String, dynamic> toJson() {
    return {
      "organization_code": organizationCode,
      if (sectionId != null) "section_id": sectionId,
      if (unitNumber.trim().isNotEmpty) "unit_number": unitNumber,
      "resident_type": residentType,
      "full_name": fullName,
      "email": email,
      "phone": phone,
      "password": password,
      if (familyJoinCode != null && familyJoinCode!.trim().isNotEmpty)
        "family_join_code": familyJoinCode!.trim().toUpperCase(),
    };
  }
}