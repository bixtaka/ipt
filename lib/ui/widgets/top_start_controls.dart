import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class TopStartControls extends StatelessWidget {
  const TopStartControls({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.currentSession;
    final bool isMeasuring = s.isRunning || s.isPaused;
    final bool isPaused = s.isPaused;
    final bool canStart = s.startTime == null;

    // Button presentation
    late final String centerLabel;
    late final IconData centerIcon;
    late final Color centerColor;
    VoidCallback? centerAction;

    if (canStart) {
      centerLabel = '測定開始';
      centerIcon = Icons.play_arrow;
      centerColor = Colors.green;
      centerAction = app.startStopwatch;
    } else {
      if (!isPaused) {
        centerLabel = '停止';
        centerIcon = Icons.pause;
        centerColor = Colors.orange;
        centerAction = () {
          // 現在パスで停止（反映）→ 次パスへ移動
          final currentIdx = app.currentPassIndex;
          app.pauseStopwatch();
          final nextIdx = currentIdx + 1;
          if (nextIdx >= 0 && nextIdx < app.passes.length) {
            app.setCurrentPassIndex(nextIdx);
          }
        };
      } else {
        centerLabel = '再開';
        centerIcon = Icons.play_arrow;
        centerColor = Colors.green;
        centerAction = () {
          // 再開後、次のパスへ自動移動して計測を引き継ぐ
          final activeIdx = app.measuringPassIndex ?? app.currentPassIndex;
          app.resumeStopwatch();
          final nextIdx = activeIdx + 1;
          if (nextIdx >= 0 && nextIdx < app.passes.length) {
            app.setCurrentPassIndex(nextIdx);
          }
        };
      }
    }

    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Start/Stop/Resume
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: centerColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: centerAction,
                  icon: Icon(centerIcon),
                  label: Text(
                    centerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Reset on the right
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: app.resetStopwatch,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Reset',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
