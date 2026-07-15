class DashboardSummary {

  final String residentName;
  final String unitNumber;

  final int visitorCount;
  final int pendingVisitors;

  final int deliveryCount;
  final int pendingDeliveries;

  final int notificationCount;
  final int unreadNotifications;

  final bool vacationMode;

  final int securityScore;

  DashboardSummary({
    required this.residentName,
    required this.unitNumber,
    required this.visitorCount,
    required this.pendingVisitors,
    required this.deliveryCount,
    required this.pendingDeliveries,
    required this.notificationCount,
    required this.unreadNotifications,
    required this.vacationMode,
    required this.securityScore,
  });

  factory DashboardSummary.fromJson(
      Map<String, dynamic> json) {

    return DashboardSummary(
      residentName: json["resident_name"],
      unitNumber: json["unit_number"],
      visitorCount: json["visitor_count"],
      pendingVisitors: json["pending_visitors"],
      deliveryCount: json["delivery_count"],
      pendingDeliveries: json["pending_deliveries"],
      notificationCount: json["notification_count"],
      unreadNotifications: json["unread_notifications"],
      vacationMode: json["vacation_mode"],
      securityScore: json["security_score"],
    );
  }
}