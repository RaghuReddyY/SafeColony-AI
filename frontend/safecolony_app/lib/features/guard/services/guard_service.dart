import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/guard_scan_result.dart';

class GuardService {
  /// --------------------------------------------------
  /// Validate QR
  /// --------------------------------------------------
  Future<GuardScanResult> validate(
    String qrToken,
  ) async {
    final Response response =
        await ApiClient.dio.post(
      "/guard/validate-qr",
      data: {
        "qr_token": qrToken,
      },
    );

    return GuardScanResult.fromJson(
      response.data,
    );
  }

  /// --------------------------------------------------
  /// Check In
  /// --------------------------------------------------
  Future<GuardScanResult> checkIn(
    int visitorId,
  ) async {
    final Response response =
        await ApiClient.dio.post(
      "/guard/check-in",
      data: {
        "visitor_id": visitorId,
      },
    );

    return GuardScanResult.fromJson(
      response.data,
    );
  }

  /// --------------------------------------------------
  /// Check Out
  /// --------------------------------------------------
  Future<GuardScanResult> checkOut(
    int visitorId,
  ) async {
    final Response response =
        await ApiClient.dio.post(
      "/guard/check-out",
      data: {
        "visitor_id": visitorId,
      },
    );

    return GuardScanResult.fromJson(
      response.data,
    );
  }
}