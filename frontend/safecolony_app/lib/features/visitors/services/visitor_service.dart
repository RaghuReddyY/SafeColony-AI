import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/visitor.dart';

class VisitorService {
  /// Get all visitors
  Future<List<Visitor>> getVisitors() async {
    final Response response = await ApiClient.dio.get(
      "/visitors",
    );

    return (response.data as List)
        .map(
          (e) => Visitor.fromJson(e),
        )
        .toList();
  }

  /// Get visitors for a resident
  Future<List<Visitor>> getResidentVisitors(
      int residentId) async {
    final Response response = await ApiClient.dio.get(
      "/visitors/resident/$residentId",
    );

    return (response.data as List)
        .map(
          (e) => Visitor.fromJson(e),
        )
        .toList();
  }

  /// Create visitor
  Future<Visitor> createVisitor(
      Visitor visitor) async {
    final Response response = await ApiClient.dio.post(
      "/visitors",
      data: visitor.toJson(),
    );

    return Visitor.fromJson(
      response.data,
    );
  }

  /// Approve visitor
  Future<Visitor> approveVisitor(
      int visitorId) async {
    final Response response = await ApiClient.dio.post(
      "/visitors/$visitorId/approve",
    );

    return Visitor.fromJson(
      response.data,
    );
  }

  /// Reject visitor
  Future<Visitor> rejectVisitor(
      int visitorId) async {
    final Response response = await ApiClient.dio.post(
      "/visitors/$visitorId/reject",
    );

    return Visitor.fromJson(
      response.data,
    );
  }

  /// Check In
  Future<Visitor> checkInVisitor(
      int visitorId) async {
    final Response response = await ApiClient.dio.post(
      "/visitors/$visitorId/check-in",
    );

    return Visitor.fromJson(
      response.data,
    );
  }

  /// Check Out
  Future<Visitor> checkOutVisitor(
      int visitorId) async {
    final Response response = await ApiClient.dio.post(
      "/visitors/$visitorId/check-out",
    );

    return Visitor.fromJson(
      response.data,
    );
  }
}