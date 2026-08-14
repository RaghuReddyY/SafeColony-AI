import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/organization_finance.dart';
import '../providers/organization_finance_provider.dart';

class OrganizationMaintenanceDetailsScreen extends ConsumerWidget {
  const OrganizationMaintenanceDetailsScreen({super.key});

  String _money(double value) {
    return '₹${value.toStringAsFixed(0)}';
  }

  String _month(DateTime? date) {
    if (date == null) return 'No period';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  Color _statusColor(String? status) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final financeAsync = ref.watch(organizationFinanceProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Organization Maintenance',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: financeAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => _errorState(
            context,
            ref,
          ),
          data: (summary) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(organizationFinanceProvider);
              await ref.read(organizationFinanceProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(summary),

                  const SizedBox(height: 18),

                  _organizationTotals(summary),

                  const SizedBox(height: 24),

                  _sectionTitle(
                    'Maintenance by Block',
                    'Organization-wide maintenance collection and expense details',
                    Icons.apartment_rounded,
                  ),

                  const SizedBox(height: 12),

                  if (summary.maintenanceSections.isEmpty)
                    _emptyCard(
                      'No maintenance period has been created yet.',
                    )
                  else
                    ...summary.maintenanceSections.map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _blockCard(section),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(OrganizationFinanceSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xffEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xff4F46E5),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Monthly Maintenance',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (summary.organizationName != null &&
              summary.organizationName!.trim().isNotEmpty)
            Text(
              summary.organizationName!,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xff334155),
              ),
            ),

          if (summary.organizationCode != null &&
              summary.organizationCode!.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              'ORG: ${summary.organizationCode!}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xff94A3B8),
              ),
            ),
          ],

          const SizedBox(height: 8),

          const Text(
            'Consolidated maintenance information across all blocks',
            style: TextStyle(
              color: Color(0xff64748B),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _organizationTotals(
    OrganizationFinanceSummary summary,
  ) {
    final cards = [
      _Metric(
        'Total billed',
        _money(summary.maintenanceBilledTotal),
        Icons.receipt_long_rounded,
      ),
      _Metric(
        'Collected',
        _money(summary.maintenanceCollectedTotal),
        Icons.payments_rounded,
      ),
      _Metric(
        'Expenses',
        _money(summary.maintenanceExpenseTotal),
        Icons.account_balance_wallet_rounded,
      ),
      _Metric(
        'Pending',
        _money(summary.maintenanceOutstandingTotal),
        Icons.pending_actions_rounded,
      ),
      _Metric(
        'Balance',
        _money(summary.maintenanceBalance),
        Icons.balance_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 750
                ? 3
                : 2;

        final width =
            (constraints.maxWidth - ((columns - 1) * 12)) /
                columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: _metricCard(metric),
                ),
              )
              .toList(),
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
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            metric.icon,
            color: const Color(0xff4F46E5),
          ),
          const SizedBox(height: 12),
          Text(
            metric.title,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xff4F46E5),
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xff64748B),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _blockCard(
    MaintenanceSectionSummary section,
  ) {
    final paidRatio = section.totalBills == 0
        ? 0.0
        : section.paidBills / section.totalBills;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xffEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: Color(0xff4F46E5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.sectionName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_month(section.month)} • '
                      '${section.paidBills}/${section.totalBills} paid',
                      style: const TextStyle(
                        color: Color(0xff64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (section.status != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(section.status)
                        .withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    section.status!,
                    style: TextStyle(
                      color: _statusColor(section.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: paidRatio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xffE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xff059669),
              ),
            ),
          ),

          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final items = [
                _BlockMetric(
                  'Billed',
                  _money(section.billedTotal),
                ),
                _BlockMetric(
                  'Collected',
                  _money(section.collectedTotal),
                ),
                _BlockMetric(
                  'Expenses',
                  _money(section.expenseTotal),
                ),
                _BlockMetric(
                  'Pending',
                  _money(section.outstandingTotal),
                ),
                _BlockMetric(
                  'Balance',
                  _money(section.balance),
                ),
              ];

              final columns = constraints.maxWidth >= 900
                  ? 5
                  : constraints.maxWidth >= 600
                      ? 3
                      : 2;

              final width =
                  (constraints.maxWidth -
                      ((columns - 1) * 10)) /
                  columns;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: width,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xffF8FAFC),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Color(0xff94A3B8),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(
                Icons.people_alt_outlined,
                size: 18,
                color: Color(0xff64748B),
              ),
              const SizedBox(width: 7),
              Text(
                '${section.paidBills} paid',
                style: const TextStyle(
                  color: Color(0xff475569),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 18),
              Text(
                '${section.pendingBills} pending',
                style: const TextStyle(
                  color: Color(0xff475569),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xff64748B),
        ),
      ),
    );
  }

  Widget _errorState(
    BuildContext context,
    WidgetRef ref,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xffDC2626),
            ),
            const SizedBox(height: 12),
            const Text(
              'Maintenance details could not be loaded.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () {
                ref.invalidate(
                  organizationFinanceProvider,
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric {
  final String title;
  final String value;
  final IconData icon;

  const _Metric(
    this.title,
    this.value,
    this.icon,
  );
}

class _BlockMetric {
  final String title;
  final String value;

  const _BlockMetric(
    this.title,
    this.value,
  );
}