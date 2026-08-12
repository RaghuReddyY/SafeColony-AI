class GuardVisitor {
  final int id;

  // Existing fields used by Guard UI
  final String visitorName;
  final String phone;
  final String visitorType;
  final String purpose;
  final String vehicleNumber;

  final String status;

  // New fields for simplified visitor flow
  final String? qrToken;
  final String? entryMode;

  final DateTime? expectedAt;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;

  final String? residentName;
  final int? residentId;

  const GuardVisitor({
    required this.id,
    required this.visitorName,
    required this.phone,
    required this.visitorType,
    required this.purpose,
    required this.vehicleNumber,
    required this.status,
    this.qrToken,
    this.entryMode,
    this.expectedAt,
    this.checkedInAt,
    this.checkedOutAt,
    this.residentName,
    this.residentId,
  });

  factory GuardVisitor.fromJson(
    Map<String, dynamic> json,
  ) {
    return GuardVisitor(
      id: _toInt(json['id']),

      visitorName:
          json['visitor_name']?.toString() ??
          json['visitorName']?.toString() ??
          json['name']?.toString() ??
          '',

      phone:
          json['phone']?.toString() ??
          json['visitor_phone']?.toString() ??
          json['visitorPhone']?.toString() ??
          '',

      visitorType:
          json['visitor_type']?.toString() ??
          json['visitorType']?.toString() ??
          json['type']?.toString() ??
          'OTHER',

      purpose:
          json['purpose']?.toString() ??
          '',

      vehicleNumber:
          json['vehicle_number']?.toString() ??
          json['vehicleNumber']?.toString() ??
          '',

      status:
          json['status']?.toString() ??
          'PENDING',

      qrToken:
          json['qr_token']?.toString() ??
          json['qrToken']?.toString(),

      entryMode:
          json['entry_mode']?.toString() ??
          json['entryMode']?.toString(),

      expectedAt:
          _parseDate(
        json['expected_at'] ??
            json['expectedAt'],
      ),

      checkedInAt:
          _parseDate(
        json['checked_in_at'] ??
            json['checkedInAt'],
      ),

      checkedOutAt:
          _parseDate(
        json['checked_out_at'] ??
            json['checkedOutAt'],
      ),

      residentName:
          json['resident_name']?.toString() ??
          json['residentName']?.toString(),

      residentId:
          _toNullableInt(
        json['resident_id'] ??
            json['residentId'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visitor_name': visitorName,
      'phone': phone,
      'visitor_type': visitorType,
      'purpose': purpose,
      'vehicle_number': vehicleNumber,
      'status': status,
      'qr_token': qrToken,
      'entry_mode': entryMode,
      'expected_at':
          expectedAt?.toIso8601String(),
      'checked_in_at':
          checkedInAt?.toIso8601String(),
      'checked_out_at':
          checkedOutAt?.toIso8601String(),
      'resident_name': residentName,
      'resident_id': residentId,
    };
  }

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  bool get isPending =>
      status.toUpperCase() == 'PENDING';

  bool get isApproved =>
      status.toUpperCase() == 'APPROVED';

  bool get isRejected =>
      status.toUpperCase() == 'REJECTED';

  bool get isCheckedIn =>
      status.toUpperCase() == 'CHECKED_IN';

  bool get isCheckedOut =>
      status.toUpperCase() == 'CHECKED_OUT';

  // ============================================================
  // ENTRY MODE
  // ============================================================

bool get isWalkIn {
  final mode = entryMode?.toUpperCase().trim();

  return mode == 'WALK_IN';
}

bool get isResidentCreated {
  final mode = entryMode?.toUpperCase().trim();

  if (mode == 'RESIDENT_CREATED' ||
      mode == 'QR') {
    return true;
  }

  // Some backend responses may not contain entry_mode,
  // but resident-created visitors have a QR token.
  if (qrToken != null &&
      qrToken!.trim().isNotEmpty) {
    return true;
  }

  return false;
}

  // ============================================================
  // HELPERS
  // ============================================================

  static int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static int? _toNullableInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}