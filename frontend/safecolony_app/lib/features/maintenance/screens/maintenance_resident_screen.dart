import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/maintenance.dart';
import '../providers/maintenance_provider.dart';

class MaintenanceResidentScreen extends ConsumerWidget {
  const MaintenanceResidentScreen({super.key});

  String _money(double value) {
    return '₹${value.toStringAsFixed(2)}';
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
    final state = ref.watch(
      residentMaintenanceProvider,
    );

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('Maintenance'),
      ),
      body: state.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load maintenance.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        data: (data) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                residentMaintenanceProvider,
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (data.bill == null)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No maintenance bill has been generated yet.',
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
                    (bill) {
                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          title: Text(
                            '${bill.residentName} • '
                            '${_date(bill.dueDate)}',
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(
                              top: 6,
                            ),
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
                      );
                    },
                  ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _currentBill(
    BuildContext context,
    WidgetRef ref,
    MaintenanceBill bill,
  ) {
    final bool paid = bill.status == 'PAID';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
              '${bill.propertyName ?? ''} '
              '${bill.sectionName ?? ''} '
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
                  onPressed: () {
                    _recordPayment(
                      context,
                      ref,
                      bill,
                    );
                  },
                  icon: const Icon(
                    Icons.payment,
                  ),
                  label: const Text(
                    'Record Payment',
                  ),
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
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
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

  Future<void> _recordPayment(
    BuildContext context,
    WidgetRef ref,
    MaintenanceBill bill,
  ) async {
    final controller = TextEditingController(
      text: bill.balance.toStringAsFixed(2),
    );

    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Record Payment',
          ),
          content: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.trim(),
                );

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              child: const Text(
                'Confirm',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (amount == null || amount <= 0) {
      return;
    }

    try {
      await ref
          .read(maintenanceServiceProvider)
          .recordPayment(
            billId: bill.id,
            amount: amount,
          );

      ref.invalidate(
        residentMaintenanceProvider,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Payment recorded successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

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
}