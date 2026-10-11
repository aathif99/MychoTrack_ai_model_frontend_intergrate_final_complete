import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myco_track/screens/analysis_result_screen.dart';
import 'package:myco_track/models/prediction_result.dart';

void main() {
  testWidgets('AnalysisResultScreen displays predicted date and time', (WidgetTester tester) async {
    final mockResult = PredictionResult(
      detectionId: 1,
      diseaseId: 3,
      diseaseName: 'Tinea Versicolor',
      confidenceScore: 94.50,
      imageUrl: '',
      heatmapUrl: '',
      heatmapBase64: '',
      detectionDate: '2026-08-15',
      detectionTime: '06:30:00',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisResultScreen(predictionResult: mockResult),
      ),
    );

    expect(find.text('Analysis Result'), findsOneWidget);
    expect(find.text('Tinea Versicolor'), findsOneWidget);
    expect(find.textContaining('Date:'), findsOneWidget);
    expect(find.textContaining('Time:'), findsOneWidget);
    expect(find.text('94.50%'), findsOneWidget);
  });
}
