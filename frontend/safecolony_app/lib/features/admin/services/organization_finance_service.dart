import '../../../core/api/api_client.dart';
import '../models/organization_finance.dart';

class OrganizationFinanceService {
  Future<OrganizationFinanceSummary> getSummary() async {
    final response = await ApiClient.dio.get('/dashboard/finance-summary');
    return OrganizationFinanceSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<MoneyTransaction>> getMoneyDetails() async {
    final response = await ApiClient.dio.get('/dashboard/money-details');
    return (response.data as List)
        .map((e) => MoneyTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
