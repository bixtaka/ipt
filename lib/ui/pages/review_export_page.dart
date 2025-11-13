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
        title: const Text('\u78BA\u8A8D\u30FB\u51FA\u529B'),
        actions: [
          // Filter button
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
            tooltip: '\u672A\u5165\u529B\u306E\u307F\u8868\u793A',
          ),
          // Excel export button
          // Excel export button
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Excel\\u51FA\\u529B\\u306F\\u672A\\u5B9F\\u88C5\\u3067\\u3059'),
                ),
              );
            },
            icon: const Icon(Icons.table_chart),
            tooltip: 'Excel\\u51FA\\u529B',
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

                  columns: [
                  // Fixed first column
                  const DataColumn(
                    label: Text('\u30D1\u30B9'),
                    numeric: true,
                  ),
                  // Editable columns
                  const DataColumn(
                    label: Text(
                      '\u958B\u59CB\n\u6E29\u5EA6',
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      '\u7D42\u4E86\n\u6E29\u5EA6',
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                  const DataColumn(label: Text('\u96FB\u6D41')),
                  const DataColumn(label: Text('\u96FB\u5727')),
                  const DataColumn(
                    label: Text(
                      '\u5165\u71B1\nkJ/cm',
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                  // Readonly computed columns
                  const DataColumn(
                    label: Text(
                      '\u6EB6\u63A5\n\u6642\u9593',
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      '\u505C\u6B62\n\u6642\u9593',
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      '\u6EB6\u63A5\u901F\u5EA6\ncm/min',
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                  const DataColumn(label: Text('\u30D1\u30B9/\u5C64')),
                  const DataColumn(label: Text('\u30B9\u30E9\u30B0')),
                  const DataColumn(label: Text('\u5099\u8003')),
                ],

                rows: passes.map((pass) {
                  return DataRow(
                    cells: [
                      // Pass number (fixed column) - clickable to navigate
                      DataCell(
                        InkWell(
                          onTap: () {
                            final passIndex = appState.passes.indexOf(pass);
                            if (passIndex != -1) {
                              appState.setCurrentPassIndex(passIndex);
                              widget.onNavigateToMeasureTab(
                                  1); // Navigate to MeasurePage tab
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
                      // Editable temperature fields
                      DataCell(
                        _buildEditableCell(
                          context,
                          pass.tStart?.toString() ?? '',
                          (value) => _updatePassField(
                              appState, pass.index, 'tStart', value),
                        ),
                      ),
                      DataCell(
                        _buildEditableCell(
                          context,
                          pass.tEnd?.toString() ?? '',
                          (value) => _updatePassField(
                              appState, pass.index, 'tEnd', value),
                        ),
                      ),
                      // Editable electrical fields
                      DataCell(
                        _buildEditableCell(
                          context,
                          pass.amps?.toString() ?? '',
                          (value) => _updatePassField(
                              appState, pass.index, 'amps', value),
                        ),
                      ),
                      DataCell(
                        _buildEditableCell(
                          context,
                          (pass.volts == null ? '' : pass.volts!.toDouble().toStringAsFixed(1)),
                          (value) => _updatePassField(
                              appState, pass.index, 'volts', value),
                        ),
                      ),
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
                      // Readonly computed fields (bind to model)
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
                      DataCell(
                        _buildEditableCell(
                          context,
                          pass.passLayer ?? '',
                          (value) => _updatePassField(
                              appState, pass.index, 'passLayer', value),
                        ),
                      ),
                      DataCell(
                        _buildEditableCell(
                          context,
                          pass.slag ?? '',
                          (value) => _updatePassField(
                              appState, pass.index, 'slag', value),
                        ),
                      ),
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
        title: const Text('確認・出力'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '新しい値',
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
    // Keep at most 2 decimals, drop trailing zeros
    final s = v.toStringAsFixed(2);
    return s.contains('.') ? s.replaceFirst(RegExp(r'\.0+$'), '').replaceFirst(RegExp(r'0+$'), '') : s;
  }
}
