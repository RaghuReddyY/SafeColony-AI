import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/guard_dashboard_service.dart';

final guardDashboardProvider =
    Provider<GuardDashboardService>((ref) {
  return GuardDashboardService();
});