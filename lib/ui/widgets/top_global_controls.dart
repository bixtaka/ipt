import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

/// グローバル開始/終了ボタン（測定中は停止のみ）
class TopGlobalControls extends StatelessWidget {
  const TopGlobalControls({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final bool isMeasuring = app.isMeasuring || app.isMeasuringPaused;

    final String centerLabel = isMeasuring ? '測定終了' : '測定開始';
    final IconData centerIcon = isMeasuring ? Icons.stop : Icons.play_arrow;
    final Color centerColor = isMeasuring ? Colors.blue : Colors.green;
    final VoidCallback? centerAction =
        isMeasuring ? app.stopActiveStopwatch : app.startStopwatch;

    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: centerColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 56),
                    textStyle:
                        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 56),
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
          ],
        ),
      ),
    );
  }
}
