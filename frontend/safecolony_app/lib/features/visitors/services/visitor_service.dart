import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/visitor.dart';
import '../models/visitor_create_request.dart';

class VisitorService {
  /// Get all visitors (Admin)
  Future<List<Visitor>> getVisitors() async {
    final Response response =
        await ApiClient.dio.get("/visitors");

    return (response.data as List)
        .map((e) => Visitor.fromJson(e))
        .toList();
  }

  /// Resident Visitor List for the authenticated resident.
  /// The backend resolves the resident from the logged-in user so the
  /// client never depends on a hard-coded resident id.
  Future<List<Visitor>> getMyVisitors() async {
    final Response response =
        await ApiClient.dio.get("/visitors/resident/me");

    return (response.data as List)
        .map((e) => Visitor.fromJson(e))
        .toList();
  }

  /// Resident Visitor List
  Future<List<Visitor>> getResidentVisitors(
      int residentId) async {
    final Response response =
        await ApiClient.dio.get(
      "/visitors/resident/$residentId",
    );

    return (response.data as List)
        .map((e) => Visitor.fromJson(e))
        .toList();
  }

  /// Resident creates planned visitor
  Future<Visitor> createVisitor(
    VisitorCreateRequest request,
  ) async {
    final Response response =
        await ApiClient.dio.post(
      "/visitors/resident",
      data: request.toJson(),
    );

    return Visitor.fromJson(response.data);
  }

  /// Guard creates walk-in visitor
  Future<Visitor> createWalkInVisitor(
    VisitorCreateRequest request,
  ) async {
    final Response response =
        await ApiClient.dio.post(
      "/guard/walk-in",
      data: request.toJson(),
    );

    return Visitor.fromJson(response.data);
  }

  /// Resident approves visitor
  Future<Visitor> approveVisitor(
      int visitorId) async {
    final Response response =
        await ApiClient.dio.post(
      "/visitors/resident/$visitorId/approve",
    );

    return Visitor.fromJson(response.data);
  }

  /// Resident rejects visitor
  Future<Visitor> rejectVisitor(
      int visitorId) async {
    final Response response =
        await ApiClient.dio.post(
      "/visitors/resident/$visitorId/reject",
    );

    return Visitor.fromJson(response.data);
  }

  /// Guard Check In
  Future<Visitor> checkInVisitor(
      int visitorId) async {
    final Response response =
        await ApiClient.dio.post(
      "/visitors/$visitorId/check-in",
    );

    return Visitor.fromJson(response.data);
  }

  /// Guard Check Out
  Future<Visitor> checkOutVisitor(
      int visitorId) async {
    final Response response =
        await ApiClient.dio.post(
      "/visitors/$visitorId/check-out",
    );

    return Visitor.fromJson(response.data);
  }
}