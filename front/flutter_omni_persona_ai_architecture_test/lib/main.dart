import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/chat_message.dart';
import 'screens/chat_screen.dart';

void main() async {
  // Flutter 엔진 초기화 보장 (비동기 처리 시 필수)
  WidgetsFlutterBinding.ensureInitialized();

  // Hive 로컬 DB 초기화
  await Hive.initFlutter();

  // Hive에 생성한 모델(Adapter) 등록
  Hive.registerAdapter(ChatMessageAdapter());

  // 'chat_box'라는 이름의 로컬 저장소 열기
  await Hive.openBox<ChatMessage>('chat_box');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omni Persona AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // 최신 플러터 디자인 적용
      ),
      home: ChatScreen(),
    );
  }
}
