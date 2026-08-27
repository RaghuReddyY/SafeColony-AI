import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/maintenance.dart';
import '../providers/maintenance_provider.dart';

class MaintenanceAdminScreen extends ConsumerStatefulWidget {
  const MaintenanceAdminScreen({super.key});

  @override
  ConsumerState<MaintenanceAdminScreen> createState() => _MaintenanceAdminScreenState();
}

class _MaintenanceAdminScreenState extends ConsumerState<MaintenanceAdminScreen> {
  final _amountController = TextEditingController();
  final _expenseCategoryController = TextEditingController();
  final _expenseDescriptionController = TextEditingController();
  final _expenseAmountController = TextEditingController();
  final _upiController = TextEditingController();
  final _paymentNameController = TextEditingController();
  final _paymentPhoneController = TextEditingController();
  final _lateFeeValueController = TextEditingController();
  String _paymentMode = 'RAZORPAY';
  String _lateFeeType = 'NONE';
  int _lateFeeGraceDays = 0;
  bool _paymentSettingsLoaded = false;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _dueDate = DateTime(DateTime.now().year, DateTime.now().month, 10);
  DateTime _spentOn = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _amountController.dispose();
    _expenseCategoryController.dispose();
    _expenseDescriptionController.dispose();
    _expenseAmountController.dispose();
    _upiController.dispose();
    _paymentNameController.dispose();
    _paymentPhoneController.dispose();
    _lateFeeValueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool month}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: month ? _month : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (month) {
        _month = DateTime(picked.year, picked.month, 1);
      } else {
        _dueDate = picked;
      }
    });
  }

  Future<void> _createPeriod() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _snack('Enter a valid maintenance amount.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(maintenanceServiceProvider).createPeriod(
            month: _month,
            monthlyAmount: amount,
            dueDate: _dueDate,
          );
      if (!mounted) return;
      _snack('Maintenance period created.');
      ref.invalidate(maintenanceDashboardProvider);
      _amountController.clear();
    } catch (e) {
      _snack('Unable to create period: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editPeriod(MaintenancePeriod period) async {
    if (period.status != 'DRAFT') {
      _snack('Only a draft maintenance period can be edited.');
      return;
    }

    final amountController = TextEditingController(
      text: period.monthlyAmount.toStringAsFixed(2),
    );
    final notesController = TextEditingController(text: period.notes ?? '');
    DateTime dueDate = period.dueDate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit Maintenance Period'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Billing month: ${_monthLabel(period.month)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monthly maintenance amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: dueDate,
                      firstDate: period.month,
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => dueDate = picked);
                    }
                  },
                  child: Text('Due date: ${_date(dueDate)}'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'The billing month is fixed after creation. Once bills are published, the period is locked.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );

    final amount = double.tryParse(amountController.text.trim());
    final notes = notesController.text.trim();
    amountController.dispose();
    notesController.dispose();

    if (saved != true || amount == null || amount <= 0) {
      if (saved == true) _snack('Enter a valid maintenance amount.');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(maintenanceServiceProvider).updatePeriod(
            periodId: period.id,
            monthlyAmount: amount,
            dueDate: dueDate,
            notes: notes.isEmpty ? null : notes,
          );
      if (!mounted) return;
      ref.invalidate(maintenanceDashboardProvider);
      _snack('Maintenance period updated.');
    } catch (e) {
      if (mounted) _snack('Unable to update maintenance period: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deletePeriod(MaintenancePeriod period) async {
    if (period.status != 'DRAFT') {
      _snack('Only a draft maintenance period can be deleted.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete maintenance period?'),
        content: Text(
          'Delete ${_monthLabel(period.month)}? This is allowed only before bills or expenses are created.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Period'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(maintenanceServiceProvider).deletePeriod(period.id);
      if (!mounted) return;
      ref.invalidate(maintenanceDashboardProvider);
      _snack('Maintenance period deleted.');
    } catch (e) {
      if (mounted) _snack('Unable to delete maintenance period: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generateBills(MaintenancePeriod period) async {
    setState(() => _busy = true);
    try {
      final result = await ref.read(maintenanceServiceProvider).generateBills(period.id);
      if (!mounted) return;
      _snack('${result['created'] ?? 0} bills created.');
      ref.invalidate(maintenanceDashboardProvider);
    } catch (e) {
      _snack('Unable to generate bills: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _closePeriod(MaintenancePeriod period) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Close maintenance period?'),
        content: const Text('Closing locks bill edits and deletes for this period. Payments already recorded remain unchanged.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Close Period')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(maintenanceServiceProvider).closePeriod(period.id);
      if (!mounted) return;
      ref.invalidate(maintenanceDashboardProvider);
      _snack('Maintenance period closed.');
    } catch (e) {
      _snack('Unable to close period: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addExpense(MaintenancePeriod period) async {
    final amount = double.tryParse(_expenseAmountController.text.trim());
    if (_expenseCategoryController.text.trim().isEmpty ||
        _expenseDescriptionController.text.trim().isEmpty ||
        amount == null || amount <= 0) {
      _snack('Enter category, description and a valid amount.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(maintenanceServiceProvider).addExpense(
            periodId: period.id,
            category: _expenseCategoryController.text.trim(),
            description: _expenseDescriptionController.text.trim(),
            amount: amount,
            spentOn: _spentOn,
          );
      if (!mounted) return;
      _snack('Expense added.');
      ref.invalidate(maintenanceDashboardProvider);
      _expenseCategoryController.clear();
      _expenseDescriptionController.clear();
      _expenseAmountController.clear();
    } catch (e) {
      _snack('Unable to add expense: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  Future<void> _editExpense(MaintenanceExpense expense) async {
    final category = TextEditingController(text: expense.category);
    final description = TextEditingController(text: expense.description);
    final amount = TextEditingController(text: expense.amount.toStringAsFixed(2));
    DateTime spentOn = expense.spentOn;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Expense'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
                const SizedBox(height: 12),
                TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Spent on: ${_date(spentOn)}')),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: spentOn,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setDialogState(() => spentOn = picked);
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save Changes')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    try {
      final value = double.tryParse(amount.text.trim());
      if (value == null || value <= 0) throw Exception('Enter a valid amount.');
      await ref.read(maintenanceServiceProvider).updateExpense(
        expenseId: expense.id,
        category: category.text,
        description: description.text,
        amount: value,
        spentOn: spentOn,
      );
      ref.invalidate(maintenanceDashboardProvider);
      if (mounted) _snack('Expense updated.');
    } catch (e) {
      if (mounted) _snack('Unable to update expense: $e');
    } finally {
      category.dispose(); description.dispose(); amount.dispose();
    }
  }

  Future<void> _editBill(MaintenanceBill bill) async {
    final amountController = TextEditingController(text: bill.amount.toStringAsFixed(2));
    DateTime dueDate = bill.dueDate;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text('Edit bill - ${bill.residentName}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Maintenance amount', prefixText: '₹ ', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () async {
            final picked = await showDatePicker(context: context, initialDate: dueDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
            if (picked != null) setDialogState(() => dueDate = picked);
          }, child: Text('Due date: ${_date(dueDate)}')),
          const SizedBox(height: 8),
          const Text('Only unpaid bills can be edited. Bills with any payment are locked to preserve financial history.', style: TextStyle(color: Colors.black54)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save Changes')),
        ],
      )),
    );
    final amount = double.tryParse(amountController.text.trim());
    amountController.dispose();
    if (result != true || amount == null || amount <= 0) return;
    setState(() => _busy = true);
    try {
      await ref.read(maintenanceServiceProvider).updateBill(billId: bill.id, amount: amount, dueDate: dueDate);
      if (!mounted) return;
      _snack('Bill updated.');
      ref.invalidate(maintenanceDashboardProvider);
    } catch (e) {
      _snack('Unable to update bill: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteBill(MaintenanceBill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete bill?'),
        content: Text('Delete the unpaid bill for ${bill.residentName}? The resident will no longer see this generated bill.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(maintenanceServiceProvider).deleteBill(bill.id);
      if (!mounted) return;
      _snack('Bill deleted.');
      ref.invalidate(maintenanceDashboardProvider);
    } catch (e) {
      _snack('Unable to delete bill: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recordAdminPayment(MaintenanceBill bill) async {
    if (bill.balance <= 0) return;
    final controller = TextEditingController(text: bill.balance.toStringAsFixed(2));
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Record payment - ${bill.residentName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text.trim())), child: const Text('Record')),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || amount <= 0) return;
    setState(() => _busy = true);
    try {
      await ref.read(maintenanceServiceProvider).recordPayment(
        billId: bill.id,
        amount: amount,
        paymentMethod: 'MANUAL',
      );
      if (!mounted) return;
      _snack('Payment recorded for ${bill.residentName}.');
      ref.invalidate(maintenanceDashboardProvider);
    } catch (e) {
      _snack('Unable to record payment: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  Future<void> _loadPaymentSettings() async {
    if (_paymentSettingsLoaded) return;
    try {
      final settings = await ref
          .read(maintenanceServiceProvider)
          .getPaymentSettings();
      if (!mounted) return;
      setState(() {
        _paymentMode = settings.mode;
        _upiController.text = settings.upiId ?? '';
        _paymentNameController.text = settings.displayName ?? '';
        _paymentPhoneController.text = settings.paymentPhone ?? '';
        _lateFeeType = settings.lateFeeType;
        _lateFeeValueController.text = settings.lateFeeValue.toStringAsFixed(2);
        _lateFeeGraceDays = settings.lateFeeGraceDays;
        _paymentSettingsLoaded = true;
      });
    } catch (e) {
      if (mounted) _snack('Unable to load payment settings: $e');
    }
  }

  Future<void> _savePaymentSettings() async {
    if (_paymentMode == 'DIRECT_UPI' &&
        (_upiController.text.trim().isEmpty ||
            !_upiController.text.trim().contains('@') ||
            _paymentNameController.text.trim().isEmpty)) {
      _snack('For Direct UPI, enter a valid UPI ID and display name.');
      return;
    }

    final lateFeeValue = double.tryParse(_lateFeeValueController.text.trim()) ?? 0;
    if (lateFeeValue < 0) {
      _snack('Enter a valid late fee value.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(maintenanceServiceProvider).updatePaymentSettings(
            mode: _paymentMode,
            upiId: _upiController.text.trim().isEmpty
                ? null
                : _upiController.text.trim(),
            displayName: _paymentNameController.text.trim().isEmpty
                ? null
                : _paymentNameController.text.trim(),
            paymentPhone: _paymentPhoneController.text.trim().isEmpty
                ? null
                : _paymentPhoneController.text.trim(),
            lateFeeType: _lateFeeType,
            lateFeeValue: lateFeeValue,
            lateFeeGraceDays: _lateFeeGraceDays,
          );
      if (!mounted) return;
      _snack('Payment settings saved.');
      ref.invalidate(maintenancePaymentSettingsProvider);
    } catch (e) {
      _snack('Unable to save payment settings: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyPendingPayment(
    PendingMaintenancePayment payment,
    bool approve,
  ) async {
    setState(() => _busy = true);
    try {
      await ref.read(maintenanceServiceProvider).verifyDirectUPIPayment(
            paymentId: payment.id,
            approve: approve,
          );
      if (!mounted) return;
      _snack(
        approve
            ? 'Payment verified for ${payment.residentName}.'
            : 'Payment rejected.',
      );
      ref.invalidate(pendingMaintenancePaymentsProvider);
      ref.invalidate(maintenanceDashboardProvider);
    } catch (e) {
      _snack('Unable to process payment: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _paymentSettingsCard() {
    final settingsAsync = ref.watch(maintenancePaymentSettingsProvider);
    settingsAsync.whenData((settings) {
      if (!_paymentSettingsLoaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _paymentSettingsLoaded) return;
          setState(() {
            _paymentMode = settings.mode;
            _upiController.text = settings.upiId ?? '';
            _paymentNameController.text = settings.displayName ?? '';
            _paymentPhoneController.text = settings.paymentPhone ?? '';
            _lateFeeType = settings.lateFeeType;
            _lateFeeValueController.text = settings.lateFeeValue.toStringAsFixed(2);
            _lateFeeGraceDays = settings.lateFeeGraceDays;
            _paymentSettingsLoaded = true;
          });
        });
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how residents pay maintenance. Razorpay is automatic; Direct UPI is suitable for communities that collect into a secretary/maintenance person’s PhonePe or Google Pay UPI account. These settings can be changed after bills are published; they affect future payment attempts, while paid bills remain unchanged.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMode,
              decoration: const InputDecoration(
                labelText: 'Payment method',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'RAZORPAY',
                  child: Text('Razorpay / Gateway'),
                ),
                DropdownMenuItem(
                  value: 'DIRECT_UPI',
                  child: Text('Direct UPI (PhonePe / Google Pay)'),
                ),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value != null) setState(() => _paymentMode = value);
                    },
            ),
            if (_paymentMode == 'DIRECT_UPI') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _upiController,
                decoration: const InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'maintenance@upi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _paymentNameController,
                decoration: const InputDecoration(
                  labelText: 'Receiver / maintenance person name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _paymentPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'UPI-linked phone (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 18),
            const Text('Late Fee Policy', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _lateFeeType,
              decoration: const InputDecoration(
                labelText: 'Late fee type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'NONE', child: Text('No late fee')),
                DropdownMenuItem(value: 'FLAT', child: Text('Flat amount')),
                DropdownMenuItem(value: 'PERCENT_PER_MONTH', child: Text('Percentage per month')),
                DropdownMenuItem(value: 'PER_DAY', child: Text('Amount per late day')),
              ],
              onChanged: _busy ? null : (v) { if (v != null) setState(() => _lateFeeType = v); },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lateFeeValueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _lateFeeType == 'PERCENT_PER_MONTH' ? 'Percentage' : 'Late fee value',
                prefixText: _lateFeeType == 'PERCENT_PER_MONTH' ? '' : '₹ ',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _lateFeeGraceDays,
              decoration: const InputDecoration(
                labelText: 'Grace period (days)',
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                31,
                (i) => DropdownMenuItem(value: i, child: Text('$i days')),
              ),
              onChanged: _busy ? null : (v) { if (v != null) setState(() => _lateFeeGraceDays = v); },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _savePaymentSettings,
                icon: const Icon(Icons.save),
                label: const Text('Save Payment Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingPaymentsCard() {
    final pending = ref.watch(pendingMaintenancePaymentsProvider);
    return pending.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text('Unable to load pending UPI payments.\n$e'),
        ),
      ),
      data: (payments) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Direct UPI Verification',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Residents using personal PhonePe/Google Pay accounts submit their UTR here. Verify the transfer before SafeColony marks the bill PAID.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              if (payments.isEmpty)
                const Text('No pending UPI payments.')
              else
                ...payments.map(
                  (payment) => Card(
                    color: const Color(0xffF8FAFC),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${payment.residentName} • ${payment.unitNumber ?? '-'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Amount: ${_money(payment.amount)}\n'
                            'UTR: ${payment.reference ?? '-'}\n'
                            'Bill: #${payment.billId}',
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _verifyPendingPayment(
                                            payment,
                                            false,
                                          ),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _verifyPendingPayment(
                                            payment,
                                            true,
                                          ),
                                  icon: const Icon(Icons.verified),
                                  label: const Text('Verify & Paid'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  String _money(double value) => '₹${value.toStringAsFixed(2)}';
  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  String _monthLabel(DateTime d) => '${_monthName(d.month)} ${d.year}';
  String _monthName(int month) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][month - 1];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maintenanceDashboardProvider);
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(title: const Text('Money Management')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Unable to load money management.\n$e'))),
        data: (dashboard) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(maintenanceDashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _paymentSettingsCard(),
              const SizedBox(height: 20),
              _pendingPaymentsCard(),
              const SizedBox(height: 20),
              _buildCreatePeriod(),
              const SizedBox(height: 20),
              if (dashboard.period == null)
                const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No maintenance period created yet. Create the current month to start tracking collections and expenses.')))
              else ...[
                _summary(dashboard.period!),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _generateBills(dashboard.period!),
                      icon: const Icon(Icons.receipt_long),
                      label: Text(
                        dashboard.period!.status == 'DRAFT'
                            ? 'Generate & Publish Bills'
                            : 'Regenerate / Sync Bills',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy || dashboard.period!.status == 'CLOSED'
                          ? null
                          : () => _closePeriod(dashboard.period!),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Close'),
                    ),
                    if (dashboard.period!.status == 'DRAFT')
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _editPeriod(dashboard.period!),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Period'),
                      ),
                    if (dashboard.period!.status == 'DRAFT')
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _deletePeriod(dashboard.period!),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Period'),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _expenseForm(dashboard.period!),
                const SizedBox(height: 20),
                _bills(dashboard.bills),
                const SizedBox(height: 20),
                _expenses(dashboard.expenses),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePeriod() => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Create Monthly Maintenance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Set the monthly amount and due date. Previous month closing balance becomes the opening balance. The period starts as Draft; generating bills publishes it.'),
            const SizedBox(height: 16),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly amount', prefixText: '₹ ', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => _pickDate(month: true), child: Text('Month: ${_month.month}/${_month.year}'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(onPressed: () => _pickDate(month: false), child: Text('Due: ${_date(_dueDate)}'))),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _createPeriod, child: const Text('Create Period'))),
          ]),
        ),
      );

  Widget _summary(MaintenancePeriod p) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: MediaQuery.sizeOf(context).width > 900 ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.7,
        children: [
          _stat('Opening Balance', _money(p.openingBalance)),
          _stat('Collected', _money(p.collectedTotal)),
          _stat('Spent', _money(p.expenseTotal)),
          _stat('Remaining Balance', _money(p.closingBalance)),
          _stat('Paid Residents', '${p.paidBills}'),
          _stat('Pending Residents', '${p.unpaidBills}'),
          _stat('Total Bills', '${p.totalBills}'),
          _stat('Billed', _money(p.billedTotal)),
        ],
      );

  Widget _stat(String title, String value) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 6), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])));

  Widget _expenseForm(MaintenancePeriod period) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Add Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(controller: _expenseCategoryController, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _expenseDescriptionController, decoration: const InputDecoration(labelText: 'What was spent on?', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _expenseAmountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: () async { final d = await showDatePicker(context: context, initialDate: _spentOn, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (d != null) setState(() => _spentOn = d); }, child: Text('Spent on: ${_date(_spentOn)}')),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : () => _addExpense(period), child: const Text('Add Expense'))),
      ])));

  Widget _bills(List<MaintenanceBill> bills) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resident Payment Tracking',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (bills.isEmpty)
                const Text('Bills are not generated yet.')
              else
                ...bills.map(
                  (b) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    color: const Color(0xffF8FAFC),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 620;
                          final info = Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                child: Icon(
                                  b.status == 'PAID'
                                      ? Icons.check
                                      : Icons.schedule,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.residentName,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${b.propertyName ?? ''} ${b.sectionName ?? ''} • Unit ${b.unitNumber ?? ''}',
                                      softWrap: true,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Due ${_date(b.dueDate)} • Paid ${_money(b.amountPaid)} • Balance ${_money(b.balance)}',
                                      softWrap: true,
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                          final actions = b.status == 'PAID' || b.status == 'PARTIAL'
                              ? Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 4,
                                  children: [
                                    Text(
                                      b.status,
                                      style: TextStyle(
                                        color: b.status == 'PAID'
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (b.status != 'PAID')
                                      TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _recordAdminPayment(b),
                                        child: const Text('Record Payment'),
                                      ),
                                  ],
                                )
                              : Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 4,
                                  children: [
                                    FilledButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _recordAdminPayment(b),
                                      child: const Text('Record Paid'),
                                    ),
                                    IconButton(
                                      tooltip: 'Edit bill',
                                      onPressed: _busy ? null : () => _editBill(b),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete bill',
                                      onPressed: _busy ? null : () => _deleteBill(b),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                );
                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                info,
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: actions,
                                ),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: info),
                              const SizedBox(width: 12),
                              actions,
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _expenses(List<MaintenanceExpense> expenses) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Monthly Expenses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (expenses.isEmpty)
          const Text('No expenses recorded.')
        else
          ...expenses.map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long),
                title: Text(e.category),
                subtitle: Text(e.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit expense',
                      onPressed: _busy ? null : () => _editExpense(e),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    Text(_money(e.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ))
      ])));
}
