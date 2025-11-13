import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/state/app_state.dart';

void main() {
  group('AppState pause/resume across pass switch', () {
    test('fallback pauses/resumes active pass when viewing another pass', () async {
      final app = AppState();
      addTearDown(app.dispose);

      // Start on pass 0
      expect(app.currentPassIndex, 0);
      app.startStopwatch();
      expect(app.isMeasuring, isTrue);
      expect(app.measuringPassIndex, 0);

      // Simulate UI showing pass 2 (index 1) without handing over measuring pass
      app.currentPassIndex = 1; // intentionally bypass setCurrentPassIndex

      // Pause via public API should affect the active (measuring) pass
      app.pauseStopwatch();
      expect(app.isMeasuringPaused, isTrue, reason: 'Active measuring pass should be paused');

      // Resume via public API should resume the active pass
      app.resumeStopwatch();
      expect(app.isMeasuringPaused, isFalse);
      expect(app.isMeasuring, isTrue);
    });

    test('normal pause/resume works after switching to next pass properly', () async {
      final app = AppState();
      addTearDown(app.dispose);

      // Start on pass 0 and switch to pass 1 using official API
      app.startStopwatch();
      expect(app.isMeasuring, isTrue);
      app.setCurrentPassIndex(1);

      // Measuring should be handed off to pass 1
      expect(app.measuringPassIndex, 1);
      expect(app.currentPassIndex, 1);

      // Pause/resume on current pass
      app.pauseStopwatch();
      // Debug
      // ignore: avoid_print
      print('[debug] after pause: isPaused=${app.isMeasuringPaused} measuringIdx=${app.measuringPassIndex}');
      expect(app.isMeasuringPaused, isTrue);
      app.resumeStopwatch();
      // ignore: avoid_print
      print('[debug] after resume: isPaused=${app.isMeasuringPaused} measuringIdx=${app.measuringPassIndex}');
      expect(app.isMeasuringPaused, isFalse);
      expect(app.isMeasuring, isTrue);
    });
  });
}
