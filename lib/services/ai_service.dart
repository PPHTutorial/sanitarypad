import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/models/ai_chat_model.dart';

class AIService {
  final Dio _dio = Dio();
  static const String _defaultBaseUrl = 'https://api.openai.com/v1';
  static const String _defaultModel = 'gpt-3.5-turbo';

  /// Get API key from environment variables
  String? getApiKey() {
    return dotenv.env['OPENAI_API_KEY'];
  }

  /// Get API base URL from environment (with fallback)
  String getApiBaseUrl() {
    return dotenv.env['OPENAI_API_BASE_URL'] ?? _defaultBaseUrl;
  }

  /// Get model from environment (with fallback)
  String getModel() {
    return dotenv.env['OPENAI_MODEL'] ?? _defaultModel;
  }

  /// Check if API key is configured
  bool isConfigured() {
    final apiKey = getApiKey();
    return apiKey != null &&
        apiKey.isNotEmpty &&
        apiKey != 'sk-your-api-key-here';
  }

  /// Build system prompt based on category and context
  String _buildSystemPrompt(String category, Map<String, dynamic>? context) {
    final basePrompt =
        'You are FemCare+, a compassionate and knowledgeable AI assistant specialized in women\'s health, wellness, and self-care. You provide evidence-based, supportive, and empathetic guidance. Always remind users to consult healthcare professionals for medical concerns.';

    switch (category) {
      case 'pregnancy':
        final week = context?['pregnancyWeek'] as int?;
        final weekInfo = week != null
            ? ' The user is currently at week $week of pregnancy.'
            : '';
        return '$basePrompt$weekInfo Focus on pregnancy-related questions, prenatal care, fetal development, nutrition, and emotional support during pregnancy.';

      case 'fertility':
        return '$basePrompt Focus on fertility tracking, ovulation, cycle health, conception tips, and reproductive wellness.';

      case 'skincare':
        return '$basePrompt Focus on skincare routines, ingredient analysis, skin health, and personalized skincare advice.';

      default:
        return '$basePrompt Provide general wellness and health guidance.';
    }
  }

  /// Build context from user data for better responses
  Future<Map<String, dynamic>> _buildContext(
      String userId, String category) async {
    // This would fetch relevant user data (pregnancy week, cycle info, etc.)
    // For now, return empty context - can be enhanced later
    return {};
  }

  /// Send message to AI and get response
  Future<String> sendMessage({
    required String userId,
    required String category,
    required String message,
    required List<AIChatMessage> conversationHistory,
    Map<String, dynamic>? context,
  }) async {
    final apiKey = getApiKey();
    if (apiKey == null || apiKey.isEmpty || !isConfigured()) {
      throw Exception(
          'OpenAI API key not configured. Please contact support or check environment configuration.');
    }

    try {
      // Build messages for API
      final messages = <Map<String, String>>[];

      // Add system prompt
      final systemContext = context ?? await _buildContext(userId, category);
      messages.add({
        'role': 'system',
        'content': _buildSystemPrompt(category, systemContext),
      });

      // Add conversation history (last 10 messages to stay within token limits)
      final recentHistory = conversationHistory.length > 10
          ? conversationHistory.sublist(conversationHistory.length - 10)
          : conversationHistory;

      for (final msg in recentHistory) {
        messages.add({
          'role': msg.role,
          'content': msg.content,
        });
      }

      // Add current user message
      messages.add({
        'role': 'user',
        'content': message,
      });

      // Make API request
      final baseUrl = getApiBaseUrl();
      final model = getModel();

      final response = await _dio.post(
        '$baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 500, // Limit response length
        },
      );

      if (response.statusCode == 200) {
        final content =
            response.data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('error')) {
          final error = errorData['error'];
          throw Exception(error['message'] ?? 'AI service error');
        }
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to communicate with AI: $e');
    }
  }

  /// Test API key validity (for development/testing)
  Future<bool> testApiKey() async {
    final apiKey = getApiKey();
    if (apiKey == null || apiKey.isEmpty) return false;

    try {
      final baseUrl = getApiBaseUrl();
      final response = await _dio.get(
        '$baseUrl/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
