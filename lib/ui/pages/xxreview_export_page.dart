import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class ReviewExportPage extends StatefulWidget {
  final Function(int) onNavigateToMeasureTab;

  const ReviewExportPage({
    super.key,
    required this.onNavigateToMeasureTab,
  });

  @override
  State<ReviewExportPage> createState() => _ReviewExportPageState();
}

class _ReviewExportPageState extends State<ReviewExportPage> {
  bool _showOnlyEmpty = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('確認・出力'),
        actions: [
          // 未入力のみ表示の切り替えボタン
          IconButton(
            onPressed: () {
              setState(() {
                _showOnlyEmpty = !_showOnlyEmpty;
              });
            },
            icon: Icon(
              _showOnlyEmpty ? Icons.filter_list : Icons.filter_list_outlined,
              color: _showOnlyEmpty ? Colors.blue : null,
            ),
            tooltip: '未入力のみ表示',
          ),
          // Excel 出力ボタン（現在はダミー）
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Excel出力は未実装です'),
                ),
              );
            },
            icon: const Icon(Icons.table_chart),
            tooltip: 'Excel出力',
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final passes = _showOnlyEmpty
              ? appState.passes
                  .where((pass) =>
                      pass.tStart == null ||
                      pass.tEnd == null ||
                      pass.amps == null ||
                      pass.volts == null ||
                      pass.note == null ||
                      pass.note!.isEmpty)
                  .toList()
              : appState.passes;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Theme(
              data: Theme.of(context).copyWith(
                dataTableTheme: const DataTableThemeData(
                  dataTextStyle: TextStyle(fontSize: 12),
                  headingTextStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 12.0,
                  horizontalMargin: 8.0,
                  headingRowHeight: 32.0,
                  dataRowMinHeight: 28.0,
                  dataRowMaxHeight: 32.0,
                  columns: const [
                    DataColumn(
                      label: Text('パス'),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        '開始\n温度',
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 2,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        '終了\n温度',
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 2,
                      ),
                    ),
                    DataColumn(label: Text('電流')),
                    DataColumn(label: Text('電圧')),
                    DataColumn(
                      label: Text(
                        '入熱\nkJ/cm',
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 2,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        '溶接\n時間',
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 2,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        '停止\n時間',
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 2,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        '溶接速度\ncm/min',
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 2,
                      ),
                    ),
                    DataColumn(label: Text('パス/層')),
                    DataColumn(label: Text('スラグ')),
                    DataColumn(label: Text('備考')),
                  ],
                  rows: passes.map((pass) {
                    return DataRow(
                      cells: [
                        // パス番号（クリックで測定タブへ）
                        DataCell(
                          InkWell(
                            onTap: () {
                              final passIndex = appState.passes.indexOf(pass);
                              if (passIndex != -1) {
                                appState.setCurrentPassIndex(passIndex);
                                widget.onNavigateToMeasureTab(1);
                              }
                            },
                            child: Text(
                              '${pass.index}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        // 開始温度
                        DataCell(
                          _buildEditableCell(
                            context,
                            pass.tStart?.toString() ?? '',
                            (value) => _updatePassField(
                                appState, pass.index, 'tStart', value),
                          ),
                        ),
                        // 終了温度
                        DataCell(
                          _buildEditableCell(
                            context,
                            pass.tEnd?.toString() ?? '',
                            (value) => _updatePassField(
                                appState, pass.index, 'tEnd', value),
                          ),
                        ),
                        // 電流
                        DataCell(
                          _buildEditableCell(
                            context,
                            pass.amps?.toString() ?? '',
                            (value) => _updatePassField(
                                appState, pass.index, 'amps', value),
                          ),
                        ),
                        // 電圧
                        DataCell(
                          _buildEditableCell(
                            context,
                            pass.volts == null
                                ? ''
                                : pass.volts!.toDouble().toStringAsFixed(1),
                            (value) => _updatePassField(
                                appState, pass.index, 'volts', value),
                          ),
                        ),
                        // 入熱
                        DataCell(
                          Text(
                            pass.heatInput == null
                                ? '--'
                                : '${_trimNum(pass.heatInput!)} kJ/cm',
                            style: TextStyle(
                              color: pass.heatInput == null
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        // 溶接時間
                        DataCell(
                          Text(
                            _formatWeldTime(pass.weldTimeSec),
                            style: TextStyle(
                              color: pass.weldTimeSec == null
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        // 停止時間
                        DataCell(
                          Text(
                            _formatWeldTime(pass.pauseSec),
                            style: TextStyle(
                              color: pass.pauseSec == null
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        // 溶接速度
                        DataCell(
                          Text(
                            pass.speed == null
                                ? '--'
                                : '${_trimNum(pass.speed!)} cm/min',
                            style: TextStyle(
                              color: pass.speed == null
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        // パス/層
                        DataCell(
                          _buildEditableCell(
                            context,
                            pass.passLayer ?? '',
                            (value) => _updatePassField(
                                appState, pass.index, 'passLayer', value),
                          ),
                        ),
                        // スラグ
                        DataCell(
                          _buildEditableCell(
                            context,
                            pass.slag ?? '',
                            (value) => _updatePassField(
                                appState, pass.index, 'slag', value),
                          ),
                        ),
                        // 備考
                        DataCell(
                          _buildEditableCell(
                            context,
                            pass.note ?? '',
                            (value) => _updatePassField(
                                appState, pass.index, 'note', value),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditableCell(
    BuildContext context,
    String currentValue,
    Function(String) onChanged,
  ) {
    return InkWell(
      onTap: () => _showEditDialog(context, currentValue, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Text(
          currentValue.isEmpty ? '-' : currentValue,
          style: TextStyle(
            color: currentValue.isEmpty ? Colors.grey : Colors.black87,
            fontStyle:
                currentValue.isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String currentValue,
    Function(String) onChanged,
  ) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('値を入力してください'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '値を入力してください',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            onChanged(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              onChanged(controller.text);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _updatePassField(
      AppState appState, int passIndex, String field, String value) {
    final idx0 = passIndex - 1;
    switch (field) {
      case 'tStart':
        final intValue = int.tryParse(value);
        appState.setPassTStart(idx0, intValue);
        break;
      case 'tEnd':
        final intValue = int.tryParse(value);
        appState.setPassTEnd(idx0, intValue);
        break;
      case 'amps':
        final intValue = int.tryParse(value);
        appState.setPassAmps(idx0, intValue);
        break;
      case 'volts':
        final intValue = int.tryParse(value);
        appState.setPassVolts(idx0, intValue);
        break;
      case 'note':
        appState.setPassNote(idx0, value.isEmpty ? null : value);
        break;
      case 'passLayer':
        appState.setPassLayer(idx0, value.isEmpty ? null : value);
        break;
      case 'slag':
        appState.setPassSlag(idx0, value.isEmpty ? null : value);
        break;
    }
  }

  // ========== Helpers ==========
  static String _formatWeldTime(double? sec) {
    if (sec == null) return '--:--';
    final total = sec.floor();
    final mm = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  static String _trimNum(double v) {
    // 小数2桁までにして末尾の0を削除
    final s = v.toStringAsFixed(2);
    return s.contains('.')
        ? s.replaceFirst(RegExp(r'\.0+$'), '').replaceFirst(RegExp(r'0+$'), '')
        : s;
  }
}
