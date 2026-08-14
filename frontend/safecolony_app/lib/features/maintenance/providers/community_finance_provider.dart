import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community_finance.dart';
import '../services/community_finance_service.dart';

final communityFinanceServiceProvider = Provider<CommunityFinanceService>((ref) => CommunityFinanceService());

final communityFinanceDashboardProvider = FutureProvider.autoDispose<CommunityFinanceDashboard>((ref) {
  return ref.read(communityFinanceServiceProvider).getDashboard();
});
