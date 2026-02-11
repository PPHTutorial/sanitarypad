import 'package:cloud_functions/cloud_functions.dart';
import '../data/models/ai_chat_model.dart';
import '../core/firebase/firebase_service.dart';

class AIService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Check if API key is configured
  /// With Cloud Functions, configuration is server-side, so this is always true
  /// unless we add a specific check function.
  bool isConfigured() {
    return true;
  }

  /// Send message to AI and get response
  Future<String> sendMessage({
    required String userId,
    required String category,
    required String message,
    required List<AIChatMessage> conversationHistory,
    Map<String, dynamic>? context,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateAIResponse');

      final response = await callable.call({
        'category': category,
        'message': message,
        'conversationHistory': conversationHistory
            .map((m) => {
                  'role': m.role,
                  'content': m.content,
                })
            .toList(),
        'userContext': context ?? {},
      });

      final data = response.data as Map<dynamic, dynamic>;

      if (data.containsKey('response')) {
        return data['response'] as String;
      } else {
        throw Exception('Invalid response format from server');
      }
    } on FirebaseFunctionsException catch (e) {
      await FirebaseService.recordError(e, null,
          reason: 'AI_Service_CloudFunction');
      throw Exception(e.message ?? 'AI service error');
    } catch (e) {
      await FirebaseService.recordError(e, null, reason: 'AI_Service_General');
      throw Exception('Failed to communicate with AI: $e');
    }
  }

  // No longer needed, as key is server-side
  Future<bool> testApiKey() async {
    return true;
  }

  /// Analyze skin image using specialized Cloud Function
  Future<Map<String, dynamic>> analyzeSkinImage({
    required String imageUrl,
  }) async {
    try {
      final callable = _functions.httpsCallable('analyzeSkinImage');
      final response = await callable.call({'imageUrl': imageUrl});
      return Map<String, dynamic>.from(response.data as Map);
    } on FirebaseFunctionsException catch (e) {
      await FirebaseService.recordError(e, null,
          reason: 'AI_Service_SkinAnalysis');
      throw Exception(e.message ?? 'Skin analysis failed');
    } catch (e) {
      await FirebaseService.recordError(e, null,
          reason: 'AI_Service_SkinAnalysis_General');
      throw Exception('Failed to communicate with skin analysis service: $e');
    }
  }
}
