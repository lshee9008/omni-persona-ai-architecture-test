import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

// 선택된 페르소나 상태 관리
final personaProvider = StateProvider<String>((ref) => '친절한 어시스턴트');

// 페르소나 목록
final personaList = [
  '친절한 어시스턴트',
  '엄격한 시니어 코드 리뷰어',
  '유쾌한 원어민 영어 튜터',
  '창의적인 마케팅 카피라이터',
];

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

  Future<void> sendMessage(String text, String currentPersona) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(role: 'user', content: text);
    _addMessageAndSave(userMessage); // 사용자 메시지 저장

    // AI가 대답할 빈 메시지 박스 미리 생성 (UI에 빈 말풍선 띄우기)
    int aiMessageIndex = state.length;
    _addMessageAndSave(ChatMessage(role: 'assistant', content: ''));

    final apiService = ref.read(apiServiceProvider);
    final sessionId = ref.read(sessionIdProvider);

    String fullReply = "";

    // Stream 데이터 구독 시작
    await for (final chunk in apiService.sendMessageStream(
      sessionId,
      text,
      currentPersona,
    )) {
      fullReply += chunk; // 들어오는 글자를 계속 이어붙임

      // Riverpod 상태 업데이트 (UI에 타이핑 효과 발생)
      final updatedMessages = List<ChatMessage>.from(state);
      updatedMessages[aiMessageIndex] = ChatMessage(
        role: 'assistant',
        content: fullReply,
      );
      state = updatedMessages;
    }

    // 통신이 완전히 끝나면 최종 결과물을 Hive(로컬 DB)에 덮어쓰기 업데이트
    _chatBox.putAt(
      aiMessageIndex,
      ChatMessage(role: 'assistant', content: fullReply),
    );
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
