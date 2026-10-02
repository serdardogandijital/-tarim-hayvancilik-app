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
    final resized = oriented.width > 1600 || oriented.height > 1600
        ? img.copyResize(
            oriented,
            width: oriented.width >= oriented.height ? 1600 : null,
            height: oriented.height > oriented.width ? 1600 : null,
          )
        : oriented;
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }
}
