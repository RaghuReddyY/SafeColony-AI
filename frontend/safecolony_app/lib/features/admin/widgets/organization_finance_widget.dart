import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/organization_finance.dart';

class OrganizationFinanceWidget extends StatelessWidget {
  final AsyncValue<OrganizationFinanceSummary> state;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenMaintenance;
  final VoidCallback? onOpenCommunityFinance;

  const OrganizationFinanceWidget({
    super.key,
    required this.state,
    this.onRetry,
    this.onOpenMaintenance,
    this.onOpenCommunityFinance,
  });

  String _money(double value) {
    return '₹${value.toStringAsFixed(0)}';
  }

  String _month(DateTime? date) {
    if (date == null) return 'No period';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PUBLISHED':
        return const Color(0xff059669);
      case 'CLOSED':
        return const Color(0xff64748B);
      default:
        return const Color(0xffD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xffE2E8F0)),
        ),
        child: const CircularProgressIndicator(),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xffFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Color(0xffDC2626)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Finance summary could not be loaded. Your existing finance screens are still available.',
                style: TextStyle(color: Color(0xff475569)),
              ),
            ),
            if (onRetry != null)
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
      data: (summary) => _content(summary),
    );
  }

  Widget _content(OrganizationFinanceSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _totals(summary),
        const SizedBox(height: 16),
        _maintenance(summary),
        const SizedBox(height: 16),
        _community(summary),
      ],
    );
  }

  Widget _totals(OrganizationFinanceSummary s) {
    final cards = [
      _Metric('Maintenance collected', _money(s.maintenanceCollectedTotal), Icons.payments_rounded, const Color(0xff059669)),
      _Metric('Maintenance pending', _money(s.maintenanceOutstandingTotal), Icons.pending_actions_rounded, const Color(0xffD97706)),
      _Metric('Community collected', _money(s.communityCollectedTotal), Icons.volunteer_activism_rounded, const Color(0xff7C3AED)),
      _Metric('Community balance', _money(s.communityBalance), Icons.account_balance_wallet_rounded, const Color(0xff2563EB)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050 ? 4 : constraints.maxWidth >= 650 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((m) => SizedBox(width: width, child: _metricCard(m))).toList(),
        );
      },
    );
  }

  Widget _metricCard(_Metric metric) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: metric.color.withValues(alpha: .10),
            foregroundColor: metric.color,
            child: Icon(metric.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metric.title, style: const TextStyle(color: Color(0xff64748B), fontSize: 12)),
                const SizedBox(height: 3),
                Text(metric.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _maintenance(OrganizationFinanceSummary s) {
    return _panel(
      title: 'Monthly Maintenance — All Blocks',
      icon: Icons.apartment_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.maintenanceSections.isEmpty)
            const Text('No maintenance period has been created yet.', style: TextStyle(color: Color(0xff64748B)))
          else
            ...s.maintenanceSections.map((row) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xffF8FAFC), borderRadius: BorderRadius.circular(14)),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.sectionName, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text('${_month(row.month)} • ${row.paidBills}/${row.totalBills} paid', style: const TextStyle(color: Color(0xff64748B), fontSize: 12)),
                      ],
                    );
                    final metrics = Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        _smallMetric('Collected', _money(row.collectedTotal)),
                        _smallMetric('Expenses', _money(row.expenseTotal)),
                        _smallMetric('Pending', _money(row.outstandingTotal)),
                      ],
                    );
                    if (constraints.maxWidth < 650) {
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [details, const SizedBox(height: 12), metrics]);
                    }
                    return Row(children: [Expanded(child: details), const SizedBox(width: 12), Expanded(child: metrics)]);
                  },
                ),
              );
            }),
          if (onOpenMaintenance != null)
            OutlinedButton.icon(
              onPressed: onOpenMaintenance,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Open Maintenance Details'),
            ),
        ],
      ),
    );
  }

  Widget _community(OrganizationFinanceSummary s) {
    return _panel(
      title: 'Community Funds — All Blocks',
      icon: Icons.volunteer_activism_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.communityFunds.isEmpty)
            const Text(
              'No community funds have been created yet.',
              style: TextStyle(color: Color(0xff64748B)),
            )
          else
            ...s.communityFunds.map((fund) {
              final statusColor = _statusColor(fund.status);
              final mandatory = fund.contributionMode == 'FIXED';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xffF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fund.title,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            fund.status,
                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 18,
                      runSpacing: 6,
                      children: [
                        if (fund.targetAmount != null) Text('Target ${_money(fund.targetAmount!)}'),
                        Text('Collected ${_money(fund.collectedAmount)}'),
                        Text('Expenses ${_money(fund.expenseAmount)}'),
                        Text('Balance ${_money(fund.balance)}'),
                        Text('${fund.contributorCount} contributors'),
                        Text(mandatory
                            ? '${fund.pendingHouseholds} households pending'
                            : '${fund.pendingHouseholds} not contributed'),
                      ],
                    ),
                  ],
                ),
              );
            }),
          if (onOpenCommunityFinance != null) ...[
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: onOpenCommunityFinance,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Open Community Finance Details'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _smallMetric(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(color: Color(0xff94A3B8), fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _panel({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xff4F46E5)),
              const SizedBox(width: 9),
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Metric {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _Metric(this.title, this.value, this.icon, this.color);
}
