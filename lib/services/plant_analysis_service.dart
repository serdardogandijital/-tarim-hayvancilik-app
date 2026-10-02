import 'analysis_image.dart';
import 'analysis_credits.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_key_store.dart';
import '../models/plant_analysis.dart';

class PlantAnalysisService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  PlantAnalysisService({
    AnalysisCredits? credits,
    http.Client? client,
    Future<String?> Function()? apiKeyReader,
  }) : _credits = credits ?? AnalysisCredits.instance,
       _client = client ?? http.Client(),
       _apiKeyReader = apiKeyReader ?? ApiKeyStore.read;
  final AnalysisCredits _credits;
  final http.Client _client;
  final Future<String?> Function() _apiKeyReader;

  Future<PlantAnalysis> analyzePlant(
    String imagePath, {
    Future<PlantAnalysis> Function(PlantAnalysis)? persist,
  }) => _credits.run(() async {
    final result = await _analyzePlant(imagePath);
    return persist == null ? result : await persist(result);
  }, succeeded: (_) => true);

  Future<PlantAnalysis> _analyzePlant(String imagePath) async {
    try {
      // API key kontrolü
      final apiKey = await _apiKeyReader();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key gerekli. Lütfen ayarlardan API key girin.');
      }

      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Görsel dosyası bulunamadı: $imagePath');
      }

      final imageUrl = await AnalysisImage.dataUrl(imageFile);

      final prompt =
          '''Bu fotoğrafı analiz et. Fotoğrafta şunlardan biri olabilir:
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
- Bitki yoksa veya tanımlayamıyorsan {"error":"uncertain"} döndür; tahmin uydurma.
- Fotoğraf tek başına kesin hastalık teşhisi değildir; belirsizliği belirt.''';

      final requestBody = {
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {'url': imageUrl},
              },
            ],
          },
        ],
        'max_tokens': 2048,
        'temperature': 0.4,
      };

      final response = await _client
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('API hatası: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);
      final responseText =
          jsonResponse['choices'][0]['message']['content'] as String;

      return _parseResponse(responseText, imagePath);
    } catch (e) {
      throw Exception('Analiz hatası: ${e.toString()}');
    }
  }

  void dispose() => _client.close();

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

      final json = jsonDecode(jsonText) as Map<String, dynamic>;
      if (json.containsKey('error') ||
          json['plantName'] is! String ||
          (json['plantName'] as String).trim().isEmpty ||
          json['status'] is! String) {
        throw const FormatException('Bitki güvenilir biçimde tanımlanamadı');
      }
      final confidence = (json['confidence'] as num?)?.toDouble();
      if (confidence == null ||
          !confidence.isFinite ||
          confidence < 0 ||
          confidence > 1) {
        throw const FormatException('Geçersiz analiz yanıtı');
      }

      return PlantAnalysis(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        imagePath: imagePath,
        plantName: json['plantName'] as String? ?? 'Bilinmeyen Bitki',
        scientificName: json['scientificName'] as String? ?? '',
        status: json['status'] as String? ?? 'Analiz Edilemedi',
        confidence: confidence,
        diseases: (json['diseases'] as List?)?.cast<String>() ?? [],
        treatments:
            (json['treatments'] as List?)?.cast<String>() ??
            ['Detaylı inceleme gerekli'],
        careAdvice:
            (json['careAdvice'] as List?)?.cast<String>() ??
            ['Genel bitki bakımı uygulayın'],
        preventionTips:
            (json['preventionTips'] as List?)?.cast<String>() ??
            ['Düzenli kontrol yapın'],
        wateringSchedule:
            json['wateringSchedule'] as String? ?? 'İhtiyaca göre',
        fertilizingSchedule:
            json['fertilizingSchedule'] as String? ?? 'Belirlenemedi',
        harvestTime: json['harvestTime'] as String?,
      );
    } catch (_) {
      throw const FormatException(
        'Analiz tamamlanamadı. Daha net bir bitki fotoğrafıyla tekrar deneyin.',
      );
    }
  }
}
