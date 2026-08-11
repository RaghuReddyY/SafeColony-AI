class AIMessage {
  final String role;
  final String content;

  const AIMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}
