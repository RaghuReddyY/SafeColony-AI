
import '../core/api/api_client.dart';
import '../models/dashboard_summary.dart';

class DashboardService {
  Future<DashboardSummary> getSummary(int residentId) async {
    print("==================================");
    print(ApiClient.dio.options.baseUrl);
    print("/dashboard/summary/$residentId");

    final response = await ApiClient.dio.get(
      "/dashboard/summary/$residentId",
    );

    print(response.requestOptions.uri);
    print(response.data);

    return DashboardSummary.fromJson(response.data);
  }
}