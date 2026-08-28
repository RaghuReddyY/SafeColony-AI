import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/ai_message.dart';
import '../models/ai_overview.dart';

class AIAssistantService {
  Future<String> chat(List<AIMessage> messages, {String? language}) async {
    final Response response = await ApiClient.dio.post(
      '/ai/chat',
      data: {
        'messages': messages.map((message) => message.toJson()).toList(),
        'language': language,
      },
    );

    return response.data['message'] as String;
  }

  Future<AIOverview> overview() async {
    final Response response = await ApiClient.dio.get('/ai/overview');
    return AIOverview.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<AIActionResult> action({required String message, bool confirmed=false, int? eventId, List<Map<String,dynamic>>? items, Map<String,dynamic>? serviceRequest}) async {
    final r=await ApiClient.dio.post('/ai/action',data:{'message':message,'confirmed':confirmed,'event_id':eventId,'items':items,'service_request':serviceRequest});
    return AIActionResult.fromJson(Map<String,dynamic>.from(r.data));
  }

  Future<String> report(String reportType) async {
    final Response response = await ApiClient.dio.post(
      '/ai/report',
      data: {'report_type': reportType},
    );
    return response.data['content']?.toString() ?? 'No report data available.';
  }
}


class AIActionResult {
  final String intent, action, preview; final bool requiresConfirmation; final Map<String,dynamic>? result;
  AIActionResult({required this.intent,required this.action,required this.preview,required this.requiresConfirmation,this.result});
  factory AIActionResult.fromJson(Map<String,dynamic> j)=>AIActionResult(intent:j['intent']?.toString()??'',action:j['action']?.toString()??'',preview:j['preview']?.toString()??'',requiresConfirmation:j['requires_confirmation']==true,result:j['result']==null?null:Map<String,dynamic>.from(j['result']));
}
