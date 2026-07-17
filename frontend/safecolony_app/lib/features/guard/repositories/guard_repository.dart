import '../models/guard_scan_result.dart';
import '../services/guard_service.dart';

class GuardRepository {
  final GuardService _service = GuardService();

  /// Validate QR Code
  Future<GuardScanResult> validateQR(
    String qrToken,
  ) async {
    return await _service.validate(qrToken);
  }

  /// Check In Visitor
  Future<GuardScanResult> checkIn(
    int visitorId,
  ) async {
    return await _service.checkIn(visitorId);
  }

  /// Check Out Visitor
  Future<GuardScanResult> checkOut(
    int visitorId,
  ) async {
    return await _service.checkOut(visitorId);
  }
}