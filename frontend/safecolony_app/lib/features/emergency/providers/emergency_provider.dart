import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_alert.dart';
import '../services/emergency_service.dart';

final emergencyServiceProvider = Provider<EmergencyService>(
  (ref) => EmergencyService(),
);

final unresolvedEmergencyProvider =
    FutureProvider<List<EmergencyAlert>>((ref) {
  return ref.read(emergencyServiceProvider).getUnresolved();
});

final allEmergencyProvider =
    FutureProvider<List<EmergencyAlert>>((ref) {
  return ref.read(emergencyServiceProvider).getAll();
});
