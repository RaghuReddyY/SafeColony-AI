class OrganizationFinanceSummary {
  final String? organizationName;
  final String? organizationCode;
  final double maintenanceBilledTotal;
  final double maintenanceCollectedTotal;
  final double maintenanceExpenseTotal;
  final double maintenanceOutstandingTotal;
  final double maintenanceBalance;
  final double communityTargetTotal;
  final double communityCollectedTotal;
  final double communityExpenseTotal;
  final double communityBalance;
  final int communityFundCount;
  final List<MaintenanceSectionSummary> maintenanceSections;
  final List<CommunityFundSummary> communityFunds;

  const OrganizationFinanceSummary({
    this.organizationName,
    this.organizationCode,
    required this.maintenanceBilledTotal,
    required this.maintenanceCollectedTotal,
    required this.maintenanceExpenseTotal,
    required this.maintenanceOutstandingTotal,
    required this.maintenanceBalance,
    required this.communityTargetTotal,
    required this.communityCollectedTotal,
    required this.communityExpenseTotal,
    required this.communityBalance,
    required this.communityFundCount,
    required this.maintenanceSections,
    required this.communityFunds,
  });

  factory OrganizationFinanceSummary.fromJson(Map<String, dynamic> json) {
    double money(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;

    return OrganizationFinanceSummary(
      organizationName: json['organization_name']?.toString(),
      organizationCode: json['organization_code']?.toString(),
      maintenanceBilledTotal: money(json['maintenance_billed_total']),
      maintenanceCollectedTotal: money(json['maintenance_collected_total']),
      maintenanceExpenseTotal: money(json['maintenance_expense_total']),
      maintenanceOutstandingTotal: money(json['maintenance_outstanding_total']),
      maintenanceBalance: money(json['maintenance_balance']),
      communityTargetTotal: money(json['community_target_total']),
      communityCollectedTotal: money(json['community_collected_total']),
      communityExpenseTotal: money(json['community_expense_total']),
      communityBalance: money(json['community_balance']),
      communityFundCount: (json['community_fund_count'] as num?)?.toInt() ?? 0,
      maintenanceSections: (json['maintenance_sections'] as List? ?? const [])
          .map((e) => MaintenanceSectionSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      communityFunds: (json['community_funds'] as List? ?? const [])
          .map((e) => CommunityFundSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class MaintenanceSectionSummary {
  final int? sectionId;
  final String sectionName;
  final DateTime? month;
  final String? status;
  final double openingBalance;
  final double billedTotal;
  final double collectedTotal;
  final double expenseTotal;
  final double outstandingTotal;
  final double balance;
  final int totalBills;
  final int paidBills;
  final int pendingBills;

  const MaintenanceSectionSummary({
    this.sectionId,
    required this.sectionName,
    this.month,
    this.status,
    required this.openingBalance,
    required this.billedTotal,
    required this.collectedTotal,
    required this.expenseTotal,
    required this.outstandingTotal,
    required this.balance,
    required this.totalBills,
    required this.paidBills,
    required this.pendingBills,
  });

  factory MaintenanceSectionSummary.fromJson(Map<String, dynamic> json) {
    double money(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
    return MaintenanceSectionSummary(
      sectionId: (json['section_id'] as num?)?.toInt(),
      sectionName: json['section_name']?.toString() ?? 'Block',
      month: DateTime.tryParse(json['month']?.toString() ?? ''),
      status: json['status']?.toString(),
      openingBalance: money(json['opening_balance']),
      billedTotal: money(json['billed_total']),
      collectedTotal: money(json['collected_total']),
      expenseTotal: money(json['expense_total']),
      outstandingTotal: money(json['outstanding_total']),
      balance: money(json['balance']),
      totalBills: (json['total_bills'] as num?)?.toInt() ?? 0,
      paidBills: (json['paid_bills'] as num?)?.toInt() ?? 0,
      pendingBills: (json['pending_bills'] as num?)?.toInt() ?? 0,
    );
  }
}

class CommunityFundSummary {
  final int id;
  final String title;
  final String status;
  final String contributionMode;
  final double? perUnitAmount;
  final double? targetAmount;
  final double collectedAmount;
  final double expenseAmount;
  final double balance;
  final int contributorCount;
  final int paidHouseholds;
  final int pendingHouseholds;

  const CommunityFundSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.contributionMode,
    this.perUnitAmount,
    this.targetAmount,
    required this.collectedAmount,
    required this.expenseAmount,
    required this.balance,
    required this.contributorCount,
    required this.paidHouseholds,
    required this.pendingHouseholds,
  });

  factory CommunityFundSummary.fromJson(Map<String, dynamic> json) {
    double? money(dynamic value) => value == null ? null : double.tryParse(value.toString());
    return CommunityFundSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Community Fund',
      status: json['status']?.toString() ?? 'DRAFT',
      contributionMode: json['contribution_mode']?.toString() ?? 'FREE',
      perUnitAmount: money(json['per_unit_amount']),
      targetAmount: money(json['target_amount']),
      collectedAmount: money(json['collected_amount']) ?? 0,
      expenseAmount: money(json['expense_amount']) ?? 0,
      balance: money(json['balance']) ?? 0,
      contributorCount: (json['contributor_count'] as num?)?.toInt() ?? 0,
      paidHouseholds: (json['paid_households'] as num?)?.toInt() ?? 0,
      pendingHouseholds: (json['pending_households'] as num?)?.toInt() ?? 0,
    );
  }
}


class MoneyTransaction {
  final String id, kind, title, payerOrCategory, status, occurredAt;
  final String? blockName, unitNumber, paymentMethod, reference;
  final double amount;
  const MoneyTransaction({
    required this.id, required this.kind, required this.title,
    required this.payerOrCategory, required this.status, required this.occurredAt,
    this.blockName, this.unitNumber, this.paymentMethod, this.reference,
    required this.amount,
  });
  factory MoneyTransaction.fromJson(Map<String,dynamic> j)=>MoneyTransaction(
    id:j['id']?.toString()??'', kind:j['kind']?.toString()??'', title:j['title']?.toString()??'',
    payerOrCategory:j['payer_or_category']?.toString()??'', status:j['status']?.toString()??'',
    occurredAt:j['occurred_at']?.toString()??'', blockName:j['block_name']?.toString(),
    unitNumber:j['unit_number']?.toString(), paymentMethod:j['payment_method']?.toString(),
    reference:j['reference']?.toString(), amount:double.tryParse(j['amount']?.toString()??'')??0,
  );
}
