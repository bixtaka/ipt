import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import './editable_value_tile.dart';
import './number_pad_sheet.dart';
import '../styles.dart';

class PassCard extends StatelessWidget {
  const PassCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final currentPass = appState.passes[appState.currentPassIndex];

        String _fmtSec(num? s) {
          if (s == null) return '-';
          final secs = s.round();
          final m = (secs ~/ 60).toString().padLeft(2, '0');
          final ss = (secs % 60).toString().padLeft(2, '0');
          return '$m:$ss';
        }

        // Derived values
        final lengthCm = appState.settings.weldingLengthCm;
        final double? workSec = currentPass.segments.isNotEmpty
            ? currentPass.weldingTotal.inSeconds.toDouble()
            : currentPass.weldTimeSec;
        final double? speed = (lengthCm != null && lengthCm > 0 && workSec != null && workSec > 0)
            ? (lengthCm / (workSec / 60.0))
            : currentPass.speed;
        final double? heat = (currentPass.amps != null && currentPass.volts != null && speed != null && speed > 0)
            ? ((currentPass.amps! * currentPass.volts! * 60) / (speed * 1000))
            : currentPass.heatInput;

        return Container(
          margin: const EdgeInsets.all(AppStyles.spacingM),
          padding: const EdgeInsets.all(AppStyles.spacingM),
          decoration: AppStyles.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'パス ${currentPass.index}',
                    style: AppStyles.heading.copyWith(color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spacingM),

              // Row 1: 開始温度 / 終了温度 / 電流 / 電圧
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => NumberPadSheet(
                            field: 'tStart',
                            currentValue: currentPass.tStart,
                            onValueChanged: (v) => appState.setPassTStart(appState.currentPassIndex, v),
                          ),
                        );
                      },
                      child: AbsorbPointer(
                        absorbing: true,
                        child: EditableValueTile(
                          label: '開始温度',
                          value: currentPass.tStart?.toString(),
                          unit: '℃',
                          keyboardType: TextInputType.number,
                          hintText: '例: 120',
                          dense: true,
                          onSubmitted: (_) {},
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => NumberPadSheet(
                            field: 'tEnd',
                            currentValue: currentPass.tEnd,
                            onValueChanged: (v) => appState.setPassTEnd(appState.currentPassIndex, v),
                          ),
                        );
                      },
                      child: AbsorbPointer(
                        absorbing: true,
                        child: EditableValueTile(
                          label: '終了温度',
                          value: currentPass.tEnd?.toString(),
                          unit: '℃',
                          keyboardType: TextInputType.number,
                          hintText: '例: 120',
                          dense: true,
                          onSubmitted: (_) {},
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => NumberPadSheet(
                            field: 'amps',
                            currentValue: currentPass.amps,
                            onValueChanged: (v) => appState.setPassAmps(appState.currentPassIndex, v),
                          ),
                        );
                      },
                      child: AbsorbPointer(
                        absorbing: true,
                        child: EditableValueTile(
                          label: '電流',
                          value: currentPass.amps?.toString(),
                          unit: 'A',
                          keyboardType: TextInputType.number,
                          dense: true,
                          onSubmitted: (_) {},
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => NumberPadSheet(
                            field: 'volts',
                            currentValue: currentPass.volts,
                            onValueChanged: (v) => appState.setPassVolts(appState.currentPassIndex, v),
                          ),
                        );
                      },
                      child: AbsorbPointer(
                        absorbing: true,
                        child: EditableValueTile(
                          label: '電圧',
                          value: currentPass.volts?.toString(),
                          unit: 'V',
                          keyboardType: TextInputType.number,
                          dense: true,
                          onSubmitted: (_) {},
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spacingS),

              // Row 2: パス/層・スラグ・備考
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => NumberPadSheet(
                            field: 'passLayer',
                            currentValue: currentPass.passLayer == null
                                ? null
                                : int.tryParse(currentPass.passLayer!),
                            onValueChanged: (v) => appState.setPassLayer(appState.currentPassIndex, v.toString()),
                          ),
                        );
                      },
                      child: AbsorbPointer(
                        absorbing: true,
                        child: EditableValueTile(
                          label: 'パス/層',
                          value: currentPass.passLayer,
                          keyboardType: TextInputType.number,
                          hintText: '1',
                          dense: true,
                          onSubmitted: (_) {},
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('有'),
                                  onTap: () {
                                    appState.setPassSlag(appState.currentPassIndex, '有');
                                    Navigator.of(context).pop();
                                  },
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  title: const Text('無'),
                                  onTap: () {
                                    appState.setPassSlag(appState.currentPassIndex, '無');
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: AbsorbPointer(
                        absorbing: true,
                        child: EditableValueTile(
                          label: 'スラグ',
                          value: currentPass.slag,
                          keyboardType: TextInputType.text,
                          hintText: '有/無',
                          dense: true,
                          onSubmitted: (_) {},
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingS),
                  Expanded(
                    flex: 2,
                    child: EditableValueTile(
                      label: '備考',
                      value: currentPass.note,
                      keyboardType: TextInputType.text,
                      maxLines: 1,
                      hintText: 'メモ',
                      dense: true,
                      onSubmitted: (v) => appState.setPassNote(appState.currentPassIndex, v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppStyles.spacingM),
              const Divider(height: 1),
              const SizedBox(height: AppStyles.spacingS),

              // Row 3: Computed values (4 equal columns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ComputedItem(
                      label: '溶接時間',
                      value: currentPass.segments.isNotEmpty
                          ? _fmtSec(currentPass.weldingTotal.inMilliseconds / 1000.0)
                          : _fmtSec(currentPass.weldTimeSec),
                    ),
                  ),
                  Expanded(
                    child: _ComputedItem(
                      label: '停止時間',
                      value: currentPass.segments.isNotEmpty
                          ? _fmtSec(currentPass.stopTotal.inMilliseconds / 1000.0)
                          : _fmtSec(currentPass.pauseSec),
                    ),
                  ),
                  Expanded(
                    child: _ComputedItem(
                      label: '溶接速度',
                      value: speed == null ? '-' : '${speed.toStringAsFixed(1)} cm/min',
                    ),
                  ),
                  Expanded(
                    child: _ComputedItem(
                      label: '入熱',
                      value: heat == null ? '-' : '${heat.toStringAsFixed(2)} kJ/cm',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComputedItem extends StatelessWidget {
  final String label;
  final String value;
  const _ComputedItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.caption.copyWith(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
