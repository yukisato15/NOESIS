class AIChatMessage {
  final String role; // 'user', 'assistant', 'system'
  final String content;

  AIChatMessage({
    required this.role,
    required this.content,
  });

  factory AIChatMessage.fromJson(Map<String, dynamic> json) {
    return AIChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}
