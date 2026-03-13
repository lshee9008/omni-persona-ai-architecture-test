import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerWidget {
  ChatScreen({super.key});

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 최신 메시지가 아래로 오도록 UI용으로 리스트 순서를 뒤집음 (자동 스크롤 효과)
    final chatMessages = ref.watch(chatProvider).reversed.toList();
    final chatNotifier = ref.read(chatProvider.notifier);
    final currentPersona = ref.watch(personaProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // 부드러운 배경색
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Omni Persona AI',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentPersona,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.blue,
                  ),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                  items: personaList.map((String persona) {
                    return DropdownMenuItem<String>(
                      value: persona,
                      child: Text(
                        persona,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      HapticFeedback.lightImpact(); // 진동 피드백
                      ref.read(personaProvider.notifier).state = newValue;
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 💬 1. 채팅 목록 영역
            Expanded(
              child: ListView.builder(
                reverse: true, // 💡 리스트를 밑에서부터 채움 (자동 스크롤 완벽 해결)
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                itemCount: chatMessages.length,
                itemBuilder: (context, index) {
                  final message = chatMessages[index];
                  final isUser = message.role == 'user';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isUser) ...[
                          // AI 아바타 아이콘
                          const CircleAvatar(
                            backgroundColor: Colors.blue,
                            radius: 16,
                            child: Icon(
                              Icons.smart_toy,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // 말풍선 본체
                        Flexible(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blue : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isUser ? 16 : 0),
                                bottomRight: Radius.circular(isUser ? 0 : 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            // 💡 일반 텍스트 대신 Markdown 적용
                            child: isUser
                                ? Text(
                                    message.content,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  )
                                : MarkdownBody(
                                    data: message.content.isEmpty
                                        ? "..."
                                        : message.content,
                                    selectable: true,
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 15,
                                        height: 1.5,
                                      ),
                                      // ✅ 수정됨: borderRadius 제거
                                      code: TextStyle(
                                        backgroundColor: Colors.grey[200],
                                      ),
                                      codeblockDecoration: BoxDecoration(
                                        color: Colors.grey[900],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ⌨️ 2. 세련된 입력창 영역
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5, // 💡 멀티라인 지원 (글이 길어지면 5줄까지 늘어남)
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF4F6F8),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 전송 버튼 (애니메이션 효과)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: chatNotifier.isLoading ? Colors.grey : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: chatNotifier.isLoading
                          ? null
                          : () {
                              HapticFeedback.mediumImpact(); // 햅틱 진동
                              chatNotifier.sendMessage(
                                _controller.text,
                                currentPersona,
                              );
                              _controller.clear();
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
