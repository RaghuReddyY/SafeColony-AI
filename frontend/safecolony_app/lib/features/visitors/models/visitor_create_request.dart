class VisitorCreateRequest {
  final int residentId;
  final String visitorName;
  final String phone;
  final String visitorType;
  final String? purpose;
  final String? vehicleNumber;
  final DateTime? expectedTime;

  // Walk-in Support
  final String entryMode;
  final String? visitorPhoto;
  final bool createdByGuard;

  const VisitorCreateRequest({
    required this.residentId,
    required this.visitorName,
    required this.phone,
    this.visitorType = "Guest",
    this.purpose,
    this.vehicleNumber,
    this.expectedTime,
    this.entryMode = "QR",
    this.visitorPhoto,
    this.createdByGuard = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "resident_id": residentId,
      "visitor_name": visitorName,
      "phone": phone,
      "visitor_type": visitorType,
      "purpose": purpose,
      "vehicle_number": vehicleNumber,
      "expected_time": expectedTime?.toIso8601String(),
      "entry_mode": entryMode,
      "visitor_photo": visitorPhoto,
      "created_by_guard": createdByGuard,
    };
  }
}