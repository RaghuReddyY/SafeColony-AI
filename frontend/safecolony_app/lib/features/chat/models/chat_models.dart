import '../../../core/utils/api_date_time.dart';
class ChatUser {
  final int id;
  final String fullName;
  final String role;

  const ChatUser({required this.id, required this.fullName, required this.role});

  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
        id: (json['id'] as num).toInt(),
        fullName: json['full_name']?.toString() ?? 'User',
        role: json['role']?.toString() ?? 'USER',
      );
}

class ChatAttachment {
  final int id;
  final String fileName;
  final String contentType;
  final int fileSize;
  final String fileUrl;
  final DateTime createdAt;
  const ChatAttachment({required this.id, required this.fileName, required this.contentType, required this.fileSize, required this.fileUrl, required this.createdAt});
  factory ChatAttachment.fromJson(Map<String,dynamic> j) => ChatAttachment(
    id: (j['id'] as num).toInt(), fileName: j['file_name']?.toString() ?? 'Attachment',
    contentType: j['content_type']?.toString() ?? '', fileSize: (j['file_size'] as num?)?.toInt() ?? 0,
    fileUrl: j['file_url']?.toString() ?? '', createdAt: ApiDateTime.parse(j['created_at']),
  );
}

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderUserId;
  final String senderName;
  final String senderRole;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final bool isDeleted;
  final List<ChatAttachment> attachments;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.isDeleted = false, this.attachments = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: (json['id'] as num).toInt(),
        conversationId: (json['conversation_id'] as num).toInt(),
        senderUserId: (json['sender_user_id'] as num).toInt(),
        senderName: json['sender_name']?.toString() ?? 'User',
        senderRole: json['sender_role']?.toString() ?? 'USER',
        content: json['content']?.toString() ?? '',
        createdAt: ApiDateTime.tryParse(json['created_at']) ?? DateTime.now(),
        updatedAt: ApiDateTime.tryParse(json['updated_at']),
        isEdited: json['is_edited'] == true,
        isDeleted: json['is_deleted'] == true,
        attachments: (json['attachments'] as List? ?? []).map((e) => ChatAttachment.fromJson(Map<String,dynamic>.from(e))).toList(),
      );
}

class ChatConversation {
  final int id;
  final String type;
  final String? name;
  final List<ChatUser> participants;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  const ChatConversation({
    required this.id,
    required this.type,
    this.name,
    required this.participants,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) => ChatConversation(
        id: (json['id'] as num).toInt(),
        type: json['conversation_type']?.toString() ?? 'DIRECT',
        name: json['name']?.toString(),
        participants: (json['participants'] as List? ?? [])
            .map((e) => ChatUser.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        lastMessage: json['last_message'] == null
            ? null
            : ChatMessage.fromJson(Map<String, dynamic>.from(json['last_message'])),
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
        updatedAt: ApiDateTime.tryParse(json['updated_at']) ?? DateTime.now(),
      );
}
