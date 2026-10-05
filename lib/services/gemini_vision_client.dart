import 'dart:convert';
import 'package:http/http.dart' as http;

/// Sends image-understanding requests with a user-owned key. Never log the key
/// or put it in a URL, and never bundle a shared project key in the mobile app.
class GeminiVisionClient {
  GeminiVisionClient(this.client);
  final http.Client client;
  static const model = 'gemini-3.8-flash';
  static final endpoint = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
  );

  Future<String> analyze({
    required String apiKey,
    required String prompt,
    required List<String> imageDataUrls,
    required List<String> labels,
    int maxOutputTokens = 4096,
    String thinkingLevel = 'medium',
  }) async {
    if (imageDataUrls.length != labels.length || imageDataUrls.isEmpty) {
      throw const FormatException('Görsel sayısı uygun değil');
    }
    final parts = <Map<String, dynamic>>[
      {'text': prompt},
    ];
    var encodedSize = 0;
    for (var i = 0; i < imageDataUrls.length; i++) {
      final dataUrl = imageDataUrls[i];
      const prefix = 'data:image/jpeg;base64,';
      if (!dataUrl.startsWith(prefix)) {
        throw const FormatException('Görsel biçimi uygun değil');
      }
      final encoded = dataUrl.substring(prefix.length);
      encodedSize += encoded.length;
      parts.add({'text': labels[i]});
      parts.add({
        'inline_data': {'mime_type': 'image/jpeg', 'data': encoded},
      });
    }
    if (encodedSize > 18 * 1024 * 1024) {
      throw const FormatException('Fotoğraflar birlikte çok büyük');
    }
    final body = {
      'contents': [
        {'role': 'user', 'parts': parts},
      ],
      'generationConfig': {
        'maxOutputTokens': maxOutputTokens,
        'responseMimeType': 'application/json',
        'thinkingConfig': {'thinkingLevel': thinkingLevel},
      },
    };
    final response = await client
        .post(
          endpoint,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const FormatException('Gemini API anahtarını kontrol edin.');
      }
      if (response.statusCode == 429) {
        throw const FormatException('Gemini kullanım sınırına ulaşıldı.');
      }
      throw FormatException('Gemini API hatası: ${response.statusCode}');
    }
    final parsed =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final candidates = parsed['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const FormatException('Gemini analiz yanıtı alınamadı');
    }
    final content = (candidates.first as Map)['content'] as Map?;
    final responseParts = content?['parts'] as List?;
    final text = responseParts
        ?.whereType<Map>()
        .map((part) => part['text'])
        .whereType<String>()
        .join('\n')
        .trim();
    if (text == null || text.isEmpty) {
      throw const FormatException('Gemini analiz yanıtı boş');
    }
    return text;
  }
}
