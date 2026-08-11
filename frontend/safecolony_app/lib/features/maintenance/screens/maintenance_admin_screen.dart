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

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  String _money(double value) => '₹${value.toStringAsFixed(2)}';
  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

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
              _buildCreatePeriod(),
              const SizedBox(height: 20),
              if (dashboard.period == null)
                const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No maintenance period created yet. Create the current month to start tracking collections and expenses.')))
              else ...[
                _summary(dashboard.period!),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: FilledButton.icon(onPressed: _busy ? null : () => _generateBills(dashboard.period!), icon: const Icon(Icons.receipt_long), label: const Text('Generate Monthly Bills'))),
                ]),
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
            const Text('Set the monthly amount and due date. Previous month closing balance becomes the opening balance.'),
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

  Widget _bills(List<MaintenanceBill> bills) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Resident Payment Tracking', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (bills.isEmpty) const Text('Bills are not generated yet.') else ...bills.map((b) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Icon(b.status == 'PAID' ? Icons.check : Icons.schedule)),
          title: Text(b.residentName),
          subtitle: Text('${b.propertyName ?? ''} ${b.sectionName ?? ''} Unit ${b.unitNumber ?? ''}\nDue ${_date(b.dueDate)}\nPaid ${_money(b.amountPaid)} • Balance ${_money(b.balance)}'),
          trailing: b.status == 'PAID'
              ? const Text('PAID', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
              : FilledButton(onPressed: _busy ? null : () => _recordAdminPayment(b), child: const Text('Record Paid')),
        ))
      ])));

  Widget _expenses(List<MaintenanceExpense> expenses) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Monthly Expenses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (expenses.isEmpty) const Text('No expenses recorded.') else ...expenses.map((e) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.receipt_long), title: Text(e.category), subtitle: Text(e.description), trailing: Text(_money(e.amount), style: const TextStyle(fontWeight: FontWeight.bold))))
      ])));
}
