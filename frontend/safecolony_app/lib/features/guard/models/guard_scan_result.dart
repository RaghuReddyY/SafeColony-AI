class GuardScanResult {
  final int id;
  final String visitorName;
  final int residentId;
  final String phone;
  final String visitorType;
  final String? purpose;
  final String? vehicleNumber;
  final String status;

  GuardScanResult({
    required this.id,
    required this.visitorName,
    required this.residentId,
    required this.phone,
    required this.visitorType,
    this.purpose,
    this.vehicleNumber,
    required this.status,
  });

  factory GuardScanResult.fromJson(
      Map<String, dynamic> json) {
    return GuardScanResult(
      id: json["id"],
      visitorName: json["visitor_name"],
      residentId: json["resident_id"],
      phone: json["phone"],
      visitorType: json["visitor_type"],
      purpose: json["purpose"],
      vehicleNumber: json["vehicle_number"],
      status: json["status"],
    );
  }
}