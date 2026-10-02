import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_key_store.dart';

class AIChatService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  String? _apiKey;
  final List<Map<String, dynamic>> _chatHistory = [];

  static Future<String?> getApiKey() => ApiKeyStore.read();

  static Future<void> setApiKey(String apiKey) => ApiKeyStore.write(apiKey);
  static Future<void> clearApiKey() => ApiKeyStore.clear();

  // API Key ayarlı mı kontrol et
  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  static const String _systemPrompt =
      '''Sen çiftçilere Türkçe bilgi veren bir tarım ve hayvan bakımı asistanısın.
Veteriner hekim olduğunu veya uzaktan kesin teşhis koyduğunu iddia etme.
Belirtilerde tür, yaş, süre ve şiddeti sor; belirsizliği açıkça belirt.
Acil belirtilerde yerel veterinere başvurulmasını öner.
Muayenesiz ilaç veya doz reçeteleme. Beslenme ve bakım için genel bilgi ver.''';

  AIChatService() {
    _chatHistory.add({'role': 'system', 'content': _systemPrompt});
  }

  Future<String> sendMessage(String message) async {
    try {
      // API key'i kontrol et
      _apiKey = await getApiKey();

      if (_apiKey == null || _apiKey!.isEmpty) {
        return '''🔑 API Key Gerekli!

Online Veteriner hizmetini kullanmak için ChatGPT API key girmeniz gerekiyor.

📝 Nasıl API Key Alınır:
1. https://platform.openai.com/api-keys adresine gidin
2. Hesap oluşturun veya giriş yapın
3. "Create new secret key" butonuna tıklayın
4. Oluşan key'i kopyalayın

⚙️ API Key'i girmek için sağ üstteki ayarlar (⚙️) butonuna tıklayın.''';
      }

      _chatHistory.add({'role': 'user', 'content': message});

      final requestBody = {
        'model': 'gpt-4o-mini',
        'messages': _chatHistory,
        'temperature': 0.7,
        'max_tokens': 1024,
      };

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) {
        _chatHistory.removeLast(); // Kullanıcı mesajını geri al
        return '''❌ API Key Geçersiz!

Girdiğiniz API key çalışmıyor. Lütfen kontrol edin:
- Key doğru kopyalandı mı?
- Key aktif mi?
- Hesabınızda kredi var mı?

⚙️ Yeni key girmek için ayarlar butonuna tıklayın.''';
      }

      if (response.statusCode != 200) {
        _chatHistory.removeLast();
        throw Exception('API hatası: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);
      final responseText =
          jsonResponse['choices'][0]['message']['content'] as String;

      _chatHistory.add({'role': 'assistant', 'content': responseText});

      return responseText;
    } catch (e) {
      // Son eklenen kullanıcı mesajını kaldır
      if (_chatHistory.isNotEmpty && _chatHistory.last['role'] == 'user') {
        _chatHistory.removeLast();
      }
      return '⚠️ Bağlantı hatası oluştu. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.';
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
• Hayvanın türüne ve yaşına göre anormal vücut sıcaklığı
• İştah kaybı
• Halsizlik
• Anormal dışkı
• Öksürük/burun akıntısı

⚠️ Acil: Hemen veteriner çağırın!
📞 Belirtileri veterinerinizle paylaşın''',

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
    _chatHistory.add({'role': 'system', 'content': _systemPrompt});
  }
}
