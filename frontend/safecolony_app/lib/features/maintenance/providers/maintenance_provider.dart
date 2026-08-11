import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/maintenance.dart';
import '../services/maintenance_service.dart';

final maintenanceServiceProvider = Provider<MaintenanceService>(
  (ref) => MaintenanceService(),
);

final maintenanceDashboardProvider = FutureProvider<MaintenanceDashboard>(
  (ref) => ref.read(maintenanceServiceProvider).getDashboard(),
);

final residentMaintenanceProvider = FutureProvider<ResidentMaintenanceSummary>(
  (ref) => ref.read(maintenanceServiceProvider).getMyMaintenance(),
);
