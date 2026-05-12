import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AiServiceException implements Exception {
  const AiServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AiService {
  AiService({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    http.Client? client,
    Duration timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       _timeout = timeout;

  final String apiKey;
  final String baseUrl;
  final String model;
  final http.Client _client;
  final Duration _timeout;

  Future<String> chat(String message, List<Map<String, String>> history) async {
    return chatRaw([
      {'role': 'system', 'content': '你是课表星图的 AI 日程助手。帮助用户规划学习、安排复习、分析课程安排。回答简洁实用。'},
      ...history,
      {'role': 'user', 'content': message},
    ]);
  }

  Future<String> chatRaw(List<Map<String, String>> messages, {double temperature = 0.7, int maxTokens = 1024, double frequencyPenalty = 0, double presencePenalty = 0}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'temperature': temperature,
              'max_tokens': maxTokens,
              'frequency_penalty': frequencyPenalty,
              'presence_penalty': presencePenalty,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiServiceException(_parseError(response.body));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw const AiServiceException('AI 未返回有效回复');
      }
      return (choices.first as Map<String, dynamic>)['message']['content'] as String? ?? '';
    } on AiServiceException {
      rethrow;
    } on TimeoutException {
      throw const AiServiceException('AI 响应超时，请重试');
    } on SocketException {
      throw const AiServiceException('无法连接 AI 服务，请检查网络');
    } on Object catch (e) {
      throw AiServiceException('请求失败: $e');
    }
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['error']['message'] as String? ?? 'API 请求失败';
    } catch (_) {
      return 'API 请求失败';
    }
  }
}
