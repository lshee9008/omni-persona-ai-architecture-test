import 'package:hive/hive.dart';

// 자동 생성될 파일 이름 지정
part 'chat_message.g.dart';

@HiveType(typeId: 0)
class ChatMessage {
  @HiveField(0)
  final String role;

  @HiveField(1)
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
