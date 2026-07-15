class Visitor {
  final int id;
  final int residentId;

  final String visitorName;
  final String phone;
  final String visitorType;

  final String? purpose;
  final String? vehicleNumber;

  final String status;

  final String? qrToken;
  final String? qrCode;

  final DateTime? approvedAt;

  Visitor({
    required this.id,
    required this.residentId,
    required this.visitorName,
    required this.phone,
    required this.visitorType,
    this.purpose,
    this.vehicleNumber,
    required this.status,
    this.qrToken,
    this.qrCode,
    this.approvedAt,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json["id"],
      residentId: json["resident_id"],
      visitorName: json["visitor_name"],
      phone: json["phone"],
      visitorType: json["visitor_type"],
      purpose: json["purpose"],
      vehicleNumber: json["vehicle_number"],
      status: json["status"],
      qrToken: json["qr_token"],
      qrCode: json["qr_code"],
      approvedAt: json["approved_at"] == null
          ? null
          : DateTime.parse(json["approved_at"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "resident_id": residentId,
      "visitor_name": visitorName,
      "phone": phone,
      "visitor_type": visitorType,
      "purpose": purpose,
      "vehicle_number": vehicleNumber,
    };
  }
}