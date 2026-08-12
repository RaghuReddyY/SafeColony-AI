import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/maintenance_provider.dart';

class CommunityFinanceScreen extends ConsumerWidget {
  const CommunityFinanceScreen({super.key});

  String _money(double value) {
    return '₹${value.toStringAsFixed(0)}';
  }

  String _month(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final financeAsync =
        ref.watch(communityFinanceProvider);

    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Community Finance',
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),

      body: financeAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons
                        .account_balance_wallet_outlined,
                    size: 56,
                    color: Color(0xff64748B),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const Text(
                    'Unable to load community finance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    error.toString(),
                    textAlign:
                        TextAlign.center,
                    style: const TextStyle(
                      color:
                          Color(0xff64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(
                        communityFinanceProvider,
                      );
                    },
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    label:
                        const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },

        data: (data) {
          final period = data.period;

          if (period == null) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  communityFinanceProvider,
                );
                await ref.read(
                  communityFinanceProvider
                      .future,
                );
              },
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(24),
                children: [
                  const SizedBox(
                    height: 120,
                  ),
                  Icon(
                    Icons
                        .account_balance_wallet_outlined,
                    size: 70,
                    color:
                        Colors.grey.shade400,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    'No financial period created yet.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  const Text(
                    'Once the administrator creates the monthly maintenance period, the community financial summary will appear here.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          Color(0xff64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                communityFinanceProvider,
              );

              await ref.read(
                communityFinanceProvider
                    .future,
              );
            },

            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding:
                  const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                32,
              ),

              children: [
                // ==================================================
                // MONTH HEADER
                // ==================================================

                _monthHeader(period),

                const SizedBox(
                  height: 18,
                ),

                // ==================================================
                // FINANCIAL SUMMARY
                // ==================================================

                _summaryCard(period),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // COLLECTION SUMMARY
                // ==================================================

                _collectionCard(period),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // EXPENSES
                // ==================================================

                const Text(
                  'Community Expenses',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xff0F172A),
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                const Text(
                  'How community funds were spent this month',
                  style: TextStyle(
                    color:
                        Color(0xff64748B),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                if (data.expenses.isEmpty)
                  _emptyExpenses()
                else
                  ...data.expenses.map(
                    (expense) =>
                        _expenseCard(
                      expense,
                    ),
                  ),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // TRANSPARENCY NOTE
                // ==================================================

                _transparencyCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // MONTH HEADER
  // ================================================================

  Widget _monthHeader(
    dynamic period,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(22),

      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xff312E81),
            Color(0xff4F46E5),
          ],
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color:
                Colors.indigo.withValues(
              alpha: .18,
            ),
            blurRadius: 18,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,

            decoration:
                BoxDecoration(
              color:
                  Colors.white.withValues(
                alpha: .15,
              ),
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),

            child: const Icon(
              Icons
                  .account_balance_wallet_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Community Finance',
                  style: TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  _month(period.month),
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SUMMARY CARD
  // ================================================================

  Widget _summaryCard(
    dynamic period,
  ) {
    return Card(
      elevation: 0,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(22),
        side: const BorderSide(
          color:
              Color(0xffE2E8F0),
        ),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Financial Summary',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(0xff0F172A),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            _summaryRow(
              'Opening Balance',
              _money(
                period.openingBalance,
              ),
              Icons
                  .account_balance_outlined,
              const Color(0xff2563EB),
            ),

            _summaryRow(
              'Maintenance Collected',
              _money(
                period.collectedTotal,
              ),
              Icons
                  .payments_outlined,
              const Color(0xff059669),
            ),

            _summaryRow(
              'Expenses',
              _money(
                period.expenseTotal,
              ),
              Icons
                  .trending_down_rounded,
              const Color(0xffEA580C),
            ),

            const Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: Divider(),
            ),

            _summaryRow(
              'Current Balance',
              _money(
                period.closingBalance,
              ),
              Icons
                  .account_balance_rounded,
              const Color(0xff16A34A),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // SUMMARY ROW
  // ================================================================

  Widget _summaryRow(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool bold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration:
                BoxDecoration(
              color:
                  color.withValues(
                alpha: .10,
              ),

              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),

            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize:
                    bold ? 15 : 14,
                fontWeight: bold
                    ? FontWeight.w700
                    : FontWeight.w500,
                color:
                    const Color(
                  0xff334155,
                ),
              ),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              fontSize:
                  bold ? 21 : 15,
              fontWeight: bold
                  ? FontWeight.w800
                  : FontWeight.w700,
              color: bold
                  ? color
                  : const Color(
                      0xff0F172A,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // COLLECTION CARD
  // ================================================================

  Widget _collectionCard(
    dynamic period,
  ) {
    final total =
        period.totalBills;

    final paid =
        period.paidBills;

    final unpaid =
        period.unpaidBills;

    final paidPercentage =
        total == 0
            ? 0.0
            : paid / total;

    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration:
          BoxDecoration(
        color:
            const Color(0xffECFDF5),

        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color:
              const Color(0xffBBF7D0),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Icon(
                Icons
                    .pie_chart_rounded,
                color:
                    Color(0xff059669),
              ),

              const SizedBox(
                width: 10,
              ),

              const Expanded(
                child: Text(
                  'Maintenance Collection',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xff14532D),
                  ),
                ),
              ),

              Text(
                '${(paidPercentage * 100).toStringAsFixed(0)}%',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xff059669),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              10,
            ),

            child:
                LinearProgressIndicator(
              value:
                  paidPercentage,
              minHeight: 10,
              backgroundColor:
                  const Color(
                0xffD1FAE5,
              ),
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                Color(0xff059669),
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _collectionMetric(
                  'Total Bills',
                  '$total',
                ),
              ),

              Expanded(
                child:
                    _collectionMetric(
                  'Paid',
                  '$paid',
                ),
              ),

              Expanded(
                child:
                    _collectionMetric(
                  'Pending',
                  '$unpaid',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _collectionMetric(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style:
              const TextStyle(
            fontSize: 19,
            fontWeight:
                FontWeight.w800,
            color:
                Color(0xff14532D),
          ),
        ),

        const SizedBox(
          height: 2,
        ),

        Text(
          label,
          style:
              const TextStyle(
            fontSize: 11,
            color:
                Color(0xff64748B),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // EXPENSE CARD
  // ================================================================

  Widget _expenseCard(
    dynamic expense,
  ) {
    return Card(
      elevation: 0,

      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),

        side: const BorderSide(
          color:
              Color(0xffE2E8F0),
        ),
      ),

      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),

        leading: Container(
          width: 46,
          height: 46,

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xffFFF7ED,
            ),

            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),

          child: const Icon(
            Icons.receipt_long_rounded,
            color:
                Color(0xffEA580C),
          ),
        ),

        title: Text(
          expense.category,

          style:
              const TextStyle(
            fontWeight:
                FontWeight.w800,
            color:
                Color(0xff0F172A),
          ),
        ),

        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 5,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              if (expense
                  .description
                  .toString()
                  .isNotEmpty)
                Text(
                  expense.description,

                  maxLines: 2,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    color:
                        Color(0xff64748B),
                    fontSize: 12,
                  ),
                ),

              const SizedBox(
                height: 3,
              ),

              Text(
                _date(
                  expense.spentOn,
                ),

                style:
                    const TextStyle(
                  color:
                      Color(0xff94A3B8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        trailing: Text(
          _money(
            expense.amount,
          ),

          style:
              const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w800,
            color:
                Color(0xffEA580C),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // EMPTY EXPENSES
  // ================================================================

  Widget _emptyExpenses() {
    return Card(
      elevation: 0,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),

        side: const BorderSide(
          color:
              Color(0xffE2E8F0),
        ),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 46,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'No expenses recorded',
              style: TextStyle(
                fontWeight:
                    FontWeight.w700,
                fontSize: 16,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            const Text(
              'No community expenses have been recorded for this period.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Color(0xff64748B),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // TRANSPARENCY
  // ================================================================

  Widget _transparencyCard() {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color:
            const Color(0xffEFF6FF),

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color:
              const Color(0xffBFDBFE),
        ),
      ),

      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.visibility_rounded,
            color:
                Color(0xff2563EB),
          ),

          SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              'Community-level collections, expenses and balance are visible to residents and security. Individual resident payment details remain private.',
              style: TextStyle(
                color:
                    Color(0xff334155),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}