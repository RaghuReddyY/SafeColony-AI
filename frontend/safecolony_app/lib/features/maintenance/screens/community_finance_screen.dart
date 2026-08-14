import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/community_finance.dart';
import '../providers/community_finance_provider.dart';
import '../providers/maintenance_provider.dart';
import '../models/maintenance.dart';
import '../../auth/providers/auth_provider.dart';

class CommunityFinanceScreen extends ConsumerStatefulWidget {
  const CommunityFinanceScreen({super.key});

  @override
  ConsumerState<CommunityFinanceScreen> createState() => _CommunityFinanceScreenState();
}

class _CommunityFinanceScreenState extends ConsumerState<CommunityFinanceScreen> {
  bool _isManager = false;
  bool _busy = false;
  String _paymentMethod = 'MANUAL';
  String _contributionMode = 'FREE';

  final _paymentUpi = TextEditingController();
  final _paymentName = TextEditingController();
  final _title = TextEditingController();
  final _purpose = TextEditingController();
  final _target = TextEditingController();
  final _perUnit = TextEditingController();
  final _payer = TextEditingController();
  final _block = TextEditingController();
  final _unit = TextEditingController();
  final _amount = TextEditingController();
  final _expenseCategory = TextEditingController();
  final _expenseDescription = TextEditingController();
  final _expenseAmount = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = ref.read(authProvider).user?.role;
      if (mounted) {
        setState(() => _isManager = role == 'ORGANIZATION_ADMIN' || role == 'COMMUNITY_FINANCE_ADMIN');
      }
    });
  }

  @override
  void dispose() {
    for (final c in [
      _paymentUpi, _paymentName, _title, _purpose, _target, _perUnit,
      _payer, _block, _unit, _amount, _expenseCategory, _expenseDescription,
      _expenseAmount,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _money(double v) => '₹${v.toStringAsFixed(0)}';
  String _money2(double v) => '₹${v.toStringAsFixed(2)}';
  String _date(DateTime? d) => d == null ? 'No due date' : '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  String _modeLabel(String mode) {
    switch (mode) {
      case 'FIXED': return 'Fixed per house';
      case 'SUGGESTED': return 'Suggested per house (pay any amount)';
      default: return 'Free contribution (pay any amount)';
    }
  }

  Future<void> _createFund({String status = 'PUBLISHED'}) async {
    final title = _title.text.trim();
    final purpose = _purpose.text.trim();
    final target = double.tryParse(_target.text.trim());
    final perUnit = double.tryParse(_perUnit.text.trim());
    if (title.isEmpty || purpose.isEmpty) {
      _snack('Enter the collection title and purpose.');
      return;
    }
    if (_contributionMode != 'FREE' && (perUnit == null || perUnit <= 0)) {
      _snack('Enter the per-house amount for this contribution type.');
      return;
    }
    if (_paymentMethod == 'DIRECT_UPI' &&
        (_paymentUpi.text.trim().isEmpty || !_paymentUpi.text.trim().contains('@') || _paymentName.text.trim().isEmpty)) {
      _snack('For Direct UPI, enter a valid UPI ID and receiver name.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(communityFinanceServiceProvider).createFund(
        title: title,
        purpose: purpose,
        targetAmount: target,
        contributionMode: _contributionMode,
        perUnitAmount: perUnit,
        paymentMethod: _paymentMethod,
        paymentUpiId: _paymentUpi.text.trim().isEmpty ? null : _paymentUpi.text.trim(),
        paymentDisplayName: _paymentName.text.trim().isEmpty ? null : _paymentName.text.trim(),
        status: status,
      );
      if (!mounted) return;
      _title.clear(); _purpose.clear(); _target.clear(); _perUnit.clear();
      _paymentUpi.clear(); _paymentName.clear();
      setState(() { _paymentMethod = 'MANUAL'; _contributionMode = 'FREE'; });
      ref.invalidate(communityFinanceDashboardProvider);
      _snack(status == 'PUBLISHED' ? 'Community collection published.' : 'Community collection saved as draft.');
    } catch (e) {
      _snack('Unable to create collection: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payFund(CommunityFund fund) async {
    final suggested = fund.perUnitAmount;
    _amount.text = suggested == null ? '' : suggested.toStringAsFixed(2);
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Pay – ${fund.title}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_modeLabel(fund.contributionMode), style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            readOnly: fund.contributionMode == 'FIXED',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: fund.contributionMode == 'FIXED' ? 'Required amount' : 'Your contribution',
              prefixText: '₹ ',
              border: const OutlineInputBorder(),
            ),
          ),
          if (fund.contributionMode == 'SUGGESTED')
            const Padding(padding: EdgeInsets.only(top: 8), child: Text('The displayed amount is only a suggestion. You can pay more or less.', style: TextStyle(fontSize: 12, color: Colors.black54))),
          if (fund.contributionMode == 'FREE')
            const Padding(padding: EdgeInsets.only(top: 8), child: Text('Enter any amount you would like to contribute.', style: TextStyle(fontSize: 12, color: Colors.black54))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(_amount.text.trim())), child: const Text('Continue')),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;

    setState(() => _busy = true);
    try {
      final link = await ref.read(communityFinanceServiceProvider).createPayment(fundId: fund.id, amount: amount);
      if (!mounted) return;

      if (link.mode == 'DIRECT_UPI' && link.paymentUrl.isNotEmpty) {
        final launched = await launchUrl(Uri.parse(link.paymentUrl), mode: LaunchMode.externalApplication);
        if (!launched) {
          _snack('Unable to open the UPI app. You can still submit the transaction reference after paying.');
        }
      }

      final referenceController = TextEditingController();
      final reference = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Submit payment reference'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(link.message ?? 'Submit your payment reference for administrator verification.'),
            const SizedBox(height: 12),
            TextField(controller: referenceController, decoration: const InputDecoration(labelText: 'Transaction / receipt reference (optional for manual)', border: OutlineInputBorder())),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, referenceController.text.trim()), child: const Text('Submit for Verification')),
          ],
        ),
      );
      referenceController.dispose();
      if (reference == null) return;

      await ref.read(communityFinanceServiceProvider).submitPayment(fundId: fund.id, amount: amount, reference: reference.isEmpty ? null : reference);
      if (!mounted) return;
      ref.invalidate(communityFinanceDashboardProvider);
      _snack('Payment submitted. It will be shown as pending until the finance administrator verifies it.');
    } catch (e) {
      _snack('Unable to process community payment: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editFund(CommunityFund fund) async {
    final title = TextEditingController(text: fund.title);
    final purpose = TextEditingController(text: fund.purpose);
    final target = TextEditingController(text: fund.targetAmount?.toStringAsFixed(2) ?? '');
    final perUnit = TextEditingController(text: fund.perUnitAmount?.toStringAsFixed(2) ?? '');
    final upi = TextEditingController(text: fund.paymentUpiId ?? '');
    final name = TextEditingController(text: fund.paymentDisplayName ?? '');
    var mode = fund.contributionMode;
    var payment = fund.paymentMethod;
    final result = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
      title: const Text('Edit community collection'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
        TextField(controller: purpose, maxLines: 2, decoration: const InputDecoration(labelText: 'Purpose')),
        TextField(controller: target, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Target amount', prefixText: '₹ ')),
        DropdownButtonFormField<String>(value: mode, items: const [DropdownMenuItem(value: 'FIXED', child: Text('Fixed')), DropdownMenuItem(value: 'SUGGESTED', child: Text('Suggested')), DropdownMenuItem(value: 'FREE', child: Text('Free'))], onChanged: (v) { if (v != null) setDialog(() => mode = v); }),
        if (mode != 'FREE') TextField(controller: perUnit, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Per-house amount', prefixText: '₹ ')),
        DropdownButtonFormField<String>(value: payment, items: const [DropdownMenuItem(value: 'MANUAL', child: Text('Manual / Cash / Bank transfer')), DropdownMenuItem(value: 'DIRECT_UPI', child: Text('Direct UPI'))], onChanged: (v) { if (v != null) setDialog(() => payment = v); }),
        if (payment == 'DIRECT_UPI') ...[TextField(controller: upi, decoration: const InputDecoration(labelText: 'UPI ID')), TextField(controller: name, decoration: const InputDecoration(labelText: 'UPI receiver name'))],
        const SizedBox(height: 8),
        const Text('Editing is allowed only when no payment activity exists.', style: TextStyle(fontSize: 12, color: Colors.black54)),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))],
    )));
    if (result != true) { for (final c in [title, purpose, target, perUnit, upi, name]) { c.dispose(); } return; }
    final targetValue = double.tryParse(target.text.trim());
    final perUnitValue = double.tryParse(perUnit.text.trim());
    if (title.text.trim().isEmpty || purpose.text.trim().isEmpty || (mode != 'FREE' && (perUnitValue == null || perUnitValue <= 0))) {
      for (final c in [title, purpose, target, perUnit, upi, name]) { c.dispose(); }
      _snack('Enter valid collection details.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(communityFinanceServiceProvider).updateFund(fundId: fund.id, title: title.text.trim(), purpose: purpose.text.trim(), targetAmount: targetValue, contributionMode: mode, perUnitAmount: perUnitValue, paymentMethod: payment, paymentUpiId: upi.text.trim().isEmpty ? null : upi.text.trim(), paymentDisplayName: name.text.trim().isEmpty ? null : name.text.trim());
      if (!mounted) return;
      ref.invalidate(communityFinanceDashboardProvider);
      _snack('Collection updated.');
    } catch (e) { _snack('Unable to update collection: $e'); } finally { if (mounted) setState(() => _busy = false); for (final c in [title, purpose, target, perUnit, upi, name]) { c.dispose(); } }
  }

  Future<void> _deleteFund(CommunityFund fund) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Delete collection?'), content: Text('Delete ${fund.title}? This is allowed only when no payment activity exists.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))]));
    if (ok != true) return;
    setState(() => _busy = true);
    try { await ref.read(communityFinanceServiceProvider).deleteFund(fund.id); if (!mounted) return; ref.invalidate(communityFinanceDashboardProvider); _snack('Collection deleted.'); } catch (e) { _snack('Unable to delete collection: $e'); } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _publishFund(CommunityFund fund) async {
    setState(() => _busy = true);
    try {
      await ref.read(communityFinanceServiceProvider).publishFund(fund.id);
      if (!mounted) return;
      ref.invalidate(communityFinanceDashboardProvider);
      _snack('Collection published and primary residents notified.');
    } catch (e) { _snack('Unable to publish collection: $e'); } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _closeFund(CommunityFund fund) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Close collection?'), content: const Text('Closed collections cannot receive new payments or be edited.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Close'))]));
    if (ok != true) return;
    setState(() => _busy = true);
    try { await ref.read(communityFinanceServiceProvider).closeFund(fund.id); if (!mounted) return; ref.invalidate(communityFinanceDashboardProvider); _snack('Collection closed.'); } catch (e) { _snack('Unable to close collection: $e'); } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _addContribution(CommunityFund fund) async {
    final amount = double.tryParse(_amount.text.trim());
    if (_payer.text.trim().isEmpty || amount == null || amount <= 0) {
      _snack('Enter payer name and amount.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(communityFinanceServiceProvider).addContribution(
        fundId: fund.id,
        payerName: _payer.text.trim(),
        blockName: _block.text.trim().isEmpty ? null : _block.text.trim(),
        unitNumber: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
        amount: amount,
      );
      if (!mounted) return;
      _payer.clear(); _block.clear(); _unit.clear(); _amount.clear();
      ref.invalidate(communityFinanceDashboardProvider);
      _snack('Collection recorded and marked verified.');
    } catch (e) { _snack('Unable to record collection: $e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _addExpense(CommunityFund fund) async {
    final amount = double.tryParse(_expenseAmount.text.trim());
    if (_expenseCategory.text.trim().isEmpty || _expenseDescription.text.trim().isEmpty || amount == null || amount <= 0) {
      _snack('Enter expense details and amount.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(communityFinanceServiceProvider).addExpense(fundId: fund.id, category: _expenseCategory.text.trim(), description: _expenseDescription.text.trim(), amount: amount, spentOn: DateTime.now());
      if (!mounted) return;
      _expenseCategory.clear(); _expenseDescription.clear(); _expenseAmount.clear();
      ref.invalidate(communityFinanceDashboardProvider);
      _snack('Community expense recorded.');
    } catch (e) { _snack('Unable to record expense: $e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _verifyContribution(CommunityContribution contribution, bool approve) async {
    setState(() => _busy = true);
    try {
      await ref.read(communityFinanceServiceProvider).verifyContribution(contributionId: contribution.id, approve: approve);
      if (!mounted) return;
      ref.invalidate(communityFinanceDashboardProvider);
      _snack(approve ? 'Contribution verified.' : 'Contribution rejected.');
    } catch (e) { _snack('Unable to process contribution: $e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(communityFinanceDashboardProvider);
    final role = ref.watch(authProvider).user?.role;
    final showMaintenanceSummary = role == 'RESIDENT' || role == 'ORGANIZATION_ADMIN';
    final maintenanceAsync = showMaintenanceSummary ? ref.watch(communityFinanceProvider) : null;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(title: const Text('Community Finance'), backgroundColor: Colors.white, surfaceTintColor: Colors.white),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.account_balance_wallet_outlined, size: 60), const SizedBox(height: 12), const Text('Unable to load community finance'), const SizedBox(height: 12), Text('$e', textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: () => ref.invalidate(communityFinanceDashboardProvider), child: const Text('Retry'))]))),
        data: (data) => RefreshIndicator(
          onRefresh: () async { ref.invalidate(communityFinanceDashboardProvider); await ref.read(communityFinanceDashboardProvider.future); },
          child: ListView(padding: const EdgeInsets.all(20), children: [
            _intro(data.canPay),
            const SizedBox(height: 16),
            _summary(data),
            if (maintenanceAsync != null) ...[
              const SizedBox(height: 22),
              maintenanceAsync.when(
                loading: () => const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))),
                error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Text('Monthly maintenance summary is unavailable.\n$e'))),
                data: (m) => _monthlyMaintenanceSection(m),
              ),
            ],
            if (_isManager) ...[const SizedBox(height: 20), _createFundCard()],
            const SizedBox(height: 20),
            if (data.funds.isEmpty) _empty() else ...data.funds.map((fund) => _fundCard(fund, data.canPay)),
          ]),
        ),
      ),
    );
  }

  Widget _intro(bool canPay) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xffECFDF5), Color(0xffEFF6FF)]), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xffBBF7D0))),
    child: Row(children: [
      const Icon(Icons.account_balance_rounded, size: 42, color: Color(0xff059669)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Organization-wide collections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        const Text('Festivals, CCTV, amenities, community events and other shared expenses are tracked separately from monthly maintenance.', style: TextStyle(color: Color(0xff475569), height: 1.35)),
        if (!canPay) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Family members can view finance information, but only the primary resident can submit a payment for the unit.', style: TextStyle(fontSize: 12, color: Color(0xff64748B)))),
      ])),
    ]),
  );

  Widget _monthlyMaintenanceSection(MaintenanceDashboard d) {
    final p = d.period;
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Monthly Maintenance – Your Section', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(p == null ? 'No maintenance period has been published yet.' : 'Current period: ${p.month.month}/${p.month.year} • Due ${_date(p.dueDate)}', style: const TextStyle(color: Color(0xff64748B))),
      if (p != null) ...[
        const SizedBox(height: 14),
        Row(children: [_mini('Collected', _money(p.collectedTotal)), _mini('Expenses', _money(p.expenseTotal)), _mini('Balance', _money(p.closingBalance))]),
        const SizedBox(height: 14),
        const Text('Section payment status', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        if (d.bills.isEmpty) const Text('No maintenance bills generated yet.') else ...d.bills.map((b) => ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: Icon(b.status == 'PAID' ? Icons.check_circle : Icons.schedule, color: b.status == 'PAID' ? Colors.green : Colors.orange),
          title: Text('${b.residentName} • Unit ${b.unitNumber ?? '-'}'),
          subtitle: Text('Due ${_money2(b.totalDue)} • Paid ${_money2(b.amountPaid)} • ${b.status}'),
          trailing: Text(b.status, style: TextStyle(fontWeight: FontWeight.w700, color: b.status == 'PAID' ? Colors.green : Colors.orange)),
        )),
        const SizedBox(height: 8),
        const Text('Maintenance expenses', style: TextStyle(fontWeight: FontWeight.w700)),
        if (d.expenses.isEmpty) const Padding(padding: EdgeInsets.only(top: 6), child: Text('No monthly maintenance expenses recorded.')) else ...d.expenses.map((e) => ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: const Icon(Icons.receipt_long), title: Text(e.category), subtitle: Text(e.description), trailing: Text(_money(e.amount), style: const TextStyle(fontWeight: FontWeight.w700)))),
      ],
    ])));
  }

  Widget _summary(CommunityFinanceDashboard d) => Row(children: [_metric('Collected', d.totalCollected, const Color(0xff059669)), const SizedBox(width: 10), _metric('Expenses', d.totalExpenses, const Color(0xffEA580C)), const SizedBox(width: 10), _metric('Balance', d.totalBalance, const Color(0xff2563EB))]);
  Widget _metric(String label, double value, Color color) => Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xffE2E8F0))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Color(0xff64748B), fontSize: 12)), const SizedBox(height: 5), Text(_money(value), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: color))])));

  Widget _createFundCard() => Card(margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Create & publish a collection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    const SizedBox(height: 6),
    const Text('Target amount is the community goal. Per-house amount controls what each resident is expected/suggested to contribute.', style: TextStyle(color: Color(0xff64748B))),
    const SizedBox(height: 14),
    TextField(controller: _title, decoration: const InputDecoration(labelText: 'Collection title', border: OutlineInputBorder())),
    const SizedBox(height: 10),
    TextField(controller: _purpose, maxLines: 2, decoration: const InputDecoration(labelText: 'Purpose', border: OutlineInputBorder())),
    const SizedBox(height: 10),
    TextField(controller: _target, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Target amount (optional)', prefixText: '₹ ', border: OutlineInputBorder())),
    const SizedBox(height: 10),
    DropdownButtonFormField<String>(
      value: _contributionMode,
      decoration: const InputDecoration(labelText: 'Contribution type', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: 'FIXED', child: Text('Fixed – exact amount is mandatory')),
        DropdownMenuItem(value: 'SUGGESTED', child: Text('Suggested – resident can pay any amount')),
        DropdownMenuItem(value: 'FREE', child: Text('Free – resident chooses any amount')),
      ],
      onChanged: _busy ? null : (v) { if (v != null) setState(() => _contributionMode = v); },
    ),
    if (_contributionMode != 'FREE') ...[
      const SizedBox(height: 10),
      TextField(controller: _perUnit, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: _contributionMode == 'FIXED' ? 'Required amount per house' : 'Suggested amount per house', prefixText: '₹ ', border: const OutlineInputBorder())),
    ],
    const SizedBox(height: 10),
    DropdownButtonFormField<String>(
      value: _paymentMethod,
      decoration: const InputDecoration(labelText: 'Payment method', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: 'MANUAL', child: Text('Manual / Cash / Bank transfer')),
        DropdownMenuItem(value: 'DIRECT_UPI', child: Text('Direct UPI (PhonePe / Google Pay)')),
      ],
      onChanged: _busy ? null : (v) { if (v != null) setState(() => _paymentMethod = v); },
    ),
    if (_paymentMethod == 'DIRECT_UPI') ...[
      const SizedBox(height: 10),
      TextField(controller: _paymentUpi, decoration: const InputDecoration(labelText: 'Collection UPI ID', hintText: 'festival@upi', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: _paymentName, decoration: const InputDecoration(labelText: 'UPI receiver name', border: OutlineInputBorder())),
    ],
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : () => _createFund(status: 'DRAFT'), icon: const Icon(Icons.save_outlined), label: const Text('Save Draft'))),
      const SizedBox(width: 10),
      Expanded(child: FilledButton.icon(onPressed: _busy ? null : () => _createFund(status: 'PUBLISHED'), icon: const Icon(Icons.publish), label: const Text('Publish'))),
    ]),
  ])));

  Widget _fundCard(CommunityFund fund, bool canPay) => Card(margin: const EdgeInsets.only(bottom: 14), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(fund.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), Chip(label: Text(fund.status))]),
    const SizedBox(height: 5), Text(fund.purpose, style: const TextStyle(color: Color(0xff64748B))),
    const SizedBox(height: 12),
    Wrap(spacing: 8, runSpacing: 8, children: [
      Chip(label: Text(_modeLabel(fund.contributionMode))),
      if (fund.perUnitAmount != null) Chip(label: Text('${fund.contributionMode == 'FIXED' ? 'Required' : 'Suggested'} ${_money(fund.perUnitAmount!)} / house')),
      if (fund.targetAmount != null) Chip(label: Text('Target ${_money(fund.targetAmount!)}')),
      Chip(label: Text('${fund.contributorCount} paid')),
    ]),
    const SizedBox(height: 12),
    Row(children: [_mini('Collected', _money(fund.collectedAmount)), _mini('Expenses', _money(fund.expenseAmount)), _mini('Balance', _money(fund.balance))]),
    const SizedBox(height: 8),
    Text('Due: ${_date(fund.dueDate)}', style: const TextStyle(fontSize: 12, color: Color(0xff64748B))),
    if (canPay && fund.status == 'PUBLISHED') ...[
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _busy ? null : () => _payFund(fund), icon: const Icon(Icons.payment), label: const Text('Pay Now'))),
    ],
    if (fund.paymentMethod == 'DIRECT_UPI') ...[
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xffF0FDF4), borderRadius: BorderRadius.circular(12)), child: Text('Payment via UPI: ${fund.paymentUpiId ?? '-'}${fund.paymentDisplayName == null ? '' : ' • ${fund.paymentDisplayName}'}')),
    ] else const Padding(padding: EdgeInsets.only(top: 8), child: Text('Payment method: Manual / Cash / Bank transfer', style: TextStyle(fontSize: 12, color: Color(0xff64748B)))),
    const SizedBox(height: 14),
    if (fund.householdStatus.isNotEmpty) ...[
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          fund.contributionMode == 'FIXED'
              ? 'Household payment status (${fund.householdStatus.length})'
              : 'Household contribution status (${fund.householdStatus.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          fund.contributionMode == 'FIXED'
              ? 'Shows every primary household in the community.'
              : 'Shows who contributed; contributions are voluntary.',
          style: const TextStyle(fontSize: 12, color: Color(0xff64748B)),
        ),
        children: fund.householdStatus.map((h) {
          final paid = h.amountPaid > 0;
          final color = h.status == 'PAID'
              ? Colors.green
              : h.status == 'PARTIAL'
                  ? Colors.orange
                  : h.status == 'UNPAID'
                      ? Colors.red
                      : Colors.blueGrey;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              h.status == 'PAID' ? Icons.check_circle : h.status == 'PARTIAL' ? Icons.timelapse : h.status == 'UNPAID' ? Icons.warning_amber_rounded : Icons.remove_circle_outline,
              color: color,
            ),
            title: Text('${h.residentName}${h.unitNumber == null ? '' : ' • Unit ${h.unitNumber}'}'),
            subtitle: Text(
              h.requiredAmount == null
                  ? 'Paid ${_money2(h.amountPaid)}'
                  : 'Required ${_money2(h.requiredAmount!)} • Paid ${_money2(h.amountPaid)}',
            ),
            trailing: Text(
              h.status == 'NOT_CONTRIBUTED' ? 'NOT CONTRIBUTED' : h.status,
              style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 11),
            ),
          );
        }).toList(),
      ),
    ],
    const SizedBox(height: 6),
    const Text('Payment records', style: TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 4),
    if (fund.contributions.isEmpty) const Text('No verified contributions yet.') else ...fund.contributions.map((c) => ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(c.status == 'VERIFIED' ? Icons.check_circle : c.status == 'PENDING' ? Icons.schedule : Icons.cancel, color: c.status == 'VERIFIED' ? Colors.green : c.status == 'PENDING' ? Colors.orange : Colors.red),
      title: Text('${c.payerName}${c.unitNumber == null ? '' : ' • Unit ${c.unitNumber}'}'),
      subtitle: Text('${_money2(c.amount)} • ${c.status}${c.reference == null ? '' : ' • Ref ${c.reference}'}'),
      trailing: _isManager && c.status == 'PENDING' ? Wrap(spacing: 2, children: [IconButton(tooltip: 'Reject', onPressed: _busy ? null : () => _verifyContribution(c, false), icon: const Icon(Icons.close)), IconButton(tooltip: 'Verify', onPressed: _busy ? null : () => _verifyContribution(c, true), icon: const Icon(Icons.verified))]) : null,
    )),
    const SizedBox(height: 8),
    const Text('Expenses', style: TextStyle(fontWeight: FontWeight.w700)),
    if (fund.expenses.isEmpty) const Padding(padding: EdgeInsets.only(top: 5), child: Text('No expenses recorded yet.')) else ...fund.expenses.map((e) => ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: const Icon(Icons.receipt_long), title: Text(e.category), subtitle: Text(e.description), trailing: Text(_money(e.amount), style: const TextStyle(fontWeight: FontWeight.w700)))),
    if (_isManager) ...[
      const SizedBox(height: 10),
      Wrap(spacing: 8, children: [
        OutlinedButton.icon(onPressed: _busy ? null : () => _showContribution(fund), icon: const Icon(Icons.add_card), label: const Text('Record Collection')),
        OutlinedButton.icon(onPressed: _busy ? null : () => _showExpense(fund), icon: const Icon(Icons.receipt_long), label: const Text('Record Expense')),
        if (fund.contributions.isEmpty && fund.expenses.isEmpty && fund.status != 'CLOSED') OutlinedButton.icon(onPressed: _busy ? null : () => _editFund(fund), icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
        if (fund.contributions.isEmpty && fund.expenses.isEmpty && fund.status != 'CLOSED') OutlinedButton.icon(onPressed: _busy ? null : () => _deleteFund(fund), icon: const Icon(Icons.delete_outline), label: const Text('Delete')),
        if (fund.status == 'DRAFT') OutlinedButton.icon(onPressed: _busy ? null : () => _publishFund(fund), icon: const Icon(Icons.publish), label: const Text('Publish')),
        if (fund.status != 'CLOSED') OutlinedButton.icon(onPressed: _busy ? null : () => _closeFund(fund), icon: const Icon(Icons.lock_outline), label: const Text('Close')),
      ]),
    ],
  ])));

  Widget _mini(String label, String value) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Color(0xff64748B))), const SizedBox(height: 3), Text(value, style: const TextStyle(fontWeight: FontWeight.w800))]));
  Widget _empty() => const Padding(padding: EdgeInsets.symmetric(vertical: 70), child: Column(children: [Icon(Icons.savings_outlined, size: 70, color: Color(0xff94A3B8)), SizedBox(height: 14), Text('No organization-wide collections yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), SizedBox(height: 6), Text('Create a collection when the community needs money for a festival, CCTV, event or other shared purpose.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff64748B)))]));

  Future<void> _showContribution(CommunityFund fund) async {
    await showDialog(context: context, builder: (_) => AlertDialog(title: Text('Record collection – ${fund.title}'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _payer, decoration: const InputDecoration(labelText: 'Payer name')),
      TextField(controller: _block, decoration: const InputDecoration(labelText: 'Block (optional)')),
      TextField(controller: _unit, decoration: const InputDecoration(labelText: 'Unit (optional)')),
      TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ')),
    ]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { Navigator.pop(context); _addContribution(fund); }, child: const Text('Record'))]));
  }

  Future<void> _showExpense(CommunityFund fund) async {
    await showDialog(context: context, builder: (_) => AlertDialog(title: Text('Record expense – ${fund.title}'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _expenseCategory, decoration: const InputDecoration(labelText: 'Category')),
      TextField(controller: _expenseDescription, decoration: const InputDecoration(labelText: 'Description')),
      TextField(controller: _expenseAmount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ')),
    ]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { Navigator.pop(context); _addExpense(fund); }, child: const Text('Record'))]));
  }
}
