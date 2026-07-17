import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/guard_dashboard.dart';

class GuardDashboardService {

  Future<GuardDashboard> loadDashboard() async {

    final Response response =
        await ApiClient.dio.get(
      "/guard/dashboard",
    );

    return GuardDashboard.fromJson(
      response.data,
    );
  }
}