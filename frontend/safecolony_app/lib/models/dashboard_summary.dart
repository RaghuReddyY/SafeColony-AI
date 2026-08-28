import '../core/utils/api_date_time.dart';
class DashboardActivity {
  final String title;
  final String message;
  final String notificationType;
  final DateTime createdAt;
  final bool isRead;
  final int count;

  DashboardActivity({
    required this.title,
    required this.message,
    required this.notificationType,
    required this.createdAt,
    required this.isRead,
    this.count = 1,
  });

  factory DashboardActivity.fromJson(Map<String, dynamic> json) {
    return DashboardActivity(
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      notificationType:
          json['notification_type']?.toString() ?? 'GENERAL',
      createdAt: ApiDateTime.tryParse(json['created_at']) ??
          DateTime.now(),
      isRead: json['is_read'] == true,
      count: int.tryParse(json['count']?.toString() ?? '1') ?? 1,
    );
  }
}

class DashboardSummary {
  final String residentName;
  final String unitNumber;
  final String? sectionName;
  final String? organizationName;
  final String? organizationCode;
  final int visitorCount;
  final int pendingVisitors;
  final int deliveryCount;
  final int pendingDeliveries;
  final int notificationCount;
  final int unreadNotifications;
  final double pendingMaintenance;
  final String? latestMaintenanceStatus;
  final DateTime? latestMaintenanceDueDate;
  final DateTime? latestMaintenancePeriodMonth;
  final double latestMaintenanceCarryForward;
  final double communityFinancePending;
  final int communityFinanceActive;
  final double communityExpenseTotal;
  final int recentMaintenancePayments;
  final bool vacationMode;
  final int securityScore;
  final List<int> weeklyVisitors;
  final List<DashboardActivity> recentActivity;
  final String recommendation;
  final double? weatherTemperature;
  final String? weatherCity;
  final String? weatherDescription;
  final String communityStatus;

  DashboardSummary({
    required this.residentName,
    required this.unitNumber,
    this.sectionName,
    this.organizationName,
    this.organizationCode,
    required this.visitorCount,
    required this.pendingVisitors,
    required this.deliveryCount,
    required this.pendingDeliveries,
    required this.notificationCount,
    required this.unreadNotifications,
    required this.pendingMaintenance,
    required this.latestMaintenanceStatus,
    required this.latestMaintenanceDueDate,
    required this.latestMaintenancePeriodMonth,
    required this.latestMaintenanceCarryForward,
    required this.communityFinancePending,
    this.communityFinanceActive = 0,
    required this.communityExpenseTotal,
    required this.recentMaintenancePayments,
    required this.vacationMode,
    required this.securityScore,
    required this.weeklyVisitors,
    required this.recentActivity,
    required this.recommendation,
    required this.weatherTemperature,
    required this.weatherCity,
    required this.weatherDescription,
    required this.communityStatus,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final rawWeekly = json['weekly_visitors'];
    final weekly = rawWeekly is List
        ? rawWeekly
            .map((value) => int.tryParse(value.toString()) ?? 0)
            .take(7)
            .toList()
        : <int>[];

    while (weekly.length < 7) {
      weekly.add(0);
    }

    final rawActivity = json['recent_activity'];
    final activity = rawActivity is List
        ? rawActivity
            .whereType<Map>()
            .map(
              (item) => DashboardActivity.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <DashboardActivity>[];

    return DashboardSummary(
      residentName: json['resident_name']?.toString() ?? 'Resident',
      unitNumber: json['unit_number']?.toString() ?? 'Not Assigned',
      sectionName: json['section_name']?.toString(),
      organizationName: json['organization_name']?.toString(),
      organizationCode: json['organization_code']?.toString(),
      visitorCount: int.tryParse(json['visitor_count'].toString()) ?? 0,
      pendingVisitors:
          int.tryParse(json['pending_visitors'].toString()) ?? 0,
      deliveryCount:
          int.tryParse(json['delivery_count'].toString()) ?? 0,
      pendingDeliveries:
          int.tryParse(json['pending_deliveries'].toString()) ?? 0,
      notificationCount:
          int.tryParse(json['notification_count'].toString()) ?? 0,
      unreadNotifications:
          int.tryParse(json['unread_notifications'].toString()) ?? 0,
      pendingMaintenance:
          double.tryParse(json['pending_maintenance']?.toString() ?? '') ?? 0.0,
      latestMaintenanceStatus: json['latest_maintenance_status']?.toString(),
      latestMaintenanceDueDate:
          ApiDateTime.tryParse(json['latest_maintenance_due_date']),
      latestMaintenancePeriodMonth:
          ApiDateTime.tryParse(json['latest_maintenance_period_month']),
      latestMaintenanceCarryForward:
          double.tryParse(json['latest_maintenance_carry_forward']?.toString() ?? '') ?? 0.0,
      communityFinancePending:
          double.tryParse(json['community_finance_pending']?.toString() ?? '') ?? 0.0,
      communityFinanceActive:
          int.tryParse(json['community_finance_active']?.toString() ?? '') ?? 0,
      communityExpenseTotal:
          double.tryParse(json['community_expense_total']?.toString() ?? '') ?? 0.0,
      recentMaintenancePayments:
          int.tryParse(json['recent_maintenance_payments']?.toString() ?? '') ?? 0,
      vacationMode: json['vacation_mode'] == true,
      securityScore:
          int.tryParse(json['security_score'].toString()) ?? 0,
      weeklyVisitors: weekly,
      recentActivity: activity,
      recommendation:
          json['recommendation']?.toString() ?? 'No recommendations right now.',
      weatherTemperature: json['weather_temperature'] == null
          ? null
          : double.tryParse(json['weather_temperature'].toString()),
      weatherCity: json['weather_city']?.toString(),
      weatherDescription: json['weather_description']?.toString(),
      communityStatus:
          json['community_status']?.toString() ?? 'Unknown',
    );
  }
}
