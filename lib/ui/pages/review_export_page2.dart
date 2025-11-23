import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../services/excel_exporter.dart';
import '../../services/pdf_exporter.dart';
import '../../services/measurement_repository.dart';
import 'history_page.dart';

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
  final _repo = MeasurementRepository();

  // ===== Excel Export =====
  Future<void> _exportToExcel() async {
    try {
      final app = context.read<AppState>();
      final infoData = _buildInfoData(app);
      final measurementData = _buildMeasurementData(app);
      await exportExcelWithInfo(infoData, measurementData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excelファイルを保存しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel出力に失敗しました: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Excel出力エラー'),
          content: SingleChildScrollView(child: Text('$e')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    }
  }

  // ===== PDF Export =====
  Future<void> _exportToPdf() async {
    try {
      final app = context.read<AppState>();
      final measurementData = _buildMeasurementData(app);
      await exportPdfReport(
        settings: app.settings,
        passes: app.passes,
        measurementData: measurementData,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDFを保存しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF出力に失敗しました: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('PDF出力エラー'),
          content: SingleChildScrollView(child: Text('$e')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _exportToPdfLocal() async {
    try {
      final app = context.read<AppState>();
      final measurementData = _buildMeasurementData(app);
      // Prefer public Download on Android; fallback handled inside exporter.
      const path = '/sdcard/Download/ipt_report.pdf';
      final savedPath = await exportPdfReportToFile(
        settings: app.settings,
        passes: app.passes,
        measurementData: measurementData,
        filePath: path,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDFを保存しました: $savedPath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF保存に失敗しました: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  List<List<String>> _buildInfoData(AppState app) {
    final s = app.settings;
    final dateStr = _fmtDate(s.measurementDate);
    return [
      <String>[
        '工事名',
        '測定日',
        '製品符号',
        '位置',
        '部材',
        '材質',
        '開先角度',
        'ルート間隔',
        '溶接姿勢',
        '溶接長(cm)',
      ],
      <String>[
        s.projectName ?? '',
        dateStr,
        s.productCode ?? '',
        s.location ?? '',
        s.part ?? '',
        s.material ?? '',
        s.grooveAngle ?? '',
        s.rootGap ?? '',
        s.posture ?? '',
        s.weldingLengthCm?.toString() ?? '',
      ],
    ];
  }

  List<List<String>> _buildMeasurementData(AppState app) {
    final headers = <String>[
      'パス',
      '開始温度',
      '終了温度',
      '電流',
      '電圧',
      '入熱(kJ/cm)',
      '溶接時間',
      '停止時間',
      '溶接速度(cm/min)',
      'パス/層',
      'スラグ',
      '備考',
    ];
    final rows = <List<String>>[];
    rows.add(headers);

    final lengthCm = app.settings.weldingLengthCm;
    for (final p in app.passes) {
      final double? workSec = p.segments.isNotEmpty
          ? p.weldingTotal.inSeconds.toDouble()
          : p.weldTimeSec;
      final double? speed =
          (lengthCm != null && lengthCm > 0 && workSec != null && workSec > 0)
              ? (lengthCm / (workSec / 60.0))
              : p.speed;
      final int? amps = p.amps;
      final double? volts = p.volts?.toDouble();
      final double? heat =
          (speed != null && speed > 0 && amps != null && volts != null)
              ? ((amps * volts * 60) / (speed * 1000))
              : p.heatInput;

      rows.add(<String>[
        p.index.toString(),
        p.tStart?.toString() ?? '',
        p.tEnd?.toString() ?? '',
        p.amps?.toString() ?? '',
        volts == null ? '' : volts.toStringAsFixed(1),
        heat == null ? '' : _trimNum(heat),
        _formatWeldTime(workSec),
        _formatWeldTime(p.pauseSec),
        speed == null ? '' : _trimNum(speed),
        p.passLayer ?? '',
        p.slag ?? '',
        p.note ?? '',
      ]);
    }

    return rows;
  }

  static String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('確認・出力'),
        actions: [
          IconButton(
            onPressed: () async {
              final app = context.read<AppState>();
              final rec = app.toRecord();
              final loadedId = app.loadedRecordId;
              if (loadedId == null) {
                await _repo.add(rec);
              } else {
                final existing = await _repo.findById(loadedId);
                if (existing != null) {
                  final updated = rec.copyWith(
                    id: existing.id,
                    createdAt: existing.createdAt,
                  );
                  await _repo.update(updated);
                } else {
                  await _repo.add(rec);
                }
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('保存しました'),
                  action: SnackBarAction(
                    label: '履歴を見る',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HistoryPage()),
                      );
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.save_outlined),
            tooltip: '測定データを保存',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
            icon: const Icon(Icons.history),
            tooltip: '履歴',
          ),
          IconButton(
            onPressed: () => setState(() => _showOnlyEmpty = !_showOnlyEmpty),
            icon: Icon(
              _showOnlyEmpty ? Icons.filter_list : Icons.filter_list_outlined,
              color: _showOnlyEmpty ? Colors.blue : null,
            ),
            tooltip: '未入力のみ表示',
          ),
          IconButton(
            onPressed: _exportToExcel,
            icon: const Icon(Icons.table_chart),
            tooltip: 'Excel出力',
          ),
          IconButton(
            onPressed: _exportToPdfLocal,
            icon: const Icon(Icons.download),
            tooltip: 'PDF保存(Download)',
          ),
          IconButton(
            onPressed: _exportToPdf,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDF出力',
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final passes = _showOnlyEmpty
              ? appState.passes
                  .where((p) =>
                      p.tStart == null ||
                      p.tEnd == null ||
                      p.amps == null ||
                      p.volts == null ||
                      (p.note == null || p.note!.isEmpty))
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
                    DataColumn(label: Text('パス'), numeric: true),
                    DataColumn(label: Text('開始\n温度')),
                    DataColumn(label: Text('終了\n温度')),
                    DataColumn(label: Text('電流')),
                    DataColumn(label: Text('電圧')),
                    DataColumn(label: Text('入熱\nkJ/cm')),
                    DataColumn(label: Text('溶接\n時間')),
                    DataColumn(label: Text('停止\n時間')),
                    DataColumn(label: Text('溶接速度\ncm/min')),
                    DataColumn(label: Text('パス/層')),
                    DataColumn(label: Text('スラグ')),
                    DataColumn(label: Text('備考')),
                  ],
                  rows: passes.map((pass) {
                    return DataRow(cells: [
                      DataCell(
                        InkWell(
                          onTap: () {
                            final idx = appState.passes.indexOf(pass);
                            if (idx != -1) {
                              appState.setCurrentPassIndex(idx);
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
                      DataCell(_buildEditableCell(
                        context,
                        pass.tStart?.toString() ?? '',
                        (v) =>
                            _updatePassField(appState, pass.index, 'tStart', v),
                      )),
                      DataCell(_buildEditableCell(
                        context,
                        pass.tEnd?.toString() ?? '',
                        (v) =>
                            _updatePassField(appState, pass.index, 'tEnd', v),
                      )),
                      DataCell(_buildEditableCell(
                        context,
                        pass.amps?.toString() ?? '',
                        (v) =>
                            _updatePassField(appState, pass.index, 'amps', v),
                      )),
                      DataCell(_buildEditableCell(
                        context,
                        pass.volts == null
                            ? ''
                            : pass.volts!.toDouble().toStringAsFixed(1),
                        (v) =>
                            _updatePassField(appState, pass.index, 'volts', v),
                      )),
                      DataCell(Text(
                        pass.heatInput == null
                            ? '--'
                            : '${_trimNum(pass.heatInput!)} kJ/cm',
                        style: TextStyle(
                          color: pass.heatInput == null
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      )),
                      DataCell(Text(
                        _formatWeldTime(pass.weldTimeSec),
                        style: TextStyle(
                          color: pass.weldTimeSec == null
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      )),
                      DataCell(Text(
                        _formatWeldTime(pass.pauseSec),
                        style: TextStyle(
                          color: pass.pauseSec == null
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      )),
                      DataCell(Text(
                        pass.speed == null
                            ? '--'
                            : '${_trimNum(pass.speed!)} cm/min',
                        style: TextStyle(
                          color:
                              pass.speed == null ? Colors.grey : Colors.black87,
                        ),
                      )),
                      DataCell(_buildEditableCell(
                        context,
                        pass.passLayer ?? '',
                        (v) => _updatePassField(
                            appState, pass.index, 'passLayer', v),
                      )),
                      DataCell(_buildEditableCell(
                        context,
                        pass.slag ?? '',
                        (v) =>
                            _updatePassField(appState, pass.index, 'slag', v),
                      )),
                      DataCell(_buildEditableCell(
                        context,
                        pass.note ?? '',
                        (v) =>
                            _updatePassField(appState, pass.index, 'note', v),
                      )),
                    ]);
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
        title: const Text('確認・入力'),
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
    final s = v.toStringAsFixed(2);
    if (!s.contains('.')) return s;
    return s
        .replaceFirst(RegExp(r'\.0+$'), '')
        .replaceFirst(RegExp(r'0+$'), '');
  }
}
