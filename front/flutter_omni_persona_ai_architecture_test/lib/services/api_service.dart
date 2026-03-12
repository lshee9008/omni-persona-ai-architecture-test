import 'package:dio/dio.dart';
import '../models/chat_message.dart';

class ApiService {
  final Dio _dio = Dio();

  final String baseUrl = 'http://localhost:8000';

  Future<String> sendMessage(String sessionId, String message) async {
    try {
      final response = await _dio.post(
        '$baseUrl/chat/',
        data: {
          'session_id': sessionId,
          'message': message,
          'persona': '친절하고 유능한 AI 어시스턴트',
        },
      );

      if (response.statusCode == 200) {
        return response.data['reply'];
      } else {
        throw Exception('API 통신 실패');
      }
    } catch (e) {
      print('에러 발생: $e');
      return "오류가 발생했습니다. 서버 연결을 확인해주세요.";
    }
  }
}
