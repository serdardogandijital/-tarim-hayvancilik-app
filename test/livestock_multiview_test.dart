import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:tarim_hayvancilik_app/services/livestock_ml_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  late Directory directory;
  late List<File> photos;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ciftci_views_');
    photos = [];
    for (var i = 0; i < 3; i++) {
      final image = img.Image(width: 16, height: 16);
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
  });
  tearDown(() => directory.delete(recursive: true));

  http.Response answer(Map<String, dynamic> result) => http.Response(
    jsonEncode({
      'choices': [
        {
          'message': {'content': jsonEncode(result)},
        },
      ],
    }),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  test(
    'all three labeled angles and measured dimensions go in one request',
    () async {
      var calls = 0;
      final service = LivestockMLService(
        apiKeyReader: () async => 'test-key',
        client: MockClient((request) async {
          calls++;
          final body = jsonDecode(request.body);
          final content = body['messages'][0]['content'] as List;
          expect(
            content.where((part) => part['type'] == 'image_url'),
            hasLength(3),
          );
          expect(content[0]['text'], contains('190.0 cm'));
          expect(content[0]['text'], contains('160.0 cm'));
          for (var i = 0; i < 3; i++) {
            expect(
              content[1 + i * 2]['text'],
              contains(['ÖNDEN', 'YANDAN', 'ARKADAN'][i]),
            );
            final image = content[2 + i * 2]['image_url'];
            expect(image['detail'], 'high');
            final decoded = img.decodeJpg(
              base64Decode((image['url'] as String).split(',').last),
            )!;
            final pixel = decoded.getPixel(0, 0);
            expect([pixel.r, pixel.g, pixel.b][i], greaterThan(240));
          }
          return answer({'photoCheck': 'usable', 'weight': 530});
        }),
      );
      final result = await service.analyzeImages(
        photos,
        chestCircumferenceCm: 190,
        bodyLengthCm: 160,
      );
      expect(result['weight'], 530);
      expect(calls, 1);
      service.dispose();
    },
  );

  test('incomplete set is rejected without calling the API', () async {
    var called = false;
    final service = LivestockMLService(
      apiKeyReader: () async => 'test-key',
      client: MockClient((_) async {
        called = true;
        return answer({'photoCheck': 'usable', 'weight': 530});
      }),
    );
    for (final count in [0, 1, 2]) {
      expect(
        (await service.analyzeImages(photos.take(count).toList()))['error'],
        'invalid_photos',
      );
    }
    expect(called, isFalse);
    service.dispose();
  });

  test(
    'same photo copied under another filename cannot fill a second angle',
    () async {
      final duplicate = await photos[0].copy('${directory.path}/copy.png');
      var calls = 0;
      final service = LivestockMLService(
        apiKeyReader: () async => 'test-key',
        client: MockClient((_) async {
          calls++;
          return answer({'weight': 530});
        }),
      );
      final result = await service.analyzeImages([
        photos[0],
        duplicate,
        photos[2],
      ]);
      expect(result['error'], 'invalid_photos');
      expect(result.containsKey('weight'), isFalse);
      expect(calls, 0);
      service.dispose();
    },
  );

  for (final error in [
    'insufficient_quality',
    'inconsistent_subject',
    'invalid_views',
    'no_livestock',
    'uncertain',
  ]) {
    test(
      '$error does not become a weight even if response includes a number',
      () async {
        final service = LivestockMLService(
          apiKeyReader: () async => 'test-key',
          client: MockClient(
            (_) async => answer({
              'error': error,
              'message': 'Yandan fotoğrafı tekrar çekin.',
              'weight': 530,
            }),
          ),
        );
        final result = await service.analyzeImages(photos);
        expect(result['error'], error);
        expect(result.containsKey('weight'), isFalse);
        service.dispose();
      },
    );
  }

  test(
    'missing photo validation is rejected instead of treated as success',
    () async {
      final service = LivestockMLService(
        apiKeyReader: () async => 'test-key',
        client: MockClient((_) async => answer({'weight': 530})),
      );
      final result = await service.analyzeImages(photos);
      expect(result.containsKey('error'), isTrue);
      expect(result.containsKey('weight'), isFalse);
      service.dispose();
    },
  );
}
