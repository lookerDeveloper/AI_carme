import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  ImageUtils._();

  static Future<Uint8List> compressImage(
    Uint8List imageData, {
    int maxWidth = 384,
    int maxHeight = 384,
    int quality = 60,
  }) async {
    return await compute(_compressImageWorker, _ImageTask(imageData, maxWidth, maxHeight, quality));
  }

  static Uint8List _compressImageWorker(_ImageTask task) {
    final image = img.decodeImage(task.imageData);
    if (image == null) return task.imageData;

    int width = image.width;
    int height = image.height;

    if (width > task.maxWidth || height > task.maxHeight) {
      final ratio = (width / task.maxWidth).compareTo(height / task.maxHeight) > 0
          ? width / task.maxWidth
          : height / task.maxHeight;
      width = (width / ratio).round();
      height = (height / ratio).round();
    }

    final resized = img.copyResize(image, width: width, height: height);
    return Uint8List.fromList(img.encodeJpg(resized, quality: task.quality));
  }

  static String imageToBase64(Uint8List imageData) {
    return base64Encode(imageData);
  }

  static Uint8List base64ToImage(String base64String) {
    return base64Decode(base64String);
  }
}

class _ImageTask {
  final Uint8List imageData;
  final int maxWidth;
  final int maxHeight;
  final int quality;

  _ImageTask(this.imageData, this.maxWidth, this.maxHeight, this.quality);
}
