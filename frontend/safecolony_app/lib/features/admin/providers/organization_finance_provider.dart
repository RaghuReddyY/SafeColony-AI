import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/organization_finance.dart';
import '../services/organization_finance_service.dart';

final organizationFinanceServiceProvider = Provider<OrganizationFinanceService>(
  (ref) => OrganizationFinanceService(),
);

final organizationFinanceProvider = FutureProvider<OrganizationFinanceSummary>((ref) async {
  return ref.read(organizationFinanceServiceProvider).getSummary();
});
