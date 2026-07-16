import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/guard_scan_result.dart';

class GuardService {

  /// Validate QR (does NOT check in)
  Future<GuardScanResult> validate(
    String qrToken,
  ) async {

    final Response response =
        await ApiClient.dio.post(
      "/visitors/validate-qr",
      data: {
        "qr_token": qrToken,
      },
    );

    return GuardScanResult.fromJson(
      response.data,
    );
  }

  /// Check In
  Future<GuardScanResult> checkIn(
    String qrToken,
  ) async {

    final Response response =
        await ApiClient.dio.post(
      "/visitors/scan",
      data: {
        "qr_token": qrToken,
      },
    );

    return GuardScanResult.fromJson(
      response.data,
    );
  }

  /// Check Out
  Future<GuardScanResult> checkOut(
    String qrToken,
  ) async {

    final Response response =
        await ApiClient.dio.post(
      "/visitors/scan-exit",
      data: {
        "qr_token": qrToken,
      },
    );

    return GuardScanResult.fromJson(
      response.data,
    );
  }
}