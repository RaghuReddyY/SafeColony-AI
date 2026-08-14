import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/maintenance.dart';
import '../providers/maintenance_provider.dart';
import 'community_finance_screen.dart';

class MaintenanceResidentScreen extends ConsumerStatefulWidget {
  const MaintenanceResidentScreen({super.key});

  @override
  ConsumerState<MaintenanceResidentScreen> createState() =>
      _MaintenanceResidentScreenState();
}

class _MaintenanceResidentScreenState
    extends ConsumerState<MaintenanceResidentScreen> {
  String _money(double value) => '₹${value.toStringAsFixed(2)}';

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  @override
  void initState() {
    super.initState();

    // IMPORTANT:
    // Maintenance data is resident-specific.
    //
    // If another resident was previously logged in using the same
    // ProviderContainer, make sure we don't display that resident's
    // cached maintenance data.
    Future.microtask(() {
      if (mounted) {
        ref.invalidate(residentMaintenanceProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(residentMaintenanceProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('Maintenance'),
      ),
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load maintenance.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(residentMaintenanceProvider);
            await ref.read(residentMaintenanceProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.account_balance),
                  ),
                  title: const Text(
                    'Community Finance',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'View the community balance, maintenance collections and expenses.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CommunityFinanceScreen(),
                      ),
                    );
                  },
                ),
              ),

              if (data.bill == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      data.isPrimary
                          ? 'No maintenance bill has been generated yet.'
                          : 'Maintenance is managed by the primary resident of this unit. No separate maintenance bill is assigned to family members.',
                    ),
                  ),
                )
              else
                _currentBill(
                  context,
                  ref,
                  data.bill!,
                ),

              const SizedBox(height: 24),

              const Text(
                'Payment History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (data.history.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No payment history available.',
                    ),
                  ),
                )
              else
                ...data.history.map(
                  (bill) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        '${bill.residentName} • ${_date(bill.dueDate)}',
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Due ${_money(bill.totalDue)}\n'
                          'Paid ${_money(bill.amountPaid)}\n'
                          'Balance ${_money(bill.balance)}',
                        ),
                      ),
                      trailing: Text(
                        bill.status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: bill.status == 'PAID'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _currentBill(
    BuildContext context,
    WidgetRef ref,
    MaintenanceBill bill,
  ) {
    final paid = bill.status == 'PAID';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Maintenance Bill',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              '${bill.propertyName ?? ''} ${bill.sectionName ?? ''} '
              '• Unit ${bill.unitNumber ?? ''}',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            _row(
              'Maintenance',
              _money(bill.amount),
            ),

            _row(
              'Carry Forward',
              _money(bill.carriedForward),
            ),

            _row(
              'Late Fee',
              _money(bill.lateFee),
            ),

            const Divider(height: 24),

            _row(
              'Total Due',
              _money(bill.totalDue),
              bold: true,
            ),

            _row(
              'Paid',
              _money(bill.amountPaid),
            ),

            _row(
              'Outstanding',
              _money(bill.balance),
              bold: true,
            ),

            const SizedBox(height: 12),

            Text(
              'Due date: ${_date(bill.dueDate)}',
            ),

            const SizedBox(height: 20),

            if (!paid)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _startPayment(
                    context,
                    ref,
                    bill,
                  ),
                  icon: const Icon(Icons.payment),
                  label: const Text('Make Payment'),
                ),
              )
            else
              const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'PAID',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
  }) {
    final style = bold
        ? const TextStyle(
            fontWeight: FontWeight.bold,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: style,
          ),
          Text(
            value,
            style: style,
          ),
        ],
      ),
    );
  }

  Future<void> _startPayment(
    BuildContext context,
    WidgetRef ref,
    MaintenanceBill bill,
  ) async {
    try {
      final result = await ref
          .read(maintenanceServiceProvider)
          .createOnlinePayment(bill.id);

      final mode = result['mode']?.toString() ?? 'RAZORPAY';

      if (mode == 'DIRECT_UPI') {
        await _showDirectUPIPayment(
          context,
          ref,
          bill,
          result,
        );
        return;
      }

      final url = result['payment_url']?.toString();

      if (url == null || url.isEmpty) {
        throw Exception(
          'Payment link was not returned by the server.',
        );
      }

      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception(
          'Unable to open the payment page.',
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Complete the payment. SafeColony will mark the bill PAID only after the payment gateway confirms it.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Payment failed: $e',
          ),
        ),
      );
    }
  }

  Future<void> _showDirectUPIPayment(
    BuildContext context,
    WidgetRef ref,
    MaintenanceBill bill,
    Map<String, dynamic> result,
  ) async {
    final upiId = result['upi_id']?.toString() ?? '';
    final displayName =
        result['display_name']?.toString() ?? 'Maintenance';
    final paymentPhone =
        result['payment_phone']?.toString();
    final upiUrl =
        result['payment_url']?.toString() ?? '';

    final controller = TextEditingController();

    try {
      final action = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Pay using UPI',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount: ${_money(bill.balance)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Pay to: $displayName',
                ),

                const SizedBox(height: 4),

                SelectableText(
                  upiId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (paymentPhone != null &&
                    paymentPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Phone: $paymentPhone',
                  ),
                ],

                const SizedBox(height: 16),

                const Text(
                  'Tap Open UPI App. After completing the transfer, enter the UPI transaction reference/UTR below and submit it for administrator verification.',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText:
                        'UPI transaction reference / UTR',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: upiId,
                      ),
                    );

                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'UPI ID copied.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text(
                    'Copy UPI ID',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
              ),
            ),

            OutlinedButton.icon(
              onPressed: upiUrl.isEmpty
                  ? null
                  : () async {
                      final launched =
                          await launchUrl(
                        Uri.parse(upiUrl),
                        mode: LaunchMode
                            .externalApplication,
                      );

                      if (!launched &&
                          dialogContext.mounted) {
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No UPI app could be opened. Copy the UPI ID and pay manually.',
                            ),
                          ),
                        );
                      }
                    },
              icon: const Icon(
                Icons.account_balance_wallet,
              ),
              label: const Text(
                'Open UPI App',
              ),
            ),

            FilledButton(
              onPressed: () {
                if (controller.text.trim().length < 4) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter the UPI transaction reference/UTR.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text(
                'Submit Payment',
              ),
            ),
          ],
        ),
      );

      if (action == null ||
          action.isEmpty ||
          !context.mounted) {
        return;
      }

      final submission = await ref
          .read(maintenanceServiceProvider)
          .submitDirectUPIPayment(
            billId: bill.id,
            amount: bill.balance,
            reference: action,
          );

      // Refresh resident-specific data only.
      ref.invalidate(
        residentMaintenanceProvider,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            submission.message,
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}