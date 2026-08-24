import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/organization_finance_provider.dart';
import '../models/organization_finance.dart';
import '../services/organization_finance_service.dart';

class OrganizationMoneyDetailsScreen extends ConsumerWidget {
  const OrganizationMoneyDetailsScreen({super.key});

  String money(double value) => '₹${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(organizationFinanceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(organizationFinanceProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      backgroundColor: const Color(0xffF5F7FB),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load money details.\n$e'),
          ),
        ),
        data: (s) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(organizationFinanceProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Detailed Financial Activity',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'This screen focuses on money movement and outstanding amounts. '
                'Use Maintenance for creating periods, bills, expenses and maintenance operations.',
                style: TextStyle(color: Color(0xff64748B)),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metric('Total billed', money(s.maintenanceBilledTotal)),
                  _metric('Collected', money(s.maintenanceCollectedTotal)),
                  _metric('Outstanding', money(s.maintenanceOutstandingTotal)),
                  _metric('Maintenance expenses', money(s.maintenanceExpenseTotal)),
                  _metric('Community collected', money(s.communityCollectedTotal)),
                  _metric('Community expenses', money(s.communityExpenseTotal)),
                  _metric('Community balance', money(s.communityBalance)),
                ],
              ),
              const SizedBox(height: 24),
              FutureBuilder<List<MoneyTransaction>>(
                future: OrganizationFinanceService().getMoneyDetails(),
                builder: (context, tx) {
                  if (tx.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (tx.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text('Unable to load individual transactions. ${tx.error}'),
                      ),
                    );
                  }
                  final rows = tx.data ?? const <MoneyTransaction>[];
                  return _panel(
                    title: 'Recent Money Transactions & Dues',
                    icon: Icons.receipt_long_rounded,
                    child: rows.isEmpty
                        ? const Text('No individual money transactions or dues yet.')
                        : Column(
                            children: rows.take(100).map((row) {
                              final expense = row.kind == 'COMMUNITY_EXPENSE';
                              final due = row.kind == 'MAINTENANCE_DUE';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  child: Icon(
                                    expense
                                        ? Icons.arrow_upward_rounded
                                        : due
                                            ? Icons.pending_actions
                                            : Icons.arrow_downward_rounded,
                                  ),
                                ),
                                title: Text(row.title),
                                subtitle: Text(
                                  '${row.payerOrCategory}'
                                  '${row.blockName == null ? '' : ' • ${row.blockName}'}'
                                  '${row.unitNumber == null ? '' : ' • Unit ${row.unitNumber}'}'
                                  '\n${row.status}'
                                  '${row.paymentMethod == null ? '' : ' • ${row.paymentMethod}'}'
                                  '${row.reference == null ? '' : ' • ${row.reference}'}',
                                ),
                                isThreeLine: true,
                                trailing: Text(
                                  '${expense ? '-' : due ? '' : '+'}₹${row.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: expense
                                        ? Colors.red
                                        : due
                                            ? Colors.orange
                                            : Colors.green,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _panel(
                title: 'Collections by Block',
                icon: Icons.apartment_rounded,
                child: s.maintenanceSections.isEmpty
                    ? const Text('No maintenance financial records yet.')
                    : Column(
                        children: s.maintenanceSections.map((row) {
                          final progress = row.totalBills == 0
                              ? 0.0
                              : row.paidBills / row.totalBills;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              row.sectionName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${row.paidBills}/${row.totalBills} paid • '
                              '${row.pendingBills} pending',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  money(row.collectedTotal),
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}% collected',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xff64748B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _panel(
                title: 'Community Fund Money',
                icon: Icons.account_balance_wallet_rounded,
                child: s.communityFunds.isEmpty
                    ? const Text('No community fund activity yet.')
                    : Column(
                        children: s.communityFunds.map((fund) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              fund.title,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${fund.contributorCount} contributors • '
                              '${fund.pendingHouseholds} pending',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Collected ${money(fund.collectedAmount)}'),
                                Text(
                                  'Balance ${money(fund.balance)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String title, String value) => Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xff64748B), fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _panel({required String title, required IconData icon, required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: const Color(0xff4F46E5)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}
