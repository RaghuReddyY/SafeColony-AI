import '../core/api/api_client.dart';
import '../models/dashboard_summary.dart';

class DashboardService {

  Future<DashboardSummary> getSummary() async {

    final response = await ApiClient.dio.get(
      "/dashboard/summary",
    );

    return DashboardSummary.fromJson(response.data);
  }
}