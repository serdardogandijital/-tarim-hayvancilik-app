import 'package:http/http.dart' as http;
import 'hosted_analysis_client.dart';

class AIChatService {
  AIChatService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final List<Map<String, String>> _chatHistory = [];

  Future<String> sendMessage(String message) async {
    try {
      final response = await HostedAnalysisClient(
        _client,
      ).chat(message: message, history: _chatHistory);
      _chatHistory.add({'role': 'user', 'text': message});
      _chatHistory.add({'role': 'assistant', 'text': response});
      if (_chatHistory.length > 8) {
        _chatHistory.removeRange(0, _chatHistory.length - 8);
      }
      return response;
    } catch (_) {
      return 'Bağlantı veya analiz hizmeti hatası oluştu. Lütfen daha sonra tekrar deneyin.';
    }
  }

  Future<String> getQuickAnswer(String question) => sendMessage(question);

  void resetChat() => _chatHistory.clear();

  void dispose() => _client.close();
}
