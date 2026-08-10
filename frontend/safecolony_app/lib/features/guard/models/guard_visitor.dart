class GuardVisitor {
  final int id;
  final int residentId;
  final String visitorName;
  final String phone;
  final String visitorType;
  final String purpose;
  final String? vehicleNumber;
  final String? expectedTime;
  final String status;

  const GuardVisitor({
    required this.id,
    required this.residentId,
    required this.visitorName,
    required this.phone,
    required this.visitorType,
    required this.purpose,
    required this.vehicleNumber,
    required this.expectedTime,
    required this.status,
  });

  factory GuardVisitor.fromJson(Map<String, dynamic> json) {
    return GuardVisitor(
      id: json["id"],
      residentId: json["resident_id"],
      visitorName: json["visitor_name"],
      phone: json["phone"],
      visitorType: json["visitor_type"],
      purpose: json["purpose"],
      vehicleNumber: json["vehicle_number"],
      expectedTime: json["expected_time"],
      status: json["status"],
    );
  }
}