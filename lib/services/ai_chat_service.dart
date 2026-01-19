import 'dart:convert';
import 'package:http/http.dart' as http;

class AIChatService {
  static const String _apiKey = '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';
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  
  final List<Map<String, dynamic>> _chatHistory = [];
  
  static const String _systemPrompt = '''Sen deneyimli bir veteriner hekim AI asistanısın. 
Türkiye'deki çiftçilere ve hayvancılara online veteriner hizmeti veriyorsun. 

Görevlerin:
1. Hayvan hastalıklarını teşhis etmek ve tedavi önerileri vermek
2. Acil durum müdahalelerinde rehberlik etmek
3. Aşı ve ilaç önerileri sunmak
4. Beslenme ve bakım tavsiyeleri vermek
5. Gerektiğinde fiziksel veteriner muayenesi önerisi yapmak

Kurallar:
- Profesyonel ve güvenilir ol
- Türkçe konuş
- Acil durumlarda hemen veteriner çağrılmasını öner
- Pratik ve uygulanabilir çözümler sun
- Hayvan refahını her zaman önceliklendir''';
  
  AIChatService() {
    _chatHistory.add({
      'role': 'system',
      'content': _systemPrompt,
    });
  }
  
  Future<String> sendMessage(String message) async {
    try {
      _chatHistory.add({
        'role': 'user',
        'content': message,
      });

      final requestBody = {
        'model': 'gpt-4o-mini',
        'messages': _chatHistory,
        'temperature': 0.7,
        'max_tokens': 1024,
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('API hatası: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);
      final responseText = jsonResponse['choices'][0]['message']['content'] as String;
      
      _chatHistory.add({
        'role': 'assistant',
        'content': responseText,
      });

      return responseText;
    } catch (e) {
      if (e.toString().contains('API') || e.toString().contains('key')) {
        return '''🔑 API Key Hatası!

ChatGPT API kullanmak için:
1. https://platform.openai.com/api-keys adresine git
2. API key oluştur
3. lib/services/ai_chat_service.dart dosyasında _apiKey değişkenine ekle

Şimdilik demo moddasınız.''';
      }
      return 'Bir hata oluştu: ${e.toString()}';
    }
  }
  
  Future<String> getQuickAnswer(String question) async {
    final quickAnswers = {
      'bugün ne yapmalıyım': '''📋 Bugünün Önerileri:

1. ✅ Hayvanları kontrol et (sağlık, su, yem)
2. 🌡️ Hava durumunu kontrol et
3. 💉 Yaklaşan aşıları kontrol et
4. 🌾 Tarla görevlerini gözden geçir
5. 📝 Günlük kayıtları tut

Daha detaylı yardım için sohbet başlat!''',
      
      'hastalık': '''🏥 Hastalık Belirtileri:

Hayvanınızda şu belirtileri kontrol edin:
• Ateş (normal: 38.5°C)
• İştah kaybı
• Halsizlik
• Anormal dışkı
• Öksürük/burun akıntısı

⚠️ Acil: Hemen veteriner çağırın!
📞 Hafif: 24 saat izleyin''',
      
      'yem': '''🌾 Yem Önerileri:

Büyükbaş için:
• Kuru ot: 8-12 kg/gün
• Konsantre: 2-4 kg/gün
• Temiz su: Sınırsız

Küçükbaş için:
• Kuru ot: 1-2 kg/gün
• Konsantre: 0.5-1 kg/gün

💡 Mevsime göre ayarlayın!''',
    };
    
    for (var entry in quickAnswers.entries) {
      if (question.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    
    return await sendMessage(question);
  }
  
  void resetChat() {
    _chatHistory.clear();
    _chatHistory.add({
      'role': 'system',
      'content': _systemPrompt,
    });
  }
}
