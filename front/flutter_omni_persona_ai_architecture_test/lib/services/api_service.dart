import 'dart:convert';
import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = 'http://localhost:8000';

  // 일반 응답 대신 Stream<String>을 반환하도록 수정
  Stream<String> sendMessageStream(
    String sessionId,
    String message,
    String persona,
  ) async* {
    try {
      final response = await _dio.post(
        '$baseUrl/chat/stream',
        data: {
          'session_id': sessionId,
          'message': message,
          'persona': persona, // 선택된 페르소나 전달
        },
        // 통신 타입을 stream으로 지정
        options: Options(responseType: ResponseType.stream),
      );

      // 서버에서 들어오는 바이트 데이터를 문자열로 변환하여 Yield
      final stream = response.data.stream;
      await for (final chunk in stream) {
        yield utf8.decode(chunk);
      }
    } catch (e) {
      yield "오류가 발생했습니다.";
    }
  }
}
