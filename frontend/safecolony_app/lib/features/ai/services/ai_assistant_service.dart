import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/ai_message.dart';
import '../models/ai_overview.dart';

class AIAssistantService {
  Future<String> chat(List<AIMessage> messages) async {
    final Response response = await ApiClient.dio.post(
      '/ai/chat',
      data: {
        'messages': messages.map((message) => message.toJson()).toList(),
      },
    );

    return response.data['message'] as String;
  }

  Future<AIOverview> overview() async {
    final Response response = await ApiClient.dio.get('/ai/overview');
    return AIOverview.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<String> report(String reportType) async {
    final Response response = await ApiClient.dio.post(
      '/ai/report',
      data: {'report_type': reportType},
    );
    return response.data['content']?.toString() ?? 'No report data available.';
  }
}
