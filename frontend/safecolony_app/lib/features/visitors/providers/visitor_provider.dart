import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visitor.dart';
import '../services/visitor_service.dart';

final visitorProvider =
    Provider<VisitorProvider>((ref) {
  return VisitorProvider();
});

class VisitorProvider {
  final VisitorService _service =
      VisitorService();

  /// Load all visitors
  Future<List<Visitor>> loadVisitors() {
    return _service.getVisitors();
  }

  /// Load resident visitors
  Future<List<Visitor>> loadResidentVisitors(
      int residentId) {
    return _service.getResidentVisitors(
      residentId,
    );
  }

  /// Create Visitor
  Future<Visitor> createVisitor(
      Visitor visitor) {
    return _service.createVisitor(
      visitor,
    );
  }

  /// Approve Visitor
  Future<Visitor> approveVisitor(
      int visitorId) {
    return _service.approveVisitor(
      visitorId,
    );
  }

  /// Reject Visitor
  Future<Visitor> rejectVisitor(
      int visitorId) {
    return _service.rejectVisitor(
      visitorId,
    );
  }

  /// Check In
  Future<Visitor> checkInVisitor(
      int visitorId) {
    return _service.checkInVisitor(
      visitorId,
    );
  }

  /// Check Out
  Future<Visitor> checkOutVisitor(
      int visitorId) {
    return _service.checkOutVisitor(
      visitorId,
    );
  }
}