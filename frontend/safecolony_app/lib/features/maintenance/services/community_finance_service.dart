import '../../../core/api/api_client.dart';
import '../models/community_finance.dart';

class CommunityFinanceService {
  Future<CommunityFinanceDashboard> getDashboard() async {
    final response = await ApiClient.dio.get('/community-finance/dashboard');
    return CommunityFinanceDashboard.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<CommunityFund> createFund({
    required String title,
    required String purpose,
    double? targetAmount,
    required String contributionMode,
    double? perUnitAmount,
    DateTime? dueDate,
    String paymentMethod = 'MANUAL',
    String? paymentUpiId,
    String? paymentDisplayName,
    String status = 'PUBLISHED',
  }) async {
    final response = await ApiClient.dio.post('/community-finance/funds', data: {
      'title': title,
      'purpose': purpose,
      'target_amount': targetAmount,
      'contribution_mode': contributionMode,
      'per_unit_amount': perUnitAmount,
      'due_date': dueDate == null ? null : _date(dueDate),
      'payment_method': paymentMethod,
      'payment_upi_id': paymentUpiId,
      'payment_display_name': paymentDisplayName,
      'status': status,
    });
    return CommunityFund.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<CommunityFund> updateFund({
    required int fundId,
    required String title,
    required String purpose,
    double? targetAmount,
    required String contributionMode,
    double? perUnitAmount,
    String paymentMethod = 'MANUAL',
    String? paymentUpiId,
    String? paymentDisplayName,
  }) async {
    final response = await ApiClient.dio.put('/community-finance/funds/$fundId', data: {
      'title': title,
      'purpose': purpose,
      'target_amount': targetAmount,
      'contribution_mode': contributionMode,
      'per_unit_amount': perUnitAmount,
      'payment_method': paymentMethod,
      'payment_upi_id': paymentUpiId,
      'payment_display_name': paymentDisplayName,
    });
    return CommunityFund.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> deleteFund(int fundId) async {
    await ApiClient.dio.delete('/community-finance/funds/$fundId');
  }

  Future<void> publishFund(int fundId) async {
    await ApiClient.dio.post('/community-finance/funds/$fundId/publish');
  }

  Future<void> closeFund(int fundId) async {
    await ApiClient.dio.post('/community-finance/funds/$fundId/close');
  }

  Future<CommunityPaymentLink> createPayment({required int fundId, required double amount}) async {
    final response = await ApiClient.dio.post(
      '/community-finance/funds/$fundId/pay',
      queryParameters: {'amount': amount},
    );
    return CommunityPaymentLink.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<CommunityFund> submitPayment({
    required int fundId,
    required double amount,
    String? reference,
  }) async {
    final response = await ApiClient.dio.post('/community-finance/funds/$fundId/payments', data: {
      'amount': amount,
      'reference': reference,
    });
    return CommunityFund.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<CommunityFund> addContribution({
    required int fundId,
    required String payerName,
    String? blockName,
    String? unitNumber,
    required double amount,
    String paymentMethod = 'MANUAL',
    String? reference,
  }) async {
    final response = await ApiClient.dio.post('/community-finance/funds/$fundId/contributions', data: {
      'payer_name': payerName,
      'block_name': blockName,
      'unit_number': unitNumber,
      'amount': amount,
      'payment_method': paymentMethod,
      'reference': reference,
    });
    return CommunityFund.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> verifyContribution({required int contributionId, required bool approve}) async {
    await ApiClient.dio.post(
      '/community-finance/contributions/$contributionId/verify',
      queryParameters: {'approve': approve},
    );
  }

  Future<CommunityFund> addExpense({
    required int fundId,
    required String category,
    required String description,
    required double amount,
    required DateTime spentOn,
  }) async {
    final response = await ApiClient.dio.post('/community-finance/funds/$fundId/expenses', data: {
      'category': category,
      'description': description,
      'amount': amount,
      'spent_on': _date(spentOn),
    });
    return CommunityFund.fromJson(Map<String, dynamic>.from(response.data));
  }

  String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
