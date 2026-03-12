class ChatMessage {
  final String role; // 'user' 또는 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  // FastAPI로 보낼 때 JSON으로 변환
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
