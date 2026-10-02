import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tarim_hayvancilik_app/screens/gallery_scale_screen.dart';
import 'package:tarim_hayvancilik_app/services/livestock_ml_service.dart';

class TestPicker extends ImagePicker {
  final List<XFile> queue;
  TestPicker(this.queue);

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => queue.removeAt(0);
}

class TestAnalysis extends LivestockMLService {
  final result = Completer<Map<String, dynamic>>();
  final List<List<String>> requests = [];

  @override
  Future<Map<String, dynamic>> analyzeImages(
    List<File> images, {
    double? chestCircumferenceCm,
    double? bodyLengthCm,
  }) {
    requests.add(images.map((image) => image.path).toList());
    return result.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  late Directory directory;
  late List<XFile> photos;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('gallery_scale_');
    final bytes = img.encodePng(img.Image(width: 16, height: 16));
    photos = [];
    for (final angle in ['front', 'side', 'rear']) {
      final file = await File(
        '${directory.path}/$angle.png',
      ).writeAsBytes(bytes);
      photos.add(XFile(file.path));
    }
  });
  tearDown(() => directory.delete(recursive: true));

  Future<void> open(WidgetTester tester, TestAnalysis service) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: GalleryScaleScreen(
          imagePicker: TestPicker([photos[2], photos[1], photos[0]]),
          mlService: service,
        ),
      ),
    );
  }

  Future<void> select(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'out-of-order selection retains angles and requires all three photos',
    (tester) async {
      final service = TestAnalysis();
      await open(tester, service);
      await select(tester, 'Arkadan görünüm');
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      await select(tester, 'Yandan görünüm');
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      await select(tester, 'Önden görünüm');
      expect(find.text('3/3 fotoğraf seçildi'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      // Even before the next frame, a second tap must not issue a paid API call.
      button.onPressed!();
      button.onPressed!();
      await tester.pump();
      expect(service.requests, [photos.map((photo) => photo.path).toList()]);
      service.result.complete({'weight': 530.0});
      await tester.pumpAndSettle();
      expect(find.text('530 kg'), findsOneWidget);
      expect(
        find.text(
          'Üç açıdan görsel tahmin; ölçek bilgisi yok. Tartı ile doğrulayın.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'clearing an incomplete set permits measurement-only estimate without AI',
    (tester) async {
      final service = TestAnalysis();
      await open(tester, service);
      await tester.enterText(find.byType(TextField).at(0), '190');
      await tester.enterText(find.byType(TextField).at(1), '160');
      await select(tester, 'Arkadan görünüm');
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      await select(tester, 'Fotoğrafları temizle');
      await select(tester, 'Ağırlık Hesapla');
      expect(find.text('535 kg'), findsOneWidget);
      expect(
        find.text('Girdiğiniz ölçülerden hesaplanan yaklaşık ağırlık.'),
        findsOneWidget,
      );
      expect(service.requests, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bad views must be retaken even when dimensions are entered', (
    tester,
  ) async {
    final service = TestAnalysis();
    await open(tester, service);
    await tester.enterText(find.byType(TextField).at(0), '190');
    await tester.enterText(find.byType(TextField).at(1), '160');
    for (final label in [
      'Arkadan görünüm',
      'Yandan görünüm',
      'Önden görünüm',
    ]) {
      await select(tester, label);
    }
    tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed!();
    service.result.complete({
      'error': 'invalid_views',
      'message': 'Yandan fotoğrafı tekrar çekin.',
    });
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Yandan fotoğrafı tekrar çekin.'),
      findsOneWidget,
    );
    expect(find.text('Analiz Tamamlandı'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
