class HistoryItem {
  final int detectionId;
  final String diseaseClass;
  final double confidenceScore;
  final String detectionDate;
  final String detectionTime;
  final String imagePath;
  final String captureMethod;
  final String heatmapPath;
  final String heatmapStatus;

  HistoryItem({
    required this.detectionId,
    required this.diseaseClass,
    required this.confidenceScore,
    required this.detectionDate,
    required this.detectionTime,
    required this.imagePath,
    required this.captureMethod,
    required this.heatmapPath,
    required this.heatmapStatus,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    double confidence = 0.0;
    if (json['confidence_score'] is num) {
      confidence = (json['confidence_score'] as num).toDouble();
    } else if (json['confidence_score'] is String) {
      confidence = double.tryParse(json['confidence_score']) ?? 0.0;
    }

    return HistoryItem(
      detectionId: json['detection_id'] ?? 0,
      diseaseClass: json['disease_class'] ?? '',
      confidenceScore: confidence,
      detectionDate: json['detection_date'] ?? '',
      detectionTime: json['detection_time'] ?? '',
      imagePath: json['image_path'] ?? '',
      captureMethod: json['capture_method'] ?? '',
      heatmapPath: json['heatmap_path'] ?? '',
      heatmapStatus: json['heat_map_status'] ?? '',
    );
  }
}
