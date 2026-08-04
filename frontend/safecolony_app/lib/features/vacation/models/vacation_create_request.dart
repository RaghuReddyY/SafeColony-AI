class VacationCreateRequest {
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final String? emergencyContact;
  final String visitorPolicy;
  final String deliveryPolicy;
  final bool notifySecurity;
  final bool monitoringEnabled;

  VacationCreateRequest({
    required this.startDate,
    required this.endDate,
    this.reason,
    this.emergencyContact,
    this.visitorPolicy = "REJECT_ALL",
    this.deliveryPolicy = "ALLOW",
    this.notifySecurity = true,
    this.monitoringEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      "start_date": startDate.toIso8601String().split("T").first,
      "end_date": endDate.toIso8601String().split("T").first,
      "reason": reason,
      "emergency_contact": emergencyContact,
      "visitor_policy": visitorPolicy,
      "delivery_policy": deliveryPolicy,
      "notify_security": notifySecurity,
      "monitoring_enabled": monitoringEnabled,
    };
  }
}