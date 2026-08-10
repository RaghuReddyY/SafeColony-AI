import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/guard_visitor.dart';

class GuardVisitorService {
  Future<List<GuardVisitor>> loadPendingVisitors() async {
    final Response response = await ApiClient.dio.get(
      "/guard/pending-visitors",
    );

    return (response.data as List)
        .map((e) => GuardVisitor.fromJson(e))
        .toList();
  }

  Future<List<GuardVisitor>> loadApprovedVisitors() async {
    final Response response = await ApiClient.dio.get(
      "/guard/approved",
    );

    return (response.data as List)
        .map((e) => GuardVisitor.fromJson(e))
        .toList();
  }

  Future<List<GuardVisitor>> loadInsideVisitors() async {
    final Response response = await ApiClient.dio.get(
      "/guard/inside",
    );

    return (response.data as List)
        .map((e) => GuardVisitor.fromJson(e))
        .toList();
  }

  Future<void> checkIn(int visitorId) async {
    await ApiClient.dio.post(
      "/guard/check-in",
      data: {
        "visitor_id": visitorId,
      },
    );
  }

  Future<void> checkOut(int visitorId) async {
    await ApiClient.dio.post(
      "/guard/check-out",
      data: {
        "visitor_id": visitorId,
      },
    );
  }
}