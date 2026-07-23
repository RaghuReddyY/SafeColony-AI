class PendingResident {
  final int id;
  final int userId;
  final String fullName;
  final String email;
  final String phone;
  final String propertyName;
  final String sectionName;
  final String unitNumber;
  final String residentType;
  final String status;
  final String? gender;
  final bool isPrimary;
  final bool isActive;

  PendingResident({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.propertyName,
    required this.sectionName,
    required this.unitNumber,
    required this.residentType,
    required this.status,
    this.gender,
    required this.isPrimary,
    required this.isActive,
  });

  factory PendingResident.fromJson(Map<String, dynamic> json) {
    return PendingResident(
      id: json['id'],
      userId: json['user_id'],
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'],
      propertyName: json['property_name'],
      sectionName: json['section_name'],
      unitNumber: json['unit_number'],
      residentType: json['resident_type'],
      status: json['status'],
      gender: json['gender'],
      isPrimary: json['is_primary'],
      isActive: json['is_active'],
    );
  }
}