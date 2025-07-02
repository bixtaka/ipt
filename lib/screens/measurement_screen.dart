import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/info_form.dart';
import 'package:flutter/scheduler.dart';
import '../services/excel_exporter.dart';
import '../widgets/stopwatch_controls.dart';
import '../widgets/measurement_table.dart';

class MeasurementTabbedScreen extends StatefulWidget {
  const MeasurementTabbedScreen({super.key});

  @override
  State<MeasurementTabbedScreen> createState() =>
      _MeasurementTabbedScreenState();
}

class _MeasurementTabbedScreenState extends State<MeasurementTabbedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> infoLabels = [
    '工事名',
    '測定日',
    '製品符号',
    '位置',
    '部材',
    '材質',
    '開先角度',
    'ルート間隔',
    '溶接姿勢',
    '溶接技能者',
    '積層数',
    '板厚', // ← 追加
    '溶接長',
    '天気',
    '気温'
  ];
  late List<TextEditingController> _infoControllers;

  final List<String> columnTitles = [
    'パス数',
    'パス間温度開始',
    'パス間温度終了',
    '入熱',
    '電流',
    '電圧',
    '速度',
    '溶接時間',
    '作業開始',
    '作業終了',
    'インターバル',
    '備考'
  ];
  final int initialRowCount = 20;
  late List<List<TextEditingController>> _controllers;

  // ストップウォッチ関連
  final Stopwatch _stopwatch = Stopwatch();
  late final Ticker _ticker;
  String _displayTime = '00:00';

  // セル選択
  int? _selectedRow;
  int? _selectedColumn;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _infoControllers =
        List.generate(infoLabels.length, (_) => TextEditingController());
    _controllers = List.generate(
      initialRowCount,
      (_) => List.generate(columnTitles.length, (_) => TextEditingController()),
    );
    _ticker = Ticker(_onTick)..start();

    // 🟡 ダミーデータをセット
    /* _infoControllers[0].text = '○○工事'; // 工事名
    _infoControllers[1].text = '2025-07-02'; // 測定日
    _infoControllers[2].text = 'TEST-001';
    _infoControllers[3].text = 'A-1';
    _infoControllers[4].text = '部材ダミー';
    _infoControllers[5].text = 'SS400';
    _infoControllers[6].text = '30';
    _infoControllers[7].text = '2.0';
    _infoControllers[8].text = 'PA';
    _infoControllers[9].text = '山田太郎';
    _infoControllers[10].text = '3'; // 積層数
    _infoControllers[11].text = '12'; // 板厚（例）
    _infoControllers[12].text = '300'; // 溶接長
    _infoControllers[13].text = '晴れ';
    _infoControllers[14].text = '25';

    for (int row = 0; row < _controllers.length; row++) {
      _controllers[row][0].text = (row + 1).toString(); // パス数
      _controllers[row][1].text = (100 + row).toString(); // パス間温度開始
      _controllers[row][2].text = (110 + row).toString(); // パス間温度終了
      _controllers[row][3].text = (row % 2 == 0) ? '12.34' : '15.67'; // 入熱
      _controllers[row][4].text = '120'; // 電流
      _controllers[row][5].text = '24'; // 電圧
      _
      _controllers[row][7].text = '01:30'; // 溶接時間
      _controllers[row][8].text = '08:00'; // 作業開始
      _controllers[row][9].text = '08:10'; // 作業終了
      _controllers[row][10].text = '00:10'; // インターバル
      _controllers[row][11].text = '備考テスト${row + 1}'; // 備考
    }*/
    _controllers.add(
        List.generate(columnTitles.length, (_) => TextEditingController()));
  }

  void _onTick(Duration elapsed) {
    if (_stopwatch.isRunning) {
      final int seconds = _stopwatch.elapsed.inSeconds;
      final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
      final secs = (seconds % 60).toString().padLeft(2, '0');
      setState(() {
        _displayTime = '$minutes:$secs';
      });
    }
  }

  void _startStopwatch() => setState(() => _stopwatch.start());
  void _stopStopwatch() => setState(() => _stopwatch.stop());
  void _resetStopwatch() => setState(() {
        _stopwatch.reset();
        _displayTime = '00:00';
      });

  static const int startWorkCol = 8; // 作業開始の列インデックス
  static const int endWorkCol = 9; // 作業終了の列インデックス
  void _fillSelectedCellWithTime() {
    if (_selectedRow != null && _selectedColumn != null) {
      if (_selectedColumn != startWorkCol && _selectedColumn != endWorkCol) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('作業開始か作業終了のセルを選択してください')),
        );
        return;
      }

      final int seconds = _stopwatch.elapsed.inSeconds;
      final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
      final secs = (seconds % 60).toString().padLeft(2, '0');
      final currentDisplayTime = '$minutes:$secs';

      final controller = _controllers[_selectedRow!][_selectedColumn!];

      setState(() {
        controller.text = currentDisplayTime;
        _updateCalculatedFields();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('セルを選択してください')),
      );
    }
  }

  void _updateCalculatedFields() {
    for (int row = 0; row < initialRowCount; row++) {
      final startText = _controllers[row][8].text;
      final endText = _controllers[row][9].text;

      if (startText.isEmpty || endText.isEmpty) {
        _controllers[row][7].text = '';
        _controllers[row][10].text = '';
        // 速度(6)・入熱(3)はここでクリアしない
        continue;
      }

      int toSeconds(String timeText) {
        final parts = timeText.split(':');
        if (parts.length != 2) return 0;
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        return minutes * 60 + seconds;
      }

      int startSec = toSeconds(startText);
      int endSec = toSeconds(endText);
      int weldingTime = endSec - startSec;

      if (weldingTime <= 0) {
        _controllers[row][7].text = '';
        _controllers[row][10].text = '';
        // 速度(6)・入熱(3)はここでクリアしない
        continue;
      }

      String formatTime(int totalSec) {
        final m = (totalSec ~/ 60).toString().padLeft(2, '0');
        final s = (totalSec % 60).toString().padLeft(2, '0');
        return '$m:$s';
      }

      _controllers[row][7].text = formatTime(weldingTime);

      // インターバル計算
      if (row < _controllers.length - 1) {
        final nextStartText = _controllers[row + 1][8].text;
        if (nextStartText.isNotEmpty) {
          int nextStartSec = toSeconds(nextStartText);
          int intervalSec = nextStartSec - endSec;
          if (intervalSec > 0) {
            _controllers[row][10].text = formatTime(intervalSec);
          } else {
            _controllers[row][10].text = '';
          }
        } else {
          _controllers[row][10].text = '';
        }
      } else {
        _controllers[row][10].text = '';
      }
    }
    setState(() {});
  }

  Duration? _parseDuration(String text) {
    try {
      final parts = text.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return Duration(minutes: minutes, seconds: seconds);
      }
    } catch (_) {}
    return null;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _calculateHeatInputAt(int row) {
    setState(() {
      try {
        final current = double.tryParse(_controllers[row][4].text) ?? 0;
        final voltage = double.tryParse(_controllers[row][5].text) ?? 0;
        final speed = double.tryParse(_controllers[row][6].text) ?? 1;
        final heatInput = (current * voltage * 60) / (speed * 10);
        _controllers[row][3].text = heatInput.toStringAsFixed(2);
      } catch (_) {}
    });
  }

  void _downloadExcel() async {
    try {
      List<List<String>> infoData = [
        infoLabels,
        _infoControllers.map((c) => c.text).toList(),
      ];

      List<List<String>> measurementData = [];
      measurementData.add(columnTitles);

      for (int row = 0; row < _controllers.length; row++) {
        List<String> rowData = [];
        for (int col = 0; col < columnTitles.length; col++) {
          rowData.add(_controllers[row][col].text);
        }
        measurementData.add(rowData);
      }

      await exportExcelWebWithInfo(infoData, measurementData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excelファイルを保存しました。')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel出力に失敗しました: $e')),
      );
    }
  }

  Widget _buildMeasurementTableViewWidget() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          StopwatchControls(
            displayTime: _displayTime,
            onStart: _startStopwatch,
            onStop: _stopStopwatch,
            onReset: _resetStopwatch,
            onRecord: _fillSelectedCellWithTime,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: MeasurementTable(
              controllers: _controllers,
              columnTitles: columnTitles,
              selectedRow: _selectedRow,
              selectedColumn: _selectedColumn,
              onCellTap: (row, col) {
                setState(() {
                  _selectedRow = row;
                  _selectedColumn = col;
                });
              },
              onCellChanged: (row, col, value) {
                // 最後の行のどこかに入力があったら新しい行を追加
                if (row == _controllers.length - 1 && value.isNotEmpty) {
                  final isLastRowEmpty =
                      _controllers.last.every((c) => c.text.isEmpty);
                  if (!isLastRowEmpty) {
                    setState(() {
                      _controllers.add(List.generate(
                          columnTitles.length, (_) => TextEditingController()));
                    });
                  }
                }

                // 電流(4), 電圧(5), 速度(6)のいずれかが変更されたら速度(6)と入熱(3)を再計算
                if (col == 4 || col == 5 || col == 6 || col == 8 || col == 9) {
                  // 溶接長
                  final weldingLength =
                      double.tryParse(_infoControllers[12].text);
                  // 作業開始・終了
                  final startText = _controllers[row][8].text;
                  final endText = _controllers[row][9].text;

                  int toSeconds(String timeText) {
                    final parts = timeText.split(':');
                    if (parts.length != 2) return 0;
                    final minutes = int.tryParse(parts[0]) ?? 0;
                    final seconds = int.tryParse(parts[1]) ?? 0;
                    return minutes * 60 + seconds;
                  }

                  int startSec = toSeconds(startText);
                  int endSec = toSeconds(endText);
                  int weldingTime = endSec - startSec;

                  // 速度再計算
                  String speedStr = '';
                  if (weldingLength != null && weldingTime > 0) {
                    double speedValue = weldingLength / (weldingTime / 60);
                    speedStr = (speedValue).toStringAsFixed(2);
                  }
                  setState(() {
                    _controllers[row][6].text = speedStr;
                  });

                  // 入熱再計算
                  final current = double.tryParse(_controllers[row][4].text);
                  final voltage = double.tryParse(_controllers[row][5].text);
                  final speed = double.tryParse(_controllers[row][6].text);
                  String heatInput = '';
                  if (current != null &&
                      voltage != null &&
                      speed != null &&
                      speed != 0) {
                    heatInput = ((current * voltage * 60) / (speed * 1000))
                        .toStringAsFixed(2);
                  }
                  setState(() {
                    _controllers[row][3].text = heatInput;
                  });
                }

                if (col == 1) {
                  _controllers[row][0].text = (row + 1).toString();
                }
                if (col == 10) {
                  _calculateHeatInputAt(row);
                }
                _updateCalculatedFields();
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: _downloadExcel, child: const Text('Excel出力')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tabController.dispose();
    for (final controller in _infoControllers) {
      controller.dispose();
    }
    for (final row in _controllers) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final infoList = ListView.builder(
      itemCount: infoLabels.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(infoLabels[index]),
        subtitle: TextField(
          controller: _infoControllers[index],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          ),
          onChanged: (_) {
            setState(() {}); // 入力内容を即時反映
          },
        ),
      ),
    );

    final infoDrawer = Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text('情報',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Expanded(child: infoList),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('測定データ'),
      ),
      drawer: infoDrawer,
      body: _buildMeasurementTableViewWidget(),
    );
  }
}
