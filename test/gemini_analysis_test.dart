import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:tarim_hayvancilik_app/services/analysis_provider.dart';
import 'package:tarim_hayvancilik_app/services/livestock_ml_service.dart';
import 'package:tarim_hayvancilik_app/services/plant_analysis_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('analysis works without a user API key', () async {
    final credential = await AnalysisProviderStore.resolve();
    expect(credential.provider, AnalysisProvider.hosted);
    expect(credential.key, isEmpty);
  });

  test('default photo analysis calls the hosted service without a key', () async {
    final directory = await Directory.systemTemp.createTemp('ciftci_hosted_');
    addTearDown(() => directory.delete(recursive: true));
    final photo = await File('${directory.path}/animal.png').writeAsBytes(
      img.encodePng(img.Image(width: 4, height: 4)),
    );
    final service = LivestockMLService(
      client: MockClient((request) async {
        expect(request.url.host, 'elaborate-stroopwafel-974180.netlify.app');
        expect(request.url.path, '/api/analyze');
        expect(request.headers.containsKey('Authorization'), isFalse);
        expect(request.headers.containsKey('x-goog-api-key'), isFalse);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['kind'], 'livestock');
        expect(body['images'], hasLength(1));
        return http.Response('{"text":"{\\"weight\\":520}"}', 200);
      }),
    );
    expect((await service.analyzeImage(photo))['weight'], 520);
    service.dispose();
  });

  test(
    'Gemini receives all three labeled images and returns only a checked estimate',
    () async {
      final directory = await Directory.systemTemp.createTemp('ciftci_gemini_');
      addTearDown(() => directory.delete(recursive: true));
      final photos = <File>[];
      for (var i = 0; i < 3; i++) {
        final image = img.Image(width: 4, height: 4);
        img.fill(
          image,
          color: img.ColorRgb8(
            i == 0 ? 255 : 0,
            i == 1 ? 255 : 0,
            i == 2 ? 255 : 0,
          ),
        );
        photos.add(
          await File(
            '${directory.path}/$i.png',
          ).writeAsBytes(img.encodePng(image)),
        );
      }
      var calls = 0;
      final service = LivestockMLService(
        credentialReader: () async =>
            const AnalysisCredential(AnalysisProvider.gemini, 'personal-key'),
        client: MockClient((request) async {
          calls++;
          expect(request.url.host, 'generativelanguage.googleapis.com');
          expect(request.headers['x-goog-api-key'], 'personal-key');
          expect(request.url.query, isEmpty);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final config = body['generationConfig'] as Map<String, dynamic>;
          expect(config.containsKey('temperature'), isFalse);
          expect(config['maxOutputTokens'], 4096);
          expect(config['thinkingConfig'], {'thinkingLevel': 'medium'});
          final parts = ((body['contents'] as List).single['parts'] as List);
          expect(parts.where((p) => p['inline_data'] != null), hasLength(3));
          for (var i = 0; i < 3; i++) {
            expect(
              parts[1 + i * 2]['text'],
              contains(['ÖNDEN', 'YANDAN', 'ARKADAN'][i]),
            );
            final imagePart = parts[2 + i * 2]['inline_data'];
            expect(imagePart['mime_type'], 'image/jpeg');
            expect(img.decodeJpg(base64Decode(imagePart['data']))?.width, 4);
          }
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': '{"photoCheck":"usable","weight":534}'},
                    ],
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final result = await service.analyzeImages(photos);
      expect(result['weight'], 534);
      expect(result['method'], 'Gemini Vision AI');
      expect(calls, 1);
      service.dispose();
    },
  );

  test(
    'Gemini plant response follows existing validation and errors do not spend a credit',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'ciftci_gemini_plant_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final photo = await File(
        '${directory.path}/plant.png',
      ).writeAsBytes(img.encodePng(img.Image(width: 4, height: 4)));
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final config = body['generationConfig'] as Map<String, dynamic>;
        expect(config['thinkingConfig'], {'thinkingLevel': 'low'});
        final parts = ((body['contents'] as List).single['parts'] as List);
        expect(parts.where((p) => p['inline_data'] != null), hasLength(1));
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': calls == 1
                          ? '{"error":"uncertain"}'
                          : '{"plantName":"Buğday","status":"İnceleme gerekli","confidence":0.6}',
                    },
                  ],
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final service = PlantAnalysisService(
        client: client,
        credentialReader: () async =>
            const AnalysisCredential(AnalysisProvider.gemini, 'personal-key'),
      );
      await expectLater(service.analyzePlant(photo.path), throwsException);
      final result = await service.analyzePlant(photo.path);
      expect(result.plantName, 'Buğday');
      expect(calls, 2);
      service.dispose();
    },
  );
}
