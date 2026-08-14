import '../../../core/api/api_client.dart';
import '../models/organization_finance.dart';

class OrganizationFinanceService {
  Future<OrganizationFinanceSummary> getSummary() async {
    final response = await ApiClient.dio.get('/dashboard/finance-summary');
    return OrganizationFinanceSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
