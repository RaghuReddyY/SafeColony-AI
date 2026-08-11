import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/ai_message.dart';

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
}
