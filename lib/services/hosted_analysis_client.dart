import 'dart:convert';
import 'package:http/http.dart' as http;

/// The server holds provider credentials; the installed app never asks for one.
class HostedAnalysisClient {
  HostedAnalysisClient(this.client);
  final http.Client client;

  static final endpoint = Uri.parse(
    const String.fromEnvironment(
      'ANALYSIS_API_URL',
      defaultValue:
          'https://elaborate-stroopwafel-974180.netlify.app/api/analyze',
    ),
  );

  Future<String> analyze({
    required String kind,
    required String prompt,
    required List<String> imageDataUrls,
  }) => _send({'kind': kind, 'prompt': prompt, 'images': imageDataUrls});

  Future<String> chat({
    required String message,
    required List<Map<String, String>> history,
  }) => _send({'kind': 'chat', 'message': message, 'history': history});

  Future<String> _send(Map<String, dynamic> body) async {
    if (endpoint.scheme != 'https') {
      throw const FormatException('Analiz bağlantısı güvenli değil.');
    }
    final response = await client
        .post(
          endpoint,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 55));
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Analiz yanıtı okunamadı.');
    }
    if (response.statusCode != 200) {
      throw FormatException(
        data['error'] is String
            ? data['error'] as String
            : 'Analiz hizmeti şu an yanıt vermiyor.',
      );
    }
    final text = data['text'];
    if (text is! String || text.trim().isEmpty) {
      throw const FormatException('Analiz yanıtı boş.');
    }
    return text;
  }
}
