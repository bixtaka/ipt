import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../styles.dart';
import 'number_pad_sheet.dart';

class QuickInputBar extends StatelessWidget {
  const QuickInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final currentPass = appState.passes[appState.currentPassIndex];

        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 開始温度
              Expanded(
                child: _buildInputField(
                  context,
                  '開始温度',
                  currentPass.tStart?.toString() ?? '',
                  () => _showNumberPad(context, appState, 'tStart'),
                ),
              ),
              const SizedBox(width: 8),
              // 終了温度
              Expanded(
                child: _buildInputField(
                  context,
                  '終了温度',
                  currentPass.tEnd?.toString() ?? '',
                  () => _showNumberPad(context, appState, 'tEnd'),
                ),
              ),
              const SizedBox(width: 8),
              // 電流
              Expanded(
                child: _buildInputField(
                  context,
                  '電流',
                  currentPass.amps?.toString() ?? '',
                  () => _showNumberPad(context, appState, 'amps'),
                ),
              ),
              const SizedBox(width: 8),
              // 電圧
              Expanded(
                child: _buildInputField(
                  context,
                  '電圧',
                  (currentPass.volts == null ? null : currentPass.volts!.toDouble().toStringAsFixed(1)) ?? '',
                  () => _showNumberPad(context, appState, 'volts'),
                ),
              ),
              const SizedBox(width: 8),
              // 備考
              Expanded(
                child: _buildInputField(
                  context,
                  '備考',
                  currentPass.note ?? '',
                  () => _showNoteInput(context, appState),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputField(
    BuildContext context,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    // Determine validation status and color
    Color borderColor = Colors.grey.shade300;
    bool hasError = false;

    if (value.isNotEmpty) {
      final intValue = int.tryParse(value);
      if (intValue != null) {
        switch (label) {
          case '開始温度':
          case '終了温度':
            hasError = !AppStyles.isValidTemperature(intValue);
            break;
          case '電流':
            hasError = !AppStyles.isValidAmps(intValue);
            break;
          case '電圧':
            hasError = !AppStyles.isValidVolts(intValue);
            break;
        }
        if (hasError) {
          borderColor = Colors.red;
        }
      }
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppStyles.spacingM,
          horizontal: AppStyles.spacingS,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: hasError ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(AppStyles.radiusS),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppStyles.minTouchTarget,
            maxHeight: AppStyles.minTouchTarget,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppStyles.caption.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: AppStyles.spacingXS),
              Flexible(
                child: Text(
                  value.isEmpty ? '-' : value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasError ? Colors.red : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNumberPad(BuildContext context, AppState appState, String field) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => NumberPadSheet(
        field: field,
        currentValue: _getCurrentValue(appState, field),
        onValueChanged: (value) => _updateField(appState, field, value),
      ),
    );
  }

  void _showNoteInput(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildNoteBottomSheet(context, appState),
    );
  }

  Widget _buildNoteBottomSheet(BuildContext context, AppState appState) {
    final currentPass = appState.passes[appState.currentPassIndex];
    final presetChips = ['欠陥なし', 'スパッタ多め', '姿勢変更'];

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '備考',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Preset chips
          Wrap(
            spacing: 8,
            children: presetChips.map((preset) {
              return ActionChip(
                label: Text(preset),
                onPressed: () {
                  appState.setPassNote(appState.currentPassIndex, preset);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Custom input
          TextField(
            decoration: const InputDecoration(
              labelText: 'カスタム入力',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: currentPass.note ?? ''),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                appState.setPassNote(appState.currentPassIndex, value);
              }
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  int? _getCurrentValue(AppState appState, String field) {
    final currentPass = appState.passes[appState.currentPassIndex];
    switch (field) {
      case 'tStart':
        return currentPass.tStart;
      case 'tEnd':
        return currentPass.tEnd;
      case 'amps':
        return currentPass.amps;
      case 'volts':
        return currentPass.volts;
      default:
        return null;
    }
  }

  void _updateField(AppState appState, String field, int value) {
    switch (field) {
      case 'tStart':
        appState.setPassTStart(appState.currentPassIndex, value);
        break;
      case 'tEnd':
        appState.setPassTEnd(appState.currentPassIndex, value);
        break;
      case 'amps':
        appState.setPassAmps(appState.currentPassIndex, value);
        break;
      case 'volts':
        appState.setPassVolts(appState.currentPassIndex, value);
        break;
    }
  }
}


