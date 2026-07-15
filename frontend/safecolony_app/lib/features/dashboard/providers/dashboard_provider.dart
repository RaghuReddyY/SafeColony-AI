import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/dashboard_summary.dart';
import '../../../services/dashboard_service.dart';

final dashboardProvider =
    Provider<DashboardProvider>((ref) {
  return DashboardProvider();
});

class DashboardProvider {

  final DashboardService _service =
      DashboardService();

  Future<DashboardSummary> loadDashboard(
      int residentId) {

    return _service.getSummary(
      residentId,
    );
  }
}