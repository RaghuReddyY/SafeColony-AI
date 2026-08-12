class MaintenancePeriod {
  final int id;
  final int organizationId;
  final DateTime month;
  final double monthlyAmount;
  final DateTime dueDate;
  final double openingBalance;
  final double billedTotal;
  final double collectedTotal;
  final double expenseTotal;
  final double closingBalance;
  final int totalBills;
  final int paidBills;
  final int unpaidBills;
  final String? notes;

  const MaintenancePeriod({
    required this.id,
    required this.organizationId,
    required this.month,
    required this.monthlyAmount,
    required this.dueDate,
    required this.openingBalance,
    required this.billedTotal,
    required this.collectedTotal,
    required this.expenseTotal,
    required this.closingBalance,
    required this.totalBills,
    required this.paidBills,
    required this.unpaidBills,
    this.notes,
  });

  factory MaintenancePeriod.fromJson(Map<String, dynamic> json) {
    return MaintenancePeriod(
      id: json['id'],
      organizationId: json['organization_id'],
      month: DateTime.parse(json['month']),
      monthlyAmount: _double(json['monthly_amount']),
      dueDate: DateTime.parse(json['due_date']),
      openingBalance: _double(json['opening_balance']),
      billedTotal: _double(json['billed_total']),
      collectedTotal: _double(json['collected_total']),
      expenseTotal: _double(json['expense_total']),
      closingBalance: _double(json['closing_balance']),
      totalBills: json['total_bills'] ?? 0,
      paidBills: json['paid_bills'] ?? 0,
      unpaidBills: json['unpaid_bills'] ?? 0,
      notes: json['notes'],
    );
  }
}

class MaintenanceBill {
  final int id;
  final int periodId;
  final int residentId;
  final String residentName;
  final String? propertyName;
  final String? sectionName;
  final String? unitNumber;
  final double amount;
  final double carriedForward;
  final double lateFee;
  final double totalDue;
  final double amountPaid;
  final double balance;
  final DateTime dueDate;
  final String status;
  final DateTime? paidAt;

  const MaintenanceBill({
    required this.id,
    required this.periodId,
    required this.residentId,
    required this.residentName,
    this.propertyName,
    this.sectionName,
    this.unitNumber,
    required this.amount,
    required this.carriedForward,
    required this.lateFee,
    required this.totalDue,
    required this.amountPaid,
    required this.balance,
    required this.dueDate,
    required this.status,
    this.paidAt,
  });

  factory MaintenanceBill.fromJson(Map<String, dynamic> json) {
    return MaintenanceBill(
      id: json['id'],
      periodId: json['period_id'],
      residentId: json['resident_id'],
      residentName: json['resident_name'] ?? 'Resident',
      propertyName: json['property_name'],
      sectionName: json['section_name'],
      unitNumber: json['unit_number'],
      amount: _double(json['amount']),
      carriedForward: _double(json['carried_forward']),
      lateFee: _double(json['late_fee']),
      totalDue: _double(json['total_due']),
      amountPaid: _double(json['amount_paid']),
      balance: _double(json['balance']),
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'] ?? 'UNPAID',
      paidAt: json['paid_at'] == null ? null : DateTime.parse(json['paid_at']),
    );
  }
}

class MaintenanceExpense {
  final int id;
  final int periodId;
  final String category;
  final String description;
  final double amount;
  final DateTime spentOn;
  final DateTime createdAt;

  const MaintenanceExpense({
    required this.id,
    required this.periodId,
    required this.category,
    required this.description,
    required this.amount,
    required this.spentOn,
    required this.createdAt,
  });

