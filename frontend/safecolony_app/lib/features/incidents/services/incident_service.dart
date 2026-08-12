import '../../../core/api/api_client.dart';
import '../models/incident.dart';

class IncidentService {
  Future<List<Incident>> list() async {
    final r = await ApiClient.dio.get('/incidents');
    return (r.data as List).map((e) => Incident.fromJson(Map<String,dynamic>.from(e))).toList();
  }
  Future<Incident> create({
    required String title, required String description,
    required String incidentType, String severity = 'MEDIUM', String? location,
  }) async {
    final r = await ApiClient.dio.post('/incidents', data: {
      'title': title, 'description': description, 'incident_type': incidentType,
      'severity': severity, 'location': location,
    });
    return Incident.fromJson(Map<String,dynamic>.from(r.data));
  }
  Future<Incident> update(int id, Map<String,dynamic> data) async {
    final r = await ApiClient.dio.put('/incidents/$id', data: data);
    return Incident.fromJson(Map<String,dynamic>.from(r.data));
  }
}
