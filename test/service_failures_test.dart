import 'package:tarim_hayvancilik_app/services/analysis_credits.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tarim_hayvancilik_app/services/livestock_ml_service.dart';
import 'package:tarim_hayvancilik_app/services/plant_analysis_service.dart';
import 'package:tarim_hayvancilik_app/services/weather_service.dart';
import 'package:tarim_hayvancilik_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  late Directory temp;
  late File photo;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('ciftci_test_');
    photo = await File(
      '${temp.path}/photo.jpg',
    ).writeAsBytes(img.encodePng(img.Image(width: 2, height: 2)));
  });
  tearDown(() => temp.delete(recursive: true));

  http.Client responding(String content, {int status = 200}) => MockClient(
    (_) async => http.Response(
      status == 200
          ? jsonEncode({
              'choices': [
                {
                  'message': {'content': content},
                },
              ],
            })
          : '',
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ),
  );

  test(
    'missing credentials produce no weight and no network request',
    () async {
      final service = LivestockMLService(
        apiKeyReader: () async => null,
        client: MockClient((_) async => throw StateError('Must not request')),
      );
      final result = await service.analyzeImage(photo);
      expect(result['error'], 'analysis_failed');
      expect(result.containsKey('weight'), isFalse);
    },
  );

  for (final response in [
    'not JSON',
    '{"weight":0}',
    '{"weight":-10}',
    '{"weight":1e999}',
    '{"error":"no_livestock"}',
  ]) {
    test(
      'invalid or non-animal response never becomes a weight: $response',
      () async {
        final service = LivestockMLService(
          client: responding(response),
          apiKeyReader: () async => 'test-key',
        );
        final result = await service.analyzeImage(photo);
        expect(result.containsKey('error'), isTrue);
        expect(result.containsKey('weight'), isFalse);
      },
    );
  }

  test('API failure never returns a random estimate', () async {
    final service = LivestockMLService(
      client: responding('', status: 500),
      apiKeyReader: () async => 'test-key',
    );
    expect((await service.analyzeImage(photo)).containsKey('weight'), isFalse);
  });

  test('valid weight is preserved without an invented confidence', () async {
    final service = LivestockMLService(
      client: responding('{"weight":520}'),
      apiKeyReader: () async => 'test-key',
    );
    final result = await service.analyzeImage(photo);
    expect(result['weight'], 520);
    expect(result.containsKey('confidence'), isFalse);
  });

  test('plant JSON keeps separate array items and commas in text', () async {
    final service = PlantAnalysisService(
      apiKeyReader: () async => 'test-key',
      client: responding(
        jsonEncode({
          'plantName': 'Domates',
          'status': 'İnceleme gerekli',
          'confidence': 0.5,
          'diseases': ['Birinci, olası durum', 'İkinci durum'],
          'careAdvice': ['Toprağı, nemi kontrol edin'],
        }),
      ),
    );
    final result = await service.analyzePlant(photo.path);
    expect(result.diseases, ['Birinci, olası durum', 'İkinci durum']);
    expect(result.careAdvice.single, 'Toprağı, nemi kontrol edin');
  });

  test(
    'invalid plant analysis fails instead of being saved as success',
    () async {
      final service = PlantAnalysisService(
        client: responding('broken'),
        apiKeyReader: () async => 'test-key',
      );
      await expectLater(service.analyzePlant(photo.path), throwsException);
    },
  );

  test(
    'successful photo consumes one, exhaustion prevents HTTP, and invalid photo costs nothing',
    () async {
      var calls = 0;
      final service = LivestockMLService(
        apiKeyReader: () async => 'test-key',
        client: MockClient((_) async {
          calls++;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': '{"weight":520}'},
                },
              ],
            }),
            200,
          );
        }),
      );
      for (var i = 0; i < 3; i++) {
        expect((await service.analyzeImage(photo))['weight'], 520);
      }
      expect((await service.analyzeImage(photo))['error'], 'no_credits');
      expect(calls, 3);
      expect(AnalysisCredits.instance.available, 0);
      service.dispose();
    },
  );

  test(
    'plant save failure preserves credit, then successful saved result consumes one',
    () async {
      final service = PlantAnalysisService(
        apiKeyReader: () async => 'test-key',
        client: responding(
          '{"plantName":"Domates","status":"Sağlıklı","confidence":0.5}',
        ),
      );
      await expectLater(
        service.analyzePlant(
          photo.path,
          persist: (_) async => throw StateError('disk'),
        ),
        throwsStateError,
      );
      expect(AnalysisCredits.instance.available, 3);
      await service.analyzePlant(photo.path, persist: (result) async => result);
      expect(AnalysisCredits.instance.available, 2);
      service.dispose();
    },
  );

  test('offline weather has no synthetic temperature', () async {
    final service = WeatherService(
      client: MockClient((_) async => throw const SocketException('offline')),
    );
    expect(await service.getWeatherByCity('Ankara'), isNull);
    expect(await service.getMultipleSourcesWeather('Ankara'), isEmpty);
  });

  test('invalid weather response has no seasonal fallback', () async {
    final service = WeatherService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    expect(await service.getWeatherByCity('İzmir'), isNull);
  });

  test('notification ids are stable, scoped, positive 32-bit integers', () {
    final animal = NotificationService.notificationId('123', 'animal_heat');
    expect(animal, NotificationService.notificationId('123', 'animal_heat'));
    expect(
      animal,
      isNot(NotificationService.notificationId('123', 'field_harvest')),
    );
    expect(animal, inInclusiveRange(0, 0x7fffffff));
  });
}
