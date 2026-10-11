import 'package:flutter_test/flutter_test.dart';
import 'package:myco_track/screens/analysis_result_screen.dart';

void main() {
  group('AnalysisResultScreen disease mapping', () {
    test('maps tinea versicolor to low risk', () {
      expect(AnalysisResultScreen.getRiskLevel('Tinea Versicolor'), 'Low Risk');
    });

    test('maps tinea cruris and ringworm to moderate risk', () {
      expect(
        AnalysisResultScreen.getRiskLevel('Tinea Cruris'),
        'Moderate Risk',
      );
      expect(AnalysisResultScreen.getRiskLevel('Ringworm'), 'Moderate Risk');
    });

    test('formats known disease names for display', () {
      expect(
        AnalysisResultScreen.formatDiseaseName('versicolar'),
        'Tinea Versicolor',
      );
      expect(AnalysisResultScreen.formatDiseaseName('cruris'), 'Tinea Cruris');
    });
  });
}
