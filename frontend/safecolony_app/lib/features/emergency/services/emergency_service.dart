import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/emergency_alert.dart';

class EmergencyService {
  Future<EmergencyAlert> raiseEmergency({
    required String emergencyType,
    String? message,
    String severity = 'CRITICAL',
  }) async {
    final Response response = await ApiClient.dio.post(
      '/security-alerts/emergency',
      data: {
        'emergency_type': emergencyType,
        'message': message,
        'severity': severity,
      },
    );

    return EmergencyAlert.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<List<EmergencyAlert>> getUnresolved() async {
    final Response response = await ApiClient.dio.get(
      '/security-alerts/unresolved',
    );

    return (response.data as List)
        .map(
          (item) => EmergencyAlert.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<List<EmergencyAlert>> getAll() async {
    final Response response = await ApiClient.dio.get(
      '/security-alerts',
    );

    return (response.data as List)
        .map(
          (item) => EmergencyAlert.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<EmergencyAlert> resolve(int alertId) async {
    final Response response = await ApiClient.dio.put(
      '/security-alerts/$alertId/resolve',
    );

    return EmergencyAlert.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }
}
