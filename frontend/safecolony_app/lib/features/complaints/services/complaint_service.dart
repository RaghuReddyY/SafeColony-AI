import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/complaint.dart';

class ComplaintService {
  Future<List<Complaint>> list() async {
    final Response r = await ApiClient.dio.get('/complaints');
    return (r.data as List).map((e) => Complaint.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Complaint> create({
    required String title,
    required String description,
    required String category,
    String priority = 'MEDIUM',
  }) async {
    final r = await ApiClient.dio.post('/complaints', data: {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
    });
    return Complaint.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<Complaint> update(int id, Map<String, dynamic> data) async {
    final r = await ApiClient.dio.put('/complaints/$id', data: data);
    return Complaint.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<Complaint> escalate(int id, String reason) async {
    final r = await ApiClient.dio.post('/complaints/$id/escalate', data: {'reason': reason});
    return Complaint.fromJson(Map<String, dynamic>.from(r.data));
  }
}
