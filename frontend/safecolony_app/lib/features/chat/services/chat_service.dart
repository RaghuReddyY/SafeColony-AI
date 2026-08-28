import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/api/api_client.dart';
import '../models/chat_models.dart';

class ChatService {
  Future<List<ChatUser>> users({String? search}) async {
    final response = await ApiClient.dio.get(
      '/chat/users',
      queryParameters: search == null || search.trim().isEmpty
          ? null
          : {'search': search.trim()},
    );

    return (response.data as List)
        .map(
          (e) => ChatUser.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<List<ChatConversation>> conversations() async {
    final response = await ApiClient.dio.get(
      '/chat/conversations',
    );

    return (response.data as List)
        .map(
          (e) => ChatConversation.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<ChatConversation> community() async {
    final response = await ApiClient.dio.get(
      '/chat/community',
    );

    return ChatConversation.fromJson(
      Map<String, dynamic>.from(
        response.data['conversation'],
      ),
    );
  }

  Future<ChatConversation> startDirect(
    int userId,
  ) async {
    final response = await ApiClient.dio.post(
      '/chat/direct/$userId',
    );

    return ChatConversation.fromJson(
      Map<String, dynamic>.from(
        response.data,
      ),
    );
  }

  Future<List<ChatMessage>> messages(
    int conversationId,
  ) async {
    final response = await ApiClient.dio.get(
      '/chat/conversations/$conversationId/messages',
    );

    return (response.data as List)
        .map(
          (e) => ChatMessage.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<ChatMessage> send(
    int conversationId,
    String content,
  ) async {
    final response = await ApiClient.dio.post(
      '/chat/conversations/$conversationId/messages',
      data: {
        'content': content,
      },
    );

    return ChatMessage.fromJson(
      Map<String, dynamic>.from(
        response.data,
      ),
    );
  }

  Future<ChatMessage> sendAttachment(
    int conversationId,
    String content,
    PlatformFile file,
  ) async {
    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception(
        'Unable to read the selected attachment.',
      );
    }

    final formData = FormData.fromMap({
      'content': content,
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.name,
      ),
    });

    final response = await ApiClient.dio.post(
      '/chat/conversations/$conversationId/messages',
      data: formData,
    );

    return ChatMessage.fromJson(
      Map<String, dynamic>.from(
        response.data,
      ),
    );
  }

  Future<ChatMessage> edit(
    int conversationId,
    int messageId,
    String content,
  ) async {
    final response = await ApiClient.dio.put(
      '/chat/conversations/$conversationId/messages/$messageId',
      data: {
        'content': content,
      },
    );

    return ChatMessage.fromJson(
      Map<String, dynamic>.from(
        response.data,
      ),
    );
  }

  Future<ChatMessage> delete(
    int conversationId,
    int messageId,
  ) async {
    final response = await ApiClient.dio.delete(
      '/chat/conversations/$conversationId/messages/$messageId',
    );

    return ChatMessage.fromJson(
      Map<String, dynamic>.from(
        response.data,
      ),
    );
  }

  Future<void> markRead(
    int conversationId,
  ) async {
    await ApiClient.dio.post(
      '/chat/conversations/$conversationId/read',
    );
  }
}