  factory MaintenanceExpense.fromJson(Map<String, dynamic> json) {
    return MaintenanceExpense(
      id: json['id'],
      periodId: json['period_id'],
      category: json['category'],
      description: json['description'],
      amount: _double(json['amount']),
      spentOn: DateTime.parse(json['spent_on']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class MaintenanceDashboard {
  final MaintenancePeriod? period;
  final List<MaintenanceBill> bills;
  final List<MaintenanceExpense> expenses;

  const MaintenanceDashboard({
    this.period,
    required this.bills,
    required this.expenses,
  });

  factory MaintenanceDashboard.fromJson(Map<String, dynamic> json) {
    return MaintenanceDashboard(
      period: json['period'] == null
          ? null
          : MaintenancePeriod.fromJson(json['period']),
      bills: (json['bills'] as List? ?? [])
          .map((e) => MaintenanceBill.fromJson(e))
          .toList(),
      expenses: (json['expenses'] as List? ?? [])
          .map((e) => MaintenanceExpense.fromJson(e))
          .toList(),
    );
  }
}

class ResidentMaintenanceSummary {
  final MaintenanceBill? bill;
  final List<MaintenanceBill> history;

  const ResidentMaintenanceSummary({
    this.bill,
    required this.history,
  });

  factory ResidentMaintenanceSummary.fromJson(Map<String, dynamic> json) {
    return ResidentMaintenanceSummary(
      bill: json['bill'] == null ? null : MaintenanceBill.fromJson(json['bill']),
      history: (json['history'] as List? ?? [])
          .map((e) => MaintenanceBill.fromJson(e))
          .toList(),
    );
  }
}

double _double(dynamic value) => double.tryParse(value?.toString() ?? '0') ?? 0;


class MaintenancePaymentSettings {
  final String mode;
  final String? upiId;
  final String? displayName;
  final String? paymentPhone;
  final String lateFeeType;
  final double lateFeeValue;
  final int lateFeeGraceDays;

  const MaintenancePaymentSettings({
    required this.mode,
    this.upiId,
    this.displayName,
    this.paymentPhone,
    this.lateFeeType = 'NONE',
    this.lateFeeValue = 0,
    this.lateFeeGraceDays = 0,
  });

  factory MaintenancePaymentSettings.fromJson(Map<String, dynamic> json) {
    return MaintenancePaymentSettings(
      mode: json['mode']?.toString() ?? 'RAZORPAY',
      upiId: json['upi_id']?.toString(),
      displayName: json['display_name']?.toString(),
      paymentPhone: json['payment_phone']?.toString(),
      lateFeeType: json['late_fee_type']?.toString() ?? 'NONE',
      lateFeeValue: (json['late_fee_value'] as num?)?.toDouble() ?? 0,
      lateFeeGraceDays: (json['late_fee_grace_days'] as num?)?.toInt() ?? 0,
    );
  }
}

class DirectUPIPaymentSubmission {
  final int paymentId;
  final int billId;
  final String status;
  final String? reference;
  final String message;

  const DirectUPIPaymentSubmission({
    required this.paymentId,
    required this.billId,
    required this.status,
    required this.reference,
    required this.message,
  });

  factory DirectUPIPaymentSubmission.fromJson(Map<String, dynamic> json) {
    return DirectUPIPaymentSubmission(
      paymentId: json['payment_id'] ?? 0,
      billId: json['bill_id'] ?? 0,
      status: json['status']?.toString() ?? 'PENDING',
      reference: json['reference']?.toString(),
      message: json['message']?.toString() ?? '',
    );
  }
}

class PendingMaintenancePayment {
  final int id;
  final int billId;
  final int residentId;
  final String residentName;
  final String? unitNumber;
  final double amount;
  final String? reference;
  final String paymentMethod;
  final String status;
  final DateTime paidAt;

  const PendingMaintenancePayment({
    required this.id,
    required this.billId,
    required this.residentId,
    required this.residentName,
    this.unitNumber,
    required this.amount,
    this.reference,
    required this.paymentMethod,
    required this.status,
    required this.paidAt,
  });

  factory PendingMaintenancePayment.fromJson(Map<String, dynamic> json) {
    return PendingMaintenancePayment(
      id: json['id'],
      billId: json['bill_id'],
      residentId: json['resident_id'],
      residentName: json['resident_name'] ?? 'Resident',
      unitNumber: json['unit_number'],
      amount: _double(json['amount']),
      reference: json['reference']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? 'DIRECT_UPI',
      status: json['status']?.toString() ?? 'PENDING',
      paidAt: DateTime.parse(json['paid_at']),
    );
  }
}
