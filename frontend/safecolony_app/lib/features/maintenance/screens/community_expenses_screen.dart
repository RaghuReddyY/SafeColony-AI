import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/community_finance.dart';
import '../providers/community_finance_provider.dart';

/// Read-only community expense view backed by the existing Community Finance API.
class CommunityExpensesScreen extends ConsumerWidget {
  const CommunityExpensesScreen({super.key});

  String _money(double value) => '₹${value.toStringAsFixed(2)}';

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-${value.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityFinanceDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('Community Expenses'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 56),
                const SizedBox(height: 12),
                const Text(
                  'Unable to load community expenses',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(communityFinanceDashboardProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final rows = <_ExpenseRow>[];
          for (final fund in data.funds) {
            for (final expense in fund.expenses) {
              rows.add(_ExpenseRow(fund: fund, expense: expense));
            }
          }
          rows.sort(
            (a, b) => b.expense.spentOn.compareTo(a.expense.spentOn),
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(communityFinanceDashboardProvider);
              await ref.read(communityFinanceDashboardProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.account_balance_wallet_outlined),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total community expenses',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _money(data.totalExpenses),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${rows.length} expense${rows.length == 1 ? '' : 's'} across '
                                '${data.funds.length} collection${data.funds.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  color: Color(0xff64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (rows.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 60,
                            color: Color(0xff94A3B8),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No community expenses yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Published community collection expenses will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xff64748B)),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...rows.map(
                    (row) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.receipt_long_outlined),
                        ),
                        title: Text(
                          row.expense.description,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            '${row.expense.category} • ${_date(row.expense.spentOn)}\n'
                            'Collection: ${row.fund.title}',
                          ),
                        ),
                        trailing: Text(
                          _money(row.expense.amount),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ExpenseRow {
  final CommunityFund fund;
  final CommunityExpense expense;

  const _ExpenseRow({
    required this.fund,
    required this.expense,
  });
}
