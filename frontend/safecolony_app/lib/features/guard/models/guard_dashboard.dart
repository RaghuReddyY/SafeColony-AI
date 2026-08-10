class GuardDashboard {
  final DashboardSummary summary;
  final List<ExpectedVisitor> expectedVisitors;
  final List<RecentActivity> recentActivities;
  final String aiMessage;

  const GuardDashboard({
    required this.summary,
    required this.expectedVisitors,
    required this.recentActivities,
    required this.aiMessage,
  });

  factory GuardDashboard.fromJson(
    Map<String, dynamic> json,
  ) {
    return GuardDashboard(
      summary: DashboardSummary.fromJson(
        json["summary"],
      ),

      expectedVisitors:
          (json["expected_visitors"] as List)
              .map(
                (e) => ExpectedVisitor.fromJson(e),
              )
              .toList(),

      recentActivities:
          (json["recent_activities"] as List)
              .map(
                (e) => RecentActivity.fromJson(e),
              )
              .toList(),

      aiMessage: json["ai_message"],
    );
  }
}

class DashboardSummary {
  final int pendingVisitors;
  final int approvedVisitors;
  final int insideVisitors;
  final int deliveries;
  final int checkedInToday;

  const DashboardSummary({
    required this.pendingVisitors,
    required this.approvedVisitors,
    required this.insideVisitors,
    required this.deliveries,
    required this.checkedInToday,
  });

  factory DashboardSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return DashboardSummary(
      pendingVisitors:
          json["pending_visitors"] ?? 0,

      approvedVisitors:
          json["approved_visitors"] ?? 0,

      insideVisitors:
          json["inside_visitors"] ?? 0,

      deliveries:
          json["deliveries"] ?? 0,

      checkedInToday:
          json["checked_in_today"] ?? 0,
    );
  }
}

class ExpectedVisitor {
  final int id;
  final int residentId;

  final String visitorName;
  final String visitorType;
  final String phone;

  final String? purpose;
  final String? vehicleNumber;
  final String? expectedTime;

  final String status;

  const ExpectedVisitor({
    required this.id,
    required this.residentId,
    required this.visitorName,
    required this.visitorType,
    required this.phone,
    required this.status,
    this.purpose,
    this.vehicleNumber,
    this.expectedTime,
  });

  factory ExpectedVisitor.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExpectedVisitor(
      id: json["id"],
      residentId: json["resident_id"],
      visitorName: json["visitor_name"],
      visitorType: json["visitor_type"],
      phone: json["phone"],
      purpose: json["purpose"],
      vehicleNumber: json["vehicle_number"],
      expectedTime: json["expected_time"],
      status: json["status"],
    );
  }
}

class RecentActivity {
  final String icon;
  final String title;
  final String time;

  const RecentActivity({
    required this.icon,
    required this.title,
    required this.time,
  });

  factory RecentActivity.fromJson(
    Map<String, dynamic> json,
  ) {
    return RecentActivity(
      icon: json["icon"],
      title: json["title"],
      time: json["time"],
    );
  }
}