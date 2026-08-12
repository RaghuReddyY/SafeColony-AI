class EmergencyAlert {
  final int id;
  final int? organizationId;
  final int? residentId;
  final int? raisedByUserId;
  final String? raisedByName;
  final String? sourceRole;
  final String? unitNumber;
  final String title;
  final String message;
  final String alertType;
  final String severity;
  final bool isResolved;
  final int? resolvedByUserId;
  final String? resolvedByName;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  const EmergencyAlert({
    required this.id,
    required this.organizationId,
    required this.residentId,
    required this.raisedByUserId,
    required this.raisedByName,
    required this.sourceRole,
    required this.unitNumber,
    required this.title,
    required this.message,
    required this.alertType,
    required this.severity,
    required this.isResolved,
    required this.resolvedByUserId,
    required this.resolvedByName,
    required this.resolvedAt,
    required this.createdAt,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: (json['id'] as num).toInt(),
      organizationId: (json['organization_id'] as num?)?.toInt(),
      residentId: (json['resident_id'] as num?)?.toInt(),
      raisedByUserId: (json['raised_by_user_id'] as num?)?.toInt(),
      raisedByName: json['raised_by_name'] as String?,
      sourceRole: json['source_role'] as String?,
      unitNumber: json['unit_number'] as String?,
      title: json['title'] as String? ?? 'Emergency SOS',
      message: json['message'] as String? ?? '',
      alertType: json['alert_type'] as String? ?? 'GENERAL',
      severity: json['severity'] as String? ?? 'CRITICAL',
      isResolved: json['is_resolved'] as bool? ?? false,
      resolvedByUserId: (json['resolved_by_user_id'] as num?)?.toInt(),
      resolvedByName: json['resolved_by_name'] as String?,
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.tryParse(json['resolved_at'].toString()),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}
