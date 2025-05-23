import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/info_form.dart';
import 'package:flutter/scheduler.dart';
import '../services/excel_exporter.dart';

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
    '溶接長',
    '天気',
    '気温'
  ];
  late List<TextEditingController> _infoControllers;

  final List<String> columnTitles = [
    'パス数',
    'パス温度開始',
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
    // 🟡 初期値設定：1行目にパス数「1」、作業開始「00:00」
    _controllers[0][0].text = '1'; // パス数（0列目）
    _controllers[0][8].text = '00:00'; // 作業開始（8列目）
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

  // 必要に応じてロジックを追加
  void _updateCalculatedFields() {
    setState(() {
      for (int row = 0; row < initialRowCount; row++) {
        final startText = _controllers[row][8].text; // 作業開始
        final endText = _controllers[row][9].text; // 作業終了

        if (startText.isEmpty || endText.isEmpty) {
          _controllers[row][7].text = ''; // 溶接時間
          _controllers[row][6].text = ''; // 速度
          _controllers[row][10].text = ''; // インターバル
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
          _controllers[row][6].text = '';
          _controllers[row][10].text = '';
          continue;
        }

        String formatTime(int totalSec) {
          final m = (totalSec ~/ 60).toString().padLeft(2, '0');
          final s = (totalSec % 60).toString().padLeft(2, '0');
          return '$m:$s';
        }

        _controllers[row][7].text = formatTime(weldingTime);

        // 速度計算（溶接長 ÷ 溶接時間（分））
        double weldingLength = double.tryParse(_infoControllers[10].text) ?? 0;
        if (weldingLength > 0) {
          double speedValue = weldingLength / (weldingTime / 60);
          _controllers[row][6].text = speedValue.toStringAsFixed(2);
        } else {
          _controllers[row][6].text = '';
        }

        // インターバル計算は次の行の開始時間 - 今の行の終了時間
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
          // 最終行はインターバル空欄
          _controllers[row][10].text = '';
        }
      }
    });
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
        final heatInput = (current * voltage * 60) / (speed * 1000);
        _controllers[row][3].text = heatInput.toStringAsFixed(2);
      } catch (_) {}
    });
  }

// _downloadExcel の中身
  void _downloadExcel() async {
    try {
      // 情報入力データを2次元リストに変換
      List<List<String>> infoData = [
        infoLabels,
        _infoControllers.map((c) => c.text).toList(),
      ];

      // 測定値データを2次元リストに変換
      List<List<String>> measurementData = [];

      measurementData.add(columnTitles);

      for (int row = 0; row < _controllers.length; row++) {
        List<String> rowData = [];
        for (int col = 0; col < columnTitles.length; col++) {
          rowData.add(_controllers[row][col].text);
        }
        measurementData.add(rowData);
      }

      // ★ 2つの引数を渡す ★
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

  Widget _buildMeasurementTableView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text('⏱ $_displayTime', style: const TextStyle(fontSize: 24)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: _startStopwatch, child: const Text('Start')),
              const SizedBox(width: 8),
              ElevatedButton(
                  onPressed: _stopStopwatch, child: const Text('Stop')),
              const SizedBox(width: 8),
              ElevatedButton(
                  onPressed: _resetStopwatch, child: const Text('Reset')),
              const SizedBox(width: 8),
              ElevatedButton(
                  onPressed: _fillSelectedCellWithTime,
                  child: const Text('記録')),
              const SizedBox(width: 8),
              ElevatedButton(
                  onPressed: () => _calculateHeatInputAt(_selectedRow ?? 0),
                  child: const Text('入熱')),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                Row(
                  children: columnTitles.map((title) {
                    return Container(
                      width: 80,
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.center,
                      child: Text(title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                ),
                ...List.generate(_controllers.length, (rowIndex) {
                  return Row(
                    children: List.generate(columnTitles.length, (colIndex) {
                      final isSelected = _selectedRow == rowIndex &&
                          _selectedColumn == colIndex;
                      final controller = _controllers[rowIndex][colIndex];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _selectedRow = rowIndex;
                            _selectedColumn = colIndex;
                          });
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.all(2),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            border: colIndex == 0
                                ? null
                                : Border.all(color: Colors.grey),
                            color: colIndex == 0
                                ? Theme.of(context).scaffoldBackgroundColor
                                : isSelected
                                    ? Colors.lightBlueAccent.withOpacity(0.3)
                                    : Colors.white,
                          ),
                          child: TextField(
                            controller: controller,
                            readOnly: [0, 3, 6, 7, 10].contains(colIndex),
                            textAlign: colIndex == 0
                                ? TextAlign.right
                                : TextAlign.center,
                            decoration:
                                const InputDecoration(border: InputBorder.none),
                            keyboardType: TextInputType.numberWithOptions(
                                decimal: true, signed: false),
                            onTap: () {
                              setState(() {
                                _selectedRow = rowIndex;
                                _selectedColumn = colIndex;
                              });
                            },
                            onChanged: (_) {
                              // 🟨 最終行に入力があれば、新しい行を追加
                              if (rowIndex == _controllers.length - 1) {
                                setState(() {
                                  _controllers.add(
                                    List.generate(columnTitles.length,
                                        (_) => TextEditingController()),
                                  );
                                });
                              }

                              // パス数を自動設定
                              if (colIndex == 1) {
                                setState(() {
                                  _controllers[rowIndex][0].text =
                                      (rowIndex + 1).toString();
                                });
                              }

                              if (colIndex == 10) {
                                _calculateHeatInputAt(rowIndex);
                              }

                              _updateCalculatedFields();
                            },
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('測定データ入力'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '情報入力'),
            Tab(text: '測定値入力'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          InfoForm(
            infoLabels: infoLabels,
            controllers: _infoControllers,
            onChanged: (index) {
              _updateCalculatedFields();
              if (index == 11) {
                _calculateHeatInputAt(_selectedRow ?? 0);
              }
            },
          ),
          _buildMeasurementTableView(),
        ],
      ),
    );
  }
}
