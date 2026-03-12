import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());
final sessionIdProvider = Provider((ref) => const Uuid().v4());

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier(this.ref) : super([]) {
    _loadMessagesFromHive(); // 객체 생성 시 로컬 DB에서 데이터 불러오기
  }

  final Ref ref;
  bool isLoading = false;
  final Box<ChatMessage> _chatBox = Hive.box<ChatMessage>('chat_box');

  // 로컬 DB(Hive)에서 기존 대화 불러오기
  void _loadMessagesFromHive() {
    if (_chatBox.isNotEmpty) {
      state = _chatBox.values.toList();
    }
  }

  // 상태 업데이트 및 Hive 저장 공통 메서드
  void _addMessageAndSave(ChatMessage message) {
    state = [...state, message];
    _chatBox.add(message); // 로컬 DB에 추가
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. 사용자 메시지 추가 및 저장
    final userMessage = ChatMessage(role: 'user', content: text);
    _addMessageAndSave(userMessage);

    isLoading = true;

    // 2. 백엔드(FastAPI) 호출
    final apiService = ref.read(apiServiceProvider);
    final sessionId = ref.read(sessionIdProvider);

    final aiReply = await apiService.sendMessage(sessionId, text);

    // 3. AI 응답 추가 및 저장
    isLoading = false;
    final aiMessage = ChatMessage(role: 'assistant', content: aiReply);
    _addMessageAndSave(aiMessage);
  }

  // (선택 사항) 대화 기록 초기화 기능
  Future<void> clearChat() async {
    await _chatBox.clear();
    state = [];
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((
  ref,
) {
  return ChatNotifier(ref);
});
