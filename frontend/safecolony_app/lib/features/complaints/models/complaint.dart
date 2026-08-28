import '../../../core/utils/api_date_time.dart';

class ComplaintAttachment {
  final int id;
  final String fileName;
  final String contentType;
  final int fileSize;
  final String fileUrl;
  final DateTime createdAt;

  const ComplaintAttachment({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.fileSize,
    required this.fileUrl,
    required this.createdAt,
  });

  factory ComplaintAttachment.fromJson(Map<String, dynamic> j) => ComplaintAttachment(
        id: (j['id'] as num).toInt(),
        fileName: j['file_name']?.toString() ?? 'Attachment',
        contentType: j['content_type']?.toString() ?? '',
        fileSize: (j['file_size'] as num?)?.toInt() ?? 0,
        fileUrl: j['file_url']?.toString() ?? '',
        createdAt: ApiDateTime.parse(j['created_at']),
      );
}

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
  final List<ComplaintAttachment> attachments;

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
    this.resolution, required this.attachments,
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
    attachments: (j['attachments'] as List? ?? []).map((e) => ComplaintAttachment.fromJson(Map<String,dynamic>.from(e))).toList(),
  );
}
