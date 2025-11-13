import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/state/app_state.dart';

void main() {
  group('Pass switch reflection', () {
    test('Pass1 -> Pass2 -> Pass3 reflect after actions', () async {
      final app = AppState();

      // Start on Pass1
      app.startStopwatch();
      await Future.delayed(const Duration(milliseconds: 30));
      app.pauseStopwatch();

      // Move to Pass2 and resume/pause
      app.setCurrentPassIndex(1);
      app.resumeStopwatch();
      await Future.delayed(const Duration(milliseconds: 30));
      app.pauseStopwatch();

      // Move to Pass3 and resume/pause
      app.setCurrentPassIndex(2);
      app.resumeStopwatch();
      await Future.delayed(const Duration(milliseconds: 30));
      app.pauseStopwatch();

      // Validate: segments are reflected in Pass1, Pass2, Pass3
      expect(app.passes[0].weldTimeSec != null || app.passes[0].segments.isNotEmpty, true,
          reason: 'Pass1 should be reflected after start/pause');
      expect(app.passes[1].weldTimeSec != null || app.passes[1].segments.isNotEmpty, true,
          reason: 'Pass2 should be reflected after resume/pause');
      expect(app.passes[2].weldTimeSec != null || app.passes[2].segments.isNotEmpty, true,
          reason: 'Pass3 should be reflected after resume/pause');
    });
  });
}
