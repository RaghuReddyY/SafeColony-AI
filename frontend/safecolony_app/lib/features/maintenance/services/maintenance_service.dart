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

  Future<ResidentMaintenanceSummary> getMyMaintenance() async {
    final response = await ApiClient.dio.get('/maintenance/me');
    return ResidentMaintenanceSummary.fromJson(response.data);
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
