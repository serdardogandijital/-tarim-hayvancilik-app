import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class AnalysisImage {
  static Future<String> dataUrl(File file) async {
    if (await file.length() > 15 * 1024 * 1024) {
      throw const FormatException(
        'Fotoğraf 15 MB sınırını aşıyor. Daha küçük bir görsel seçin.',
      );
    }
    final bytes = await file.readAsBytes();
    final jpeg = await compute(_prepare, bytes);
    return 'data:image/jpeg;base64,${base64Encode(jpeg)}';
  }

  static Uint8List _prepare(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException(
        'Görsel okunamadı. JPEG veya PNG fotoğraf seçin.',
      );
    }
    final oriented = img.bakeOrientation(decoded);
    final resized = oriented.width > 1280 || oriented.height > 1280
        ? img.copyResize(
            oriented,
            width: oriented.width >= oriented.height ? 1280 : null,
            height: oriented.height > oriented.width ? 1280 : null,
          )
        : oriented;
    for (final quality in [78, 65, 50]) {
      final jpeg = img.encodeJpg(resized, quality: quality);
      if (jpeg.length <= 1_100_000) return Uint8List.fromList(jpeg);
    }
    final smaller = img.copyResize(
      resized,
      width: resized.width >= resized.height ? 960 : null,
      height: resized.height > resized.width ? 960 : null,
    );
    final jpeg = img.encodeJpg(smaller, quality: 50);
    if (jpeg.length > 1_100_000) {
      throw const FormatException(
        'Fotoğraf hâlâ çok büyük. Başka bir fotoğraf seçin.',
      );
    }
    return Uint8List.fromList(jpeg);
  }
}
