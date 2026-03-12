import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

// API 서비스 Provider
final apiServiceProvider = Provider((ref) => ApiService());

// 고유 세션 ID 생성 (앱 실행 시 한 번 생성)
final sessionIdProvider = Provider((ref) => const Uuid().v4());

// 채팅 목록 상태를 관리하는 Notifier
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier(this.ref) : super([]);

  final Ref ref;
  bool isLoading = false; // AI 응답 대기 상태

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. 사용자 메시지를 상태에 추가 (UI 즉각 반영)
    state = [...state, ChatMessage(role: 'user', content: text)];
    isLoading = true;

    // 2. API 호출
    final apiService = ref.read(apiServiceProvider);
    final sessionId = ref.read(sessionIdProvider);

    final aiReply = await apiService.sendMessage(sessionId, text);

    // 3. AI 응답을 상태에 추가
    isLoading = false;
    state = [...state, ChatMessage(role: 'assistant', content: aiReply)];
  }
}

// UI에서 접근할 Provider 선언
final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((
  ref,
) {
  return ChatNotifier(ref);
});
