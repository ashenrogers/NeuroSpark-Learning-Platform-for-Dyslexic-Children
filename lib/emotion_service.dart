import 'dart:typed_data';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;

class EmotionService {
  tfl.Interpreter? _interpreter;

  final List<String> labels = [
    'angry',
    'disgust',
    'fear',
    'happy',
    'neutral',
    'sad',
    'surprise',
  ];

  Future<void> loadModel() async {
    // Only try to load TFLite on Android/iOS
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    _interpreter ??= await tfl.Interpreter.fromAsset(
      'assets/models/emotion_model_cafe.tflite',
    );
  }

  Future<String> predictFromBytes(Uint8List imageBytes) async {
    // On Windows / Web / desktop: just return neutral (dev mode)
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return 'neutral';
    }

    await loadModel();

    img.Image? original = img.decodeImage(imageBytes);
    if (original == null) return 'neutral';

    img.Image resized = img.copyResize(original, width: 96, height: 96);

    // [1, 96, 96, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        96,
        (y) => List.generate(
          96,
          (x) {
            final pixel = resized.getPixel(x, y);
            final r = img.getRed(pixel) / 255.0;
            final g = img.getGreen(pixel) / 255.0;
            final b = img.getBlue(pixel) / 255.0;
            return [r, g, b];
          },
        ),
      ),
    );

    final output =
        List.generate(1, (_) => List.filled(labels.length, 0.0));

    _interpreter!.run(input, output);

    int maxIndex = 0;
    double maxValue = output[0][0];
    for (int i = 1; i < labels.length; i++) {
      if (output[0][i] > maxValue) {
        maxValue = output[0][i];
        maxIndex = i;
      }
    }

    return labels[maxIndex];
  }
}
