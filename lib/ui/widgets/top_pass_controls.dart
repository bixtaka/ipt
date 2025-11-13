import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class TopPassControls extends StatelessWidget {
  const TopPassControls({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.currentSession;
    final idx = app.currentPassIndex;
    final last = app.passes.isEmpty ? 0 : app.passes.length - 1;

    // 左ボタン：停止／再開トグル
    final bool isRunning = s.isRunning;
    final bool isPaused = s.isPaused;

    String leftLabel;
    IconData leftIcon;
    VoidCallback? leftOnPressed;

    if (isRunning) {
      leftLabel = '停止';
      leftIcon = Icons.pause_circle_filled;
      leftOnPressed = app.pauseStopwatch;
    } else if (isPaused) {
      leftLabel = '再開';
      leftIcon = Icons.play_arrow;
      leftOnPressed = app.resumeStopwatch;
    } else {
      leftLabel = '停止';
      leftIcon = Icons.pause_circle_filled;
      leftOnPressed = null; // 未開始/停止済は無効
    }

    // 中央/右ボタン：パス移動（範囲外は無効）
    final canPrev = idx > 0;
    // 次パスは常に押下可能。末尾なら自動で新規パスを追加して移動
    final canNext = true;

    void goPrev() {
      if (canPrev) app.setCurrentPassIndex(idx - 1);
    }

    void goNext() {
      if (idx >= last) {
        // Ensure a new pass exists at idx+1
        app.ensurePassCount(idx + 2);
      }
      app.setCurrentPassIndex(idx + 1);
    }

    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // 左：停止／再開
            Expanded(
              child: ElevatedButton.icon(
                onPressed: leftOnPressed,
                icon: Icon(leftIcon),
                label: Text(leftLabel),
              ),
            ),
            const SizedBox(width: 8),

            // 中央：前パス
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canPrev ? goPrev : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('前パス'),
              ),
            ),
            const SizedBox(width: 8),

            // 右：次パス
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canNext ? goNext : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('次パス'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
