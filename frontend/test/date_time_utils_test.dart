import 'package:flutter_test/flutter_test.dart';
import 'package:myco_track/utils/date_time_utils.dart';
import 'package:myco_track/models/prediction_result.dart';
import 'package:myco_track/models/history_item.dart';

void main() {
  group('DateTimeUtils Tests', () {
    test('parses UTC date and time correctly into device local time', () {
      final localDateTime = DateTimeUtils.parseToLocal('2026-08-15', '06:30:00');
      expect(localDateTime, isNotNull);
      expect(localDateTime!.year, 2026);
      expect(localDateTime.month, 8);
      expect(localDateTime.day, 15);
    });

    test('formats DateTime into DD.MM.YYYY and HH:MM', () {
      final dt = DateTime(2026, 8, 15, 14, 45);
      expect(DateTimeUtils.formatDate(dt), '15.08.2026');
      expect(DateTimeUtils.formatTime(dt), '14:45');
      expect(DateTimeUtils.formatTime(dt, use12Hour: true), '2:45 PM');
    });

    test('handles full ISO datetime string', () {
      final localDateTime = DateTimeUtils.parseToLocal('2026-08-15T06:30:00.000Z', '');
      expect(localDateTime, isNotNull);
    });
  });

  group('PredictionResult & HistoryItem conversion', () {
    test('PredictionResult.fromHistoryItem sets dates and fields accurately', () {
      final historyItem = HistoryItem(
        detectionId: 10,
        diseaseClass: 'Tinea Versicolor',
        confidenceScore: 95.5,
        detectionDate: '2026-08-15',
        detectionTime: '06:30:00',
        imagePath: '/uploads/sample.jpg',
        captureMethod: 'Camera',
        heatmapPath: '/heatmaps/sample_hm.jpg',
        heatmapStatus: 'Generated',
      );

      final result = PredictionResult.fromHistoryItem(historyItem);
      expect(result.detectionId, 10);
      expect(result.diseaseName, 'Tinea Versicolor');
      expect(result.confidenceScore, 95.5);
      expect(result.detectionDate, '2026-08-15');
      expect(result.detectionTime, '06:30:00');
      expect(result.heatmapUrl, '/heatmaps/sample_hm.jpg');
    });
  });
}
