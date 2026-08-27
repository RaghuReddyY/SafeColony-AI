import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/maintenance.dart';

class MaintenanceService {
  Future<MaintenanceDashboard> getDashboard() async {
    final Response response = await ApiClient.dio.get('/maintenance/dashboard');
    return MaintenanceDashboard.fromJson(response.data);
  }

  Future<MaintenancePeriod> createPeriod({
    required DateTime month,
    required double monthlyAmount,
    required DateTime dueDate,
    String? notes,
  }) async {
    final response = await ApiClient.dio.post(
      '/maintenance/periods',
      data: {
        'month': _date(month),
        'monthly_amount': monthlyAmount,
        'due_date': _date(dueDate),
        'notes': notes,
      },
    );
    return MaintenancePeriod.fromJson(response.data);
  }

  Future<MaintenancePeriod> updatePeriod({
    required int periodId,
    required double monthlyAmount,
    required DateTime dueDate,
    String? notes,
  }) async {
    final response = await ApiClient.dio.put(
      '/maintenance/periods/$periodId',
      data: {
        'monthly_amount': monthlyAmount,
        'due_date': _date(dueDate),
        'notes': notes,
      },
    );
    return MaintenancePeriod.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<void> deletePeriod(int periodId) async {
    await ApiClient.dio.delete('/maintenance/periods/$periodId');
  }

  Future<MaintenancePeriod> closePeriod(int periodId) async {
  final response = await ApiClient.dio.post(
    '/maintenance/periods/$periodId/close',
  );
  return MaintenancePeriod.fromJson(
    Map<String, dynamic>.from(response.data),
  );
}

  Future<Map<String, dynamic>> generateBills(int periodId) async {
    final response = await ApiClient.dio.post(
      '/maintenance/periods/$periodId/generate-bills',
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<MaintenanceExpense> addExpense({
    required int periodId,
    required String category,
    required String description,
    required double amount,
    required DateTime spentOn,
  }) async {
    final response = await ApiClient.dio.post(
      '/maintenance/periods/$periodId/expenses',
      data: {
        'category': category,
        'description': description,
        'amount': amount,
        'spent_on': _date(spentOn),
      },
    );
    return MaintenanceExpense.fromJson(response.data);
  }

  Future<MaintenanceDashboard> getCommunityFinance() async {
    final response = await ApiClient.dio.get('/maintenance/community-finance');
    return MaintenanceDashboard.fromJson(response.data);
  }

  Future<Map<String, dynamic>> createOnlinePayment(int billId) async {
    final response = await ApiClient.dio.post('/maintenance/bills/$billId/pay');
    return Map<String, dynamic>.from(response.data);
  }

  Future<MaintenancePaymentSettings> getPaymentSettings() async {
    final response = await ApiClient.dio.get('/maintenance/payment-settings');
    return MaintenancePaymentSettings.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<MaintenancePaymentSettings> updatePaymentSettings({
    required String mode,
    String? upiId,
    String? displayName,
    String? paymentPhone,
    String lateFeeType = 'NONE',
    double lateFeeValue = 0,
    int lateFeeGraceDays = 0,
  }) async {
    final response = await ApiClient.dio.put(
      '/maintenance/payment-settings',
      data: {
        'mode': mode,
        'upi_id': upiId,
        'display_name': displayName,
        'payment_phone': paymentPhone,
        'late_fee_type': lateFeeType,
        'late_fee_value': lateFeeValue,
        'late_fee_grace_days': lateFeeGraceDays,
      },
    );
    return MaintenancePaymentSettings.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<DirectUPIPaymentSubmission> submitDirectUPIPayment({
    required int billId,
    required double amount,
    required String reference,
  }) async {
    final response = await ApiClient.dio.post(
      '/maintenance/bills/$billId/direct-upi-payment',
      data: {
        'amount': amount,
        'reference': reference,
      },
    );
    return DirectUPIPaymentSubmission.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<List<PendingMaintenancePayment>> getPendingPayments() async {
    final response = await ApiClient.dio.get('/maintenance/payments/pending');
    return (response.data as List)
        .map((e) => PendingMaintenancePayment.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> verifyDirectUPIPayment({
    required int paymentId,
    required bool approve,
  }) async {
    final response = await ApiClient.dio.post(
      '/maintenance/payments/$paymentId/verify',
      queryParameters: {'approve': approve},
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<ResidentMaintenanceSummary> getMyMaintenance() async {
    final response = await ApiClient.dio.get('/maintenance/me');
    return ResidentMaintenanceSummary.fromJson(response.data);
  }

  Future<MaintenancePayerInfo> getMaintenancePayer() async {
    final response = await ApiClient.dio.get('/maintenance/me/payer');
    return MaintenancePayerInfo.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MaintenancePayerInfo> updateMaintenancePayer(int residentId) async {
    final response = await ApiClient.dio.put(
      '/maintenance/me/payer',
      data: {'resident_id': residentId},
    );
    return MaintenancePayerInfo.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MaintenanceBill> updateBill({
    required int billId,
    required double amount,
    required DateTime dueDate,
  }) async {
    final response = await ApiClient.dio.put(
      '/maintenance/bills/$billId',
      data: {
        'amount': amount,
        'due_date': _date(dueDate),
      },
    );
    return MaintenanceBill.fromJson(response.data);
  }

  Future<MaintenanceExpense> updateExpense({
    required int expenseId,
    required String category,
    required String description,
    required double amount,
    required DateTime spentOn,
  }) async {
    final response = await ApiClient.dio.put(
      '/maintenance/expenses/$expenseId',
      data: {
        'category': category,
        'description': description,
        'amount': amount,
        'spent_on': spentOn.toIso8601String().split('T').first,
      },
    );
    return MaintenanceExpense.fromJson(response.data);
  }

  Future<void> deleteBill(int billId) async {
    await ApiClient.dio.delete('/maintenance/bills/$billId');
  }

  Future<MaintenanceBill> recordPayment({
    required int billId,
    required double amount,
    String paymentMethod = 'MANUAL',
    String? reference,
  }) async {
    final response = await ApiClient.dio.post(
      '/maintenance/bills/$billId/payments',
      data: {
        'amount': amount,
        'payment_method': paymentMethod,
        'reference': reference,
      },
    );
    return MaintenanceBill.fromJson(response.data);
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
