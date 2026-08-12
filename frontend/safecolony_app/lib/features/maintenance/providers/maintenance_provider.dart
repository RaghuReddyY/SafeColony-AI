import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/maintenance.dart';
import '../services/maintenance_service.dart';

final maintenanceServiceProvider = Provider<MaintenanceService>(
  (ref) => MaintenanceService(),
);

final maintenanceDashboardProvider =
    FutureProvider.autoDispose<MaintenanceDashboard>(
  (ref) {
    return ref.read(maintenanceServiceProvider).getDashboard();
  },
);

/// Resident-specific maintenance data.
///
/// autoDispose is important here because this data belongs to the
/// currently authenticated resident. We must not keep the previous
/// resident's maintenance data after logout/login.
final residentMaintenanceProvider =
    FutureProvider.autoDispose<ResidentMaintenanceSummary>(
  (ref) {
    return ref.read(maintenanceServiceProvider).getMyMaintenance();
  },
);

final communityFinanceProvider =
    FutureProvider.autoDispose<MaintenanceDashboard>(
  (ref) {
    return ref.read(maintenanceServiceProvider).getCommunityFinance();
  },
);

final maintenancePaymentSettingsProvider =
    FutureProvider.autoDispose<MaintenancePaymentSettings>(
  (ref) {
    return ref.read(maintenanceServiceProvider).getPaymentSettings();
  },
);

final pendingMaintenancePaymentsProvider =
    FutureProvider.autoDispose<List<PendingMaintenancePayment>>(
  (ref) {
    return ref.read(maintenanceServiceProvider).getPendingPayments();
  },
);