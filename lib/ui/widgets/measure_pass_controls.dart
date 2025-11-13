import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class MeasurePassControls extends StatelessWidget {
  const MeasurePassControls({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final idx = app.currentPassIndex;
    final last = app.passes.isEmpty ? 0 : app.passes.length - 1;

    // Use current pass session state instead of global
    final s = app.currentSession;
    final bool isRunning = s.isRunning;
    final bool isPaused = s.isPaused;
    final bool localMeasuring = isRunning || isPaused;

    // Left button: always control the active measuring session
    String leftLabel;
    IconData leftIcon;
    VoidCallback? leftOnPressed;
    Color? leftBg;
    Color? leftFg;

    if (!localMeasuring) {
      leftLabel = '停止';
      leftIcon = Icons.pause_circle_filled;
      leftOnPressed = null;
      leftBg = null;
      leftFg = null;
    } else if (isPaused) {
      // When paused, resume (AppState handles moving to next pass and closing pause).
      leftLabel = '再開';
      leftIcon = Icons.play_arrow;
      leftOnPressed = () {
        app.resumeStopwatch();
      };
      leftBg = Colors.orange;
      leftFg = Colors.white;
    } else {
      // When running, Pause and move to next pass immediately.
      leftLabel = '停止';
      leftIcon = Icons.pause_circle_filled;
      leftOnPressed = () {
        app.pauseActiveStopwatch();
        // Stay on the same pass while paused; next pass is selected on Resume.
      };
      leftBg = Colors.yellow;
      leftFg = Colors.black;
    }

    // Center: previous pass
    final bool canPrev = idx > 0;
    void goPrev() {
      if (canPrev) app.setCurrentPassIndex(idx - 1);
    }

    // Right: next pass
    // 次パスは常に押下可能。末尾で押された場合は自動的に追加
    final bool canNext = true;
    void goNext() {
      if (idx >= last) {
        app.ensurePassCount(idx + 2);
      }
      app.setCurrentPassIndex(idx + 1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Stop/Resume | Prev | Next
          Expanded(
            child: ElevatedButton.icon(
              onPressed: leftOnPressed,
              icon: Icon(leftIcon),
              label: Text(leftLabel),
              style: (leftBg == null && leftFg == null)
                  ? null
                  : ElevatedButton.styleFrom(
                      backgroundColor: leftBg,
                      foregroundColor: leftFg,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canPrev ? goPrev : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('前パス'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: ElevatedButton.icon(
                onPressed: canNext ? goNext : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('次パス'),
              ),
          ),
        ],
      ),
    );
  }
}
