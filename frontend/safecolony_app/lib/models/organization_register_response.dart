class OrganizationRegisterResponse {
  final String message;
  final int organizationId;
  final String organizationName;
  final String organizationCode;
  final int adminUserId;
  final String adminEmail;

  OrganizationRegisterResponse({
    required this.message,
    required this.organizationId,
    required this.organizationName,
    required this.organizationCode,
    required this.adminUserId,
    required this.adminEmail,
  });

  factory OrganizationRegisterResponse.fromJson(
      Map<String, dynamic> json) {
    return OrganizationRegisterResponse(
      message: json["message"],
      organizationId: json["organization_id"],
      organizationName: json["organization_name"],
      organizationCode: json["organization_code"],
      adminUserId: json["admin_user_id"],
      adminEmail: json["admin_email"],
    );
  }
}