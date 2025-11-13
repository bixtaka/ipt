import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSave;
  final VoidCallback? onExcelExport;
  final VoidCallback? onClearData;
  final VoidCallback? onStartStopwatch;
  final VoidCallback? onStopStopwatch;
  final VoidCallback? onResetStopwatch;
  final VoidCallback? onRecordTime;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    this.onSave,
    this.onExcelExport,
    this.onClearData,
    this.onStartStopwatch,
    this.onStopStopwatch,
    this.onResetStopwatch,
    this.onRecordTime,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Ctrl+S: 保存
          if (event.logicalKey == LogicalKeyboardKey.keyS &&
              HardwareKeyboard.instance.isControlPressed) {
            onSave?.call();
            return KeyEventResult.handled;
          }

          // Ctrl+E: Excel出力
          if (event.logicalKey == LogicalKeyboardKey.keyE &&
              HardwareKeyboard.instance.isControlPressed) {
            onExcelExport?.call();
            return KeyEventResult.handled;
          }

          // Ctrl+Shift+C: データクリア
          if (event.logicalKey == LogicalKeyboardKey.keyC &&
              HardwareKeyboard.instance.isControlPressed &&
              HardwareKeyboard.instance.isShiftPressed) {
            onClearData?.call();
            return KeyEventResult.handled;
          }

          // Space: ストップウォッチ開始/停止
          if (event.logicalKey == LogicalKeyboardKey.space) {
            // ストップウォッチの状態に応じて開始/停止を切り替え
            // この処理は親コンポーネントで行う
            onStartStopwatch?.call();
            return KeyEventResult.handled;
          }

          // R: ストップウォッチリセット
          if (event.logicalKey == LogicalKeyboardKey.keyR) {
            onResetStopwatch?.call();
            return KeyEventResult.handled;
          }

          // Enter: 時間記録
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            onRecordTime?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

// ショートカットヘルプダイアログ
class ShortcutsHelpDialog extends StatelessWidget {
  const ShortcutsHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('キーボードショートカット'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ファイル操作:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Ctrl+S: データ保存'),
          Text('Ctrl+E: Excel出力'),
          Text('Ctrl+Shift+C: データクリア'),
          SizedBox(height: 16),
          Text('ストップウォッチ:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Space: 開始/停止'),
          Text('R: リセット'),
          Text('Enter: 時間記録'),
          SizedBox(height: 16),
          Text('その他:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Tab: セル間移動'),
          Text('矢印キー: セル選択'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
