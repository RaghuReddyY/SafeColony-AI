import '../../../core/utils/api_date_time.dart';
class Incident {
  final int id;
  final String title;
  final String description;
  final String incidentType;
  final String severity;
  final String status;
  final String? location;
  final DateTime createdAt;
  Incident({
    required this.id, required this.title, required this.description,
    required this.incidentType, required this.severity, required this.status,
    this.location, required this.createdAt,
  });
  factory Incident.fromJson(Map<String,dynamic> j) => Incident(
    id: j['id'], title: j['title'] ?? '', description: j['description'] ?? '',
    incidentType: j['incident_type'] ?? '', severity: j['severity'] ?? 'MEDIUM',
    status: j['status'] ?? 'OPEN', location: j['location'],
    createdAt: ApiDateTime.parse(j['created_at']),
  );
}
