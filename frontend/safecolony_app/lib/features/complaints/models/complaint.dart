import '../../../core/utils/api_date_time.dart';
class Complaint {
  final int id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final int? assignedToUserId;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolution;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.assignedToUserId,
    required this.createdAt,
    this.resolvedAt,
    this.resolution,
  });

  factory Complaint.fromJson(Map<String, dynamic> j) => Complaint(
    id: j['id'],
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    category: j['category'] ?? '',
    priority: j['priority'] ?? 'MEDIUM',
    status: j['status'] ?? 'OPEN',
    assignedToUserId: j['assigned_to_user_id'],
    createdAt: ApiDateTime.parse(j['created_at']),
    resolvedAt: j['resolved_at'] == null ? null : ApiDateTime.parse(j['resolved_at']),
    resolution: j['resolution'],
  );
}
