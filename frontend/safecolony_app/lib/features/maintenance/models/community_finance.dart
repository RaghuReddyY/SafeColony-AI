double _financeDouble(dynamic value) => double.tryParse(value?.toString() ?? '0') ?? 0;
int _financeInt(dynamic value) => int.tryParse(value?.toString() ?? '0') ?? 0;

class CommunityContribution {
  final int id;
  final int? residentId;
  final String payerName;
  final String? blockName;
  final String? unitNumber;
  final double amount;
  final String paymentMethod;
  final String? reference;
  final String status;
  final DateTime collectedAt;

  const CommunityContribution({
    required this.id,
    this.residentId,
    required this.payerName,
    this.blockName,
    this.unitNumber,
    required this.amount,
    required this.paymentMethod,
    this.reference,
    required this.status,
    required this.collectedAt,
  });

  factory CommunityContribution.fromJson(Map<String, dynamic> json) => CommunityContribution(
        id: _financeInt(json['id']),
        residentId: json['resident_id'] == null ? null : _financeInt(json['resident_id']),
        payerName: json['payer_name']?.toString() ?? 'Resident',
        blockName: json['block_name']?.toString(),
        unitNumber: json['unit_number']?.toString(),
        amount: _financeDouble(json['amount']),
        paymentMethod: json['payment_method']?.toString() ?? 'MANUAL',
        reference: json['reference']?.toString(),
        status: json['status']?.toString() ?? 'VERIFIED',
        collectedAt: DateTime.parse(json['collected_at'].toString()),
      );
}

class CommunityExpense {
  final int id;
  final String category;
  final String description;
  final double amount;
  final DateTime spentOn;
  final DateTime createdAt;

  const CommunityExpense({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.spentOn,
    required this.createdAt,
  });

  factory CommunityExpense.fromJson(Map<String, dynamic> json) => CommunityExpense(
        id: _financeInt(json['id']),
        category: json['category']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        amount: _financeDouble(json['amount']),
        spentOn: DateTime.parse(json['spent_on'].toString()),
        createdAt: DateTime.parse(json['created_at'].toString()),
      );
}

class CommunityHouseholdStatus {
  final int residentId;
  final String residentName;
  final String? sectionName;
  final String? unitNumber;
  final double? requiredAmount;
  final double amountPaid;
  final String status;

  const CommunityHouseholdStatus({
    required this.residentId,
    required this.residentName,
    this.sectionName,
    this.unitNumber,
    this.requiredAmount,
    required this.amountPaid,
    required this.status,
  });

  factory CommunityHouseholdStatus.fromJson(Map<String, dynamic> json) =>
      CommunityHouseholdStatus(
        residentId: _financeInt(json['resident_id']),
        residentName: json['resident_name']?.toString() ?? 'Resident',
        sectionName: json['section_name']?.toString(),
        unitNumber: json['unit_number']?.toString(),
        requiredAmount: json['required_amount'] == null ? null : _financeDouble(json['required_amount']),
        amountPaid: _financeDouble(json['amount_paid']),
        status: json['status']?.toString() ?? 'UNPAID',
      );
}

class CommunityFund {
  final int id;
  final String title;
  final String purpose;
  final double? targetAmount;
  final String contributionMode;
  final double? perUnitAmount;
  final DateTime? dueDate;
  final String status;
  final String paymentMethod;
  final String? paymentUpiId;
  final String? paymentDisplayName;
  final double collectedAmount;
  final double expenseAmount;
  final double balance;
  final int contributorCount;
  final DateTime createdAt;
  final List<CommunityContribution> contributions;
  final List<CommunityHouseholdStatus> householdStatus;
  final List<CommunityExpense> expenses;

  const CommunityFund({
    required this.id,
    required this.title,
    required this.purpose,
    required this.targetAmount,
    required this.contributionMode,
    required this.perUnitAmount,
    required this.dueDate,
    required this.status,
    required this.paymentMethod,
    this.paymentUpiId,
    this.paymentDisplayName,
    required this.collectedAmount,
    required this.expenseAmount,
    required this.balance,
    required this.contributorCount,
    required this.createdAt,
    this.contributions = const [],
    this.householdStatus = const [],
    this.expenses = const [],
  });

  factory CommunityFund.fromJson(Map<String, dynamic> json) => CommunityFund(
        id: _financeInt(json['id']),
        title: json['title']?.toString() ?? '',
        purpose: json['purpose']?.toString() ?? '',
        targetAmount: json['target_amount'] == null ? null : _financeDouble(json['target_amount']),
        contributionMode: json['contribution_mode']?.toString() ?? 'FREE',
        perUnitAmount: json['per_unit_amount'] == null ? null : _financeDouble(json['per_unit_amount']),
        dueDate: json['due_date'] == null ? null : DateTime.parse(json['due_date'].toString()),
        status: json['status']?.toString() ?? 'OPEN',
        paymentMethod: json['payment_method']?.toString() ?? 'MANUAL',
        paymentUpiId: json['payment_upi_id']?.toString(),
        paymentDisplayName: json['payment_display_name']?.toString(),
        collectedAmount: _financeDouble(json['collected_amount']),
        expenseAmount: _financeDouble(json['expense_amount']),
        balance: _financeDouble(json['balance']),
        contributorCount: _financeInt(json['contributor_count']),
        createdAt: DateTime.parse(json['created_at'].toString()),
        contributions: (json['contributions'] as List? ?? [])
            .map((e) => CommunityContribution.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        householdStatus: (json['household_status'] as List? ?? [])
            .map((e) => CommunityHouseholdStatus.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        expenses: (json['expenses'] as List? ?? [])
            .map((e) => CommunityExpense.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class CommunityFinanceDashboard {
  final bool canPay;
  final List<CommunityFund> funds;
  final double totalCollected;
  final double totalExpenses;
  final double totalBalance;

  const CommunityFinanceDashboard({
    required this.canPay,
    required this.funds,
    required this.totalCollected,
    required this.totalExpenses,
    required this.totalBalance,
  });

  factory CommunityFinanceDashboard.fromJson(Map<String, dynamic> json) => CommunityFinanceDashboard(
        canPay: json['can_pay'] == true,
        funds: (json['funds'] as List? ?? [])
            .map((e) => CommunityFund.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        totalCollected: _financeDouble(json['total_collected']),
        totalExpenses: _financeDouble(json['total_expenses']),
        totalBalance: _financeDouble(json['total_balance']),
      );
}

class CommunityPaymentLink {
  final int fundId;
  final double amount;
  final String mode;
  final String referenceId;
  final String paymentUrl;
  final String? upiId;
  final String? displayName;
  final String? message;

  const CommunityPaymentLink({
    required this.fundId,
    required this.amount,
    required this.mode,
    required this.referenceId,
    required this.paymentUrl,
    this.upiId,
    this.displayName,
    this.message,
  });

  factory CommunityPaymentLink.fromJson(Map<String, dynamic> json) => CommunityPaymentLink(
        fundId: _financeInt(json['fund_id']),
        amount: _financeDouble(json['amount']),
        mode: json['mode']?.toString() ?? 'MANUAL',
        referenceId: json['reference_id']?.toString() ?? '',
        paymentUrl: json['payment_url']?.toString() ?? '',
        upiId: json['upi_id']?.toString(),
        displayName: json['display_name']?.toString(),
        message: json['message']?.toString(),
      );
}
