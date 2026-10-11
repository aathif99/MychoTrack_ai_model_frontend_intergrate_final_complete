import 'history_item.dart';

class PredictionResult {
  final int detectionId;
  final int diseaseId;
  final String diseaseName;
  final double confidenceScore;
  final String imageUrl;
  final String heatmapUrl;
  final String heatmapBase64;
  final String detectionDate;
  final String detectionTime;
  final String? captureMethod;

  PredictionResult({
    required this.detectionId,
    required this.diseaseId,
    required this.diseaseName,
    required this.confidenceScore,
    required this.imageUrl,
    required this.heatmapUrl,
    required this.heatmapBase64,
    this.detectionDate = '',
    this.detectionTime = '',
    this.captureMethod,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    // Handle case where confidence_score might be parsed as int or string
    double confidence = 0.0;
    if (json['confidence_score'] is num) {
      confidence = (json['confidence_score'] as num).toDouble();
    } else if (json['confidence_score'] is String) {
      confidence = double.tryParse(json['confidence_score']) ?? 0.0;
    }

    return PredictionResult(
      detectionId: json['detection_id'] ?? 0,
      diseaseId: json['disease_id'] ?? 0,
      diseaseName: json['disease_name'] ?? '',
      confidenceScore: confidence,
      imageUrl: json['image_url'] ?? '',
      heatmapUrl: json['heatmap_url'] ?? '',
      heatmapBase64: json['heatmap_base64'] ?? '',
      detectionDate: json['detection_date']?.toString() ?? '',
      detectionTime: json['detection_time']?.toString() ?? '',
      captureMethod: json['capture_method']?.toString(),
    );
  }

  factory PredictionResult.fromHistoryItem(HistoryItem item) {
    return PredictionResult(
      detectionId: item.detectionId,
      diseaseId: 0,
      diseaseName: item.diseaseClass,
      confidenceScore: item.confidenceScore,
      imageUrl: item.imagePath,
      heatmapUrl: item.heatmapPath,
      heatmapBase64: '',
      detectionDate: item.detectionDate,
      detectionTime: item.detectionTime,
      captureMethod: item.captureMethod,
    );
  }
}

