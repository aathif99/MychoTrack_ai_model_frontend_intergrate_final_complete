import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/prediction_result.dart';

class _PreprocessedData {
  final List<List<List<List<double>>>> tensor;
  final int originalWidth;
  final int originalHeight;

  _PreprocessedData({
    required this.tensor,
    required this.originalWidth,
    required this.originalHeight,
  });
}

class ClassifierService {
  static final ClassifierService _instance = ClassifierService._internal();
  factory ClassifierService() => _instance;
  ClassifierService._internal();

  Interpreter? _interpreter;
  bool _isInitialized = false;

  static const int inputSize = 300;

  // Disease mappings matching backend/ai_service and MySQL database
  static const List<Map<String, dynamic>> diseaseMapping = [
    {"index": 0, "model_class": "Cruris", "disease_id": 2, "disease_name": "Tinea Cruris"},
    {"index": 1, "model_class": "Other", "disease_id": 0, "disease_name": "Other"},
    {"index": 2, "model_class": "Ringworm", "disease_id": 1, "disease_name": "Tinea Corporis"},
    {"index": 3, "model_class": "Versicolor", "disease_id": 3, "disease_name": "Tinea Versicolor"},
  ];

  Future<void> initialize() async {
    if (_isInitialized && _interpreter != null) return;

    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/skin_classifier.tflite',
        options: options,
      );
      _isInitialized = true;
      print('✅ ClassifierService: TFLite model loaded successfully from assets.');
    } catch (e) {
      print('❌ ClassifierService: Failed to load TFLite model: $e');
      rethrow;
    }
  }

  /// Run on-device prediction and transparent heatmap generation.
  /// Heavy image decoding and heatmap encoding run in background isolates
  /// so the UI thread maintains a rock-solid 60 FPS spinning animation.
  Future<PredictionResult> predictImage(String imagePath, {String captureMethod = 'Gallery'}) async {
    await initialize();

    final file = File(imagePath);
    if (!file.existsSync()) {
      throw Exception('Image file not found at: $imagePath');
    }

    // 1. Offload heavy decoding & EXIF orientation baking to background isolate
    final preprocessed = await Isolate.run(() async {
      final bytes = await File(imagePath).readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Failed to decode image.');
      }
      // Bake EXIF orientation so Samsung, Oppo, Redmi camera photos are upright
      final oriented = img.bakeOrientation(decoded);
      final origW = oriented.width;
      final origH = oriented.height;

      // Resize to 300x300 float32 RGB for model input
      final resized = img.copyResize(oriented, width: inputSize, height: inputSize);

      final tensor = List.generate(1, (_) {
        return List.generate(inputSize, (y) {
          return List.generate(inputSize, (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          });
        });
      });

      return _PreprocessedData(
        tensor: tensor,
        originalWidth: origW,
        originalHeight: origH,
      );
    });

    // 2. Identify output indices and channels dynamically
    int probIndex = 0;
    int heatmapIndex = 1;
    int heatmapChannels = 4;

    for (int i = 0; i < _interpreter!.getOutputTensors().length; i++) {
      final shape = _interpreter!.getOutputTensor(i).shape;
      if (shape.length == 2 && shape[1] == 4) {
        probIndex = i;
      } else if (shape.length == 4) {
        heatmapIndex = i;
        heatmapChannels = shape[3];
      }
    }

    var probBuffer = List.generate(1, (_) => List<double>.filled(4, 0.0));
    var heatmapBuffer = List.generate(
      1,
      (_) => List.generate(
        10,
        (_) => List.generate(10, (_) => List<double>.filled(heatmapChannels, 0.0)),
      ),
    );

    final outputs = {
      probIndex: probBuffer,
      heatmapIndex: heatmapBuffer,
    };

    // 3. Fast TFLite inference (~150ms)
    final stopwatch = Stopwatch()..start();
    _interpreter!.runForMultipleInputs([preprocessed.tensor], outputs);
    stopwatch.stop();
    print('⚡ ClassifierService: TFLite inference took ${stopwatch.elapsedMilliseconds} ms');

    // 4. Parse probabilities
    final probabilities = probBuffer[0];
    int predictedIndex = 0;
    double maxConfidence = -1.0;
    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxConfidence) {
        maxConfidence = probabilities[i];
        predictedIndex = i;
      }
    }

    final diseaseInfo = diseaseMapping[predictedIndex];
    final confidenceScore = double.parse((maxConfidence * 100).toStringAsFixed(2));

    // 5. Select the exact class-weighted channel for the predicted disease
    final camChannel = heatmapChannels >= 4 ? predictedIndex : 0;
    print('🎯 Using CAM channel $camChannel for predicted disease: ${diseaseInfo["disease_name"]}');

    final raw2dHeatmap = List.generate(
      10,
      (r) => List.generate(10, (c) => heatmapBuffer[0][r][c][camChannel]),
    );

    // 6. Generate transparent PNG overlay in a background isolate
    String heatmapBase64 = '';
    try {
      final origW = preprocessed.originalWidth;
      final origH = preprocessed.originalHeight;

      heatmapBase64 = await Isolate.run(() {
        return _generateTransparentHeatmapOverlay(raw2dHeatmap, origW, origH);
      });
    } catch (e) {
      print('⚠️ ClassifierService: Failed to generate local heatmap: $e');
    }

    final now = DateTime.now();
    final detectionDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final detectionTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    return PredictionResult(
      detectionId: 0,
      diseaseId: diseaseInfo["disease_id"] as int,
      diseaseName: diseaseInfo["disease_name"] as String,
      confidenceScore: confidenceScore,
      imageUrl: imagePath,
      heatmapUrl: '',
      heatmapBase64: heatmapBase64,
      detectionDate: detectionDate,
      detectionTime: detectionTime,
      captureMethod: captureMethod,
    );
  }

  /// Generates a TRANSPARENT PNG heatmap overlay with identical aspect ratio.
  /// Non-lesion skin is 100% transparent (alpha=0), allowing the original photo
  /// underneath to show through with zero shrinking, zero shifting, and zero distortion.
  static String _generateTransparentHeatmapOverlay(
    List<List<double>> heatmap10x10,
    int originalWidth,
    int originalHeight,
  ) {
    // 1. Min-Max normalization
    double minVal = double.infinity;
    double maxVal = -double.infinity;
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        final v = heatmap10x10[r][c];
        if (v < minVal) minVal = v;
        if (v > maxVal) maxVal = v;
      }
    }

    final range = maxVal - minVal;
    final norm10x10 = List.generate(10, (r) {
      return List.generate(10, (c) {
        if (range > 1e-6) {
          return (heatmap10x10[r][c] - minVal) / range;
        }
        return 0.0;
      });
    });

    // 2. Percentile thresholding to accurately focus on the lesion:
    // Suppress the bottom 35% background skin activations
    final allVals = <double>[];
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        allVals.add(norm10x10[r][c]);
      }
    }
    allVals.sort();
    final p35 = allVals[(allVals.length * 0.35).floor()];

    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        if (norm10x10[r][c] <= p35) {
          norm10x10[r][c] = 0.0;
        } else {
          norm10x10[r][c] = (norm10x10[r][c] - p35) / (1.0 - p35 + 1e-7);
        }
      }
    }

    // 3. Proportional dimensions matching the EXACT aspect ratio of original image
    const int targetW = 320;
    final int targetH = max((targetW * originalHeight / originalWidth).round(), 1);

    final overlay = img.Image(
      width: targetW,
      height: targetH,
      numChannels: 4, // RGBA for transparency
    );

    // 4. Smooth Bilinear interpolation with transparent JET coloring
    for (int y = 0; y < targetH; y++) {
      final gy = ((y + 0.5) / targetH) * 9.0;
      final y0 = gy.floor().clamp(0, 9);
      final y1 = (y0 + 1).clamp(0, 9);
      final dy = gy - y0;

      for (int x = 0; x < targetW; x++) {
        final gx = ((x + 0.5) / targetW) * 9.0;
        final x0 = gx.floor().clamp(0, 9);
        final x1 = (x0 + 1).clamp(0, 9);
        final dx = gx - x0;

        final top = norm10x10[y0][x0] * (1.0 - dx) + norm10x10[y0][x1] * dx;
        final bottom = norm10x10[y1][x0] * (1.0 - dx) + norm10x10[y1][x1] * dx;
        double val = (top * (1.0 - dy) + bottom * dy).clamp(0.0, 1.0);

        // Power curve sharpening for contrast around active lesion margins
        val = pow(val, 1.8).toDouble();

        if (val > 0.08) {
          // Lesion region: JET colored overlay with graduated alpha (up to 70% opacity)
          final jet = _intensityToJetColor(val);
          final alpha = ((0.20 + val * 0.50) * 255).round().clamp(0, 255);
          overlay.setPixelRgba(x, y, jet[0], jet[1], jet[2], alpha);
        } else {
          // Healthy skin: 100% transparent (alpha = 0)
          overlay.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    // Encode as transparent PNG
    final encodedPng = img.encodePng(overlay);
    return "data:image/png;base64,${base64Encode(encodedPng)}";
  }

  /// Converts normalized value [0..1] to JET RGB color
  static List<int> _intensityToJetColor(double v) {
    double r = (1.5 - (4.0 * v - 3.0).abs()).clamp(0.0, 1.0);
    double g = (1.5 - (4.0 * v - 2.0).abs()).clamp(0.0, 1.0);
    double b = (1.5 - (4.0 * v - 1.0).abs()).clamp(0.0, 1.0);

    return [(r * 255).round(), (g * 255).round(), (b * 255).round()];
  }
}
