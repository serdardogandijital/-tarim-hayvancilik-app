import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_analysis.dart';

class PlantAnalysisService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _apiKeyPrefKey = 'openai_api_key';
  static const String _defaultApiKey = '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';

  PlantAnalysisService();

  // API Key'i SharedPreferences'tan al (yoksa default key kullan)
  static Future<String?> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_apiKeyPrefKey);
    return (savedKey != null && savedKey.isNotEmpty) ? savedKey : _defaultApiKey;
  }

  Future<PlantAnalysis> analyzePlant(String imagePath) async {
    try {
      print('🌿 Bitki analizi başlıyor: $imagePath');
      
      // API key kontrolü
      final apiKey = await _getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key gerekli. Lütfen ayarlardan API key girin.');
      }
      
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Görsel dosyası bulunamadı: $imagePath');
      }
      
      final imageBytes = await imageFile.readAsBytes();
      print('📸 Görsel okundu: ${imageBytes.length} bytes');
      
      final base64Image = base64Encode(imageBytes);
      print('🔄 Base64 encode tamamlandı');

      final prompt = '''Bu fotoğrafı analiz et. Fotoğrafta şunlardan biri olabilir:
- Çiçek veya süs bitkisi
- Tarla ürünü (arpa, buğday, yonca, fiğ, mısır, ayçiçeği, pamuk, şeker pancarı, patates, domates, biber, patlıcan, salatalık, fasulye, nohut, mercimek, çeltik vb.)
- Meyve ağacı veya meyve
- Sebze
- Yabani ot

Fotoğraftaki bitkiyi/ürünü tespit et ve aşağıdaki bilgileri JSON formatında ver:

{
  "plantName": "Bitki/Ürün adı (Türkçe) - örn: Arpa, Buğday, Yonca, Fiğ, Gül, Domates vb.",
  "scientificName": "Bilimsel adı (Latince)",
  "status": "Sağlıklı/Hastalıklı/Zararlı Var/Besin Eksikliği/Olgunlaşmamış/Hasat Zamanı",
  "confidence": 0.95,
  "diseases": ["Tespit edilen hastalıklar listesi - yoksa boş array"],
  "treatments": ["Tedavi önerileri - pratik ve uygulanabilir"],
  "careAdvice": ["Genel bakım tavsiyeleri - sulama, gübreleme, ilaçlama vb."],
  "preventionTips": ["Hastalık ve zararlı önleme ipuçları"],
  "wateringSchedule": "Sulama sıklığı (örn: Günde 1 kez, Haftada 2 kez, Yağmur sulaması yeterli)",
  "fertilizingSchedule": "Gübreleme sıklığı (örn: Ekimde, Kardeşlenmede, Ayda 1 kez)",
  "harvestTime": "Tahmini hasat zamanı veya olgunluk durumu"
}

Kurallar:
- Türkçe yanıt ver
- Türkiye iklim koşullarına uygun öneriler sun
- Tarla ürünleri için: ekim zamanı, hasat zamanı, verim artırma önerileri ver
- Pratik ve çiftçi dostu dil kullan
- Organik çözümleri önceliklendir
- Acil durumları belirt (don riski, kuraklık, hastalık yayılması vb.)
- JSON formatına kesinlikle uy
- Bitkiyi tanıyamasan bile en yakın tahmini yap, "bulunamadı" deme''';

      print('🤖 ChatGPT Vision API çağrılıyor...');
      
      final requestBody = {
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': prompt,
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                },
              },
            ],
          },
        ],
        'max_tokens': 2048,
        'temperature': 0.4,
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 HTTP Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('❌ API Hatası: ${response.body}');
        throw Exception('API hatası: ${response.statusCode} - ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      final responseText = jsonResponse['choices'][0]['message']['content'] as String;

      print('✅ API yanıtı alındı');
      print('📝 Yanıt metni: ${responseText.substring(0, responseText.length > 100 ? 100 : responseText.length)}...');

      return _parseResponse(responseText, imagePath);
    } catch (e) {
      print('❌ Analiz hatası: $e');
      print('📍 Hata detayı: ${e.runtimeType}');
      throw Exception('Analiz hatası: ${e.toString()}');
    }
  }

  PlantAnalysis _parseResponse(String responseText, String imagePath) {
    try {
      String jsonText = responseText.trim();
      
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      } else if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      
      jsonText = jsonText.trim();

      final Map<String, dynamic> json = {};
      final lines = jsonText.split('\n');
      
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line == '{' || line == '}') continue;
        
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            var key = parts[0].trim().replaceAll('"', '').replaceAll(',', '');
            var value = parts.sublist(1).join(':').trim().replaceAll(',', '');
            
            if (value.startsWith('[') && value.endsWith(']')) {
              value = value.substring(1, value.length - 1);
              final items = value.split('",').map((e) => e.trim().replaceAll('"', '')).where((e) => e.isNotEmpty).toList();
              json[key] = items;
            } else if (value == 'null') {
              json[key] = null;
            } else if (value.startsWith('"') && value.endsWith('"')) {
              json[key] = value.substring(1, value.length - 1);
            } else {
              try {
                json[key] = double.parse(value);
              } catch (_) {
                json[key] = value;
              }
            }
          }
        }
      }

      return PlantAnalysis(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        imagePath: imagePath,
        plantName: json['plantName'] as String? ?? 'Bilinmeyen Bitki',
        scientificName: json['scientificName'] as String? ?? '',
        status: json['status'] as String? ?? 'Analiz Edilemedi',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        diseases: (json['diseases'] as List?)?.cast<String>() ?? [],
        treatments: (json['treatments'] as List?)?.cast<String>() ?? ['Detaylı inceleme gerekli'],
        careAdvice: (json['careAdvice'] as List?)?.cast<String>() ?? ['Genel bitki bakımı uygulayın'],
        preventionTips: (json['preventionTips'] as List?)?.cast<String>() ?? ['Düzenli kontrol yapın'],
        wateringSchedule: json['wateringSchedule'] as String? ?? 'İhtiyaca göre',
        fertilizingSchedule: json['fertilizingSchedule'] as String? ?? 'Ayda 1 kez',
        harvestTime: json['harvestTime'] as String?,
      );
    } catch (e) {
      return PlantAnalysis(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        imagePath: imagePath,
        plantName: 'Analiz Hatası',
        scientificName: '',
        status: 'Analiz tamamlanamadı',
        confidence: 0.0,
        diseases: [],
        treatments: ['Lütfen tekrar deneyin veya daha net bir fotoğraf çekin'],
        careAdvice: [],
        preventionTips: [],
        wateringSchedule: 'Bilinmiyor',
        fertilizingSchedule: 'Bilinmiyor',
        harvestTime: null,
      );
    }
  }
}
