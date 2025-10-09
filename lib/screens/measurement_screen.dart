import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../services/excel_exporter.dart';
import '../services/data_storage.dart';
import '../utils/validators.dart';
import '../widgets/stopwatch_controls.dart';
import '../widgets/measurement_table.dart';
import '../widgets/keyboard_shortcuts.dart';
import '../state/app_state.dart';
import 'dart:async';

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
    '板厚',
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
  Timer? _stopwatchTimer;

  // セル選択
  int? _selectedRow;
  int? _selectedColumn;

  // 自動保存関連
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  DateTime? _lastSavedTime;
  bool _suppressChangeNotifications = false;

  // エラー状態
  Map<String, String> _validationErrors = {};

  // オプションリスト
  final List<String> materialOptions = [
    'SS400',
    'SN400A',
    'SN400B',
    'SN490A',
    'SN490B',
  ];

  final List<String> rootGapOptions = [
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  ];

  final List<String> postureOptions = [
    '下向き',
    '横向き',
  ];

  final List<String> welderOptions = [
    '村上裕実',
    '阿曽勇樹',
    '近藤紀幸',
  ];

  final List<String> weatherOptions = [
    '晴れ',
    '曇り',
    '雨',
    '雪',
  ];

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

    // ストップウォッチのTickerを初期化（自動開始はしない）
    _ticker = Ticker(_onTick);

    // デフォルト値の設定
    _setDefaultValues();

    // 保存されたデータの読み込み
    _loadSavedData();

    // 自動保存タイマーの開始
    _startAutoSaveTimer();

    // 入力変更の監視
    _setupInputListeners();
  }

  void _setDefaultValues() {
    // 1行目の作業開始（8列目）を00:00に設定
    _controllers[0][8].text = '00:00';

    // 測定日（1番目のinfoコントローラ）に今日の日付をセット
    _infoControllers[1].text = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 開先角度（7番目）をデフォルトで35°
    _infoControllers[6].text = '35°';

    // 部材（5番目）をデフォルトで "H-  x  x  x" に設定
    _infoControllers[4].text = 'H-  x  x  x';

    // 位置（4番目）をデフォルトで "F-  -" に設定
    _infoControllers[3].text = 'F-  -';
  }

  Future<void> _loadSavedData() async {
    try {
      // 情報データの読み込み
      final savedInfoData = await DataStorageService.loadInfoData();
      if (savedInfoData.isNotEmpty) {
        for (int i = 0;
            i < savedInfoData.length && i < _infoControllers.length;
            i++) {
          _infoControllers[i].text = savedInfoData[i];
        }
      }

      // 測定データの読み込み
      final savedMeasurementData =
          await DataStorageService.loadMeasurementData();
      if (savedMeasurementData.isNotEmpty) {
        // 既存のコントローラーをクリア
        for (final row in _controllers) {
          for (final controller in row) {
            controller.dispose();
          }
        }

        // 新しいコントローラーを作成
        _controllers = savedMeasurementData
            .map((row) =>
                row.map((value) => TextEditingController(text: value)).toList())
            .toList();
      }

      _lastSavedTime = DataStorageService.getLastSavedTime();

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存されたデータを読み込みました'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データの読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupInputListeners() {
    // 情報入力の監視
    for (final controller in _infoControllers) {
      controller.addListener(_onDataChanged);
    }

    // 測定データの監視
    for (final row in _controllers) {
      for (final controller in row) {
        controller.addListener(_onDataChanged);
      }
    }
  }

  void _onDataChanged() {
    if (_suppressChangeNotifications) return;
    _hasUnsavedChanges = true;
    _validateCurrentData();
  }

  void _validateCurrentData() {
    final errors =
        Validators.validateAllData(_infoControllers, _controllers, infoLabels);
    setState(() {
      _validationErrors = errors;
    });
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_hasUnsavedChanges) {
        _saveData();
      }
    });
  }

  Future<void> _saveData() async {
    try {
      await DataStorageService.saveInfoData(_infoControllers);
      await DataStorageService.saveMeasurementData(_controllers);

      setState(() {
        _hasUnsavedChanges = false;
        _lastSavedTime = DateTime.now();
      });

      print('データを自動保存しました: ${DateTime.now()}');
    } catch (e) {
      print('自動保存に失敗しました: $e');
    }
  }

  void _onTick(Duration elapsed) {
    if (_stopwatch.isRunning) {
      final int seconds = _stopwatch.elapsed.inSeconds;
      final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
      final secs = (seconds % 60).toString().padLeft(2, '0');
      setState(() {
        _displayTime = '$minutes:$secs';
      });
      print('タイマー更新: $_displayTime');
    }
  }

  void _stopStopwatch() => setState(() {
        _stopwatch.stop();
        _ticker.stop();
        _stopwatchTimer?.cancel();
      });
  void _resetStopwatch() => setState(() {
        _stopwatch.reset();
        _ticker.stop();
        _stopwatchTimer?.cancel();
        _displayTime = '00:00';
      });

  void _toggleStopwatch() => setState(() {
        print('ストップウォッチ切り替え: 現在の状態=${_stopwatch.isRunning}');
        if (_stopwatch.isRunning) {
          _stopwatch.stop();
          _ticker.stop();
          _stopwatchTimer?.cancel();
          print('ストップウォッチを停止しました');
        } else {
          _stopwatch.start();
          _ticker.start();
          _startStopwatchTimer();
          print('ストップウォッチを開始しました');
        }
      });

  void _startStopwatchTimer() {
    _stopwatchTimer?.cancel();
    _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!_stopwatch.isRunning) return;
      final int seconds = _stopwatch.elapsed.inSeconds;
      final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
      final secs = (seconds % 60).toString().padLeft(2, '0');
      if (_displayTime != '$minutes:$secs') {
        setState(() {
          _displayTime = '$minutes:$secs';
        });
      }
    });
  }

  static const int startWorkCol = 8; // 作業開始の列インデックス
  static const int endWorkCol = 9; // 作業終了の列インデックス

  void _fillSelectedCellWithTime() {
    if (_selectedRow != null && _selectedColumn != null) {
      if (_selectedColumn != startWorkCol && _selectedColumn != endWorkCol) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('作業開始か作業終了のセルを選択してください'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final int seconds = _stopwatch.elapsed.inSeconds;
      final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
      final secs = (seconds % 60).toString().padLeft(2, '0');
      final currentDisplayTime = '$minutes:$secs';

      final controller = _controllers[_selectedRow!][_selectedColumn!];

      _suppressChangeNotifications = true;
      controller.text = currentDisplayTime;
      _suppressChangeNotifications = false;
      _updateCalculatedFields();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('セルを選択してください'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _updateCalculatedFields() {
    _suppressChangeNotifications = true;
    for (int row = 0; row < _controllers.length; row++) {
      final startText = _controllers[row][8].text;
      final endText = _controllers[row][9].text;

      if (startText.isEmpty || endText.isEmpty) {
        _controllers[row][7].text = '';
        _controllers[row][10].text = '';
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
    _suppressChangeNotifications = false;
    setState(() {});
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

  Future<void> _downloadExcel() async {
    try {
      // データ検証
      final errors = Validators.validateAllData(
          _infoControllers, _controllers, infoLabels);
      if (errors.isNotEmpty) {
        final errorCount = errors.length;
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('入力エラー'),
            content: Text('$errorCount個の入力エラーがあります。続行しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('続行'),
              ),
            ],
          ),
        );

        if (shouldContinue != true) return;
      }

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

      await exportExcelWithInfo(infoData, measurementData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Excelファイルを保存しました。'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel出力に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データクリア'),
        content: const Text('すべてのデータをクリアしますか？この操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('クリア'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DataStorageService.clearAllData();

        // コントローラーをクリア
        for (final controller in _infoControllers) {
          controller.clear();
        }
        for (final row in _controllers) {
          for (final controller in row) {
            controller.clear();
          }
        }

        // デフォルト値を再設定
        _setDefaultValues();

        setState(() {
          _hasUnsavedChanges = false;
          _validationErrors.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('すべてのデータをクリアしました'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データのクリアに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMeasurementTableViewWidget() {
    // SafeArea: top を有効、bottom は false にして手動で余白を管理
    return SafeArea(
      top: true,
      bottom: false,
      child: Builder(builder: (context) {
        final mq = MediaQuery.of(context);
        final keyboard = mq.viewInsets.bottom; // ソフトキーボード高さ
        final nav = kBottomNavigationBarHeight; // 外部ボトムナビ高さ
        const margin = 16.0;

        return LayoutBuilder(builder: (context, constraints) {
          // テーブル領域の高さを画面高さの比率で確保（オーバーフロー防止）
          final tableHeight = (constraints.maxHeight * 0.60)
              .clamp(200.0, constraints.maxHeight - 120.0);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              margin,
              margin,
              margin,
              margin + nav + keyboard,
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 保存状態とエラー表示
                  if (_hasUnsavedChanges || _validationErrors.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _validationErrors.isNotEmpty
                            ? Colors.red.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _validationErrors.isNotEmpty
                              ? Colors.red.shade200
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _validationErrors.isNotEmpty
                                ? Icons.error
                                : Icons.info,
                            color: _validationErrors.isNotEmpty
                                ? Colors.red
                                : Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _validationErrors.isNotEmpty
                                  ? '${_validationErrors.length}個の入力エラーがあります'
                                  : '未保存の変更があります',
                              style: TextStyle(
                                color: _validationErrors.isNotEmpty
                                    ? Colors.red.shade700
                                    : Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),
                  Consumer<AppState>(
                    builder: (context, app, child) {
                      final s = app.currentSession;
                      return StopwatchControls(
                        displayTime: _displayTime,
                        isRunning: s.isRunning,
                        isPaused: s.isPaused,
                        events: s.events,
                        onStart: app.startStopwatch,
                        onStop: app.stopStopwatch,
                        onReset: app.resetStopwatch,
                        onRecord: app.recordLap,
                        onPause: app.pauseStopwatch,
                        onResume: app.resumeStopwatch,
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // セッション時間表示
                  Consumer<AppState>(
                    builder: (context, app, child) {
                      final s = app.currentSession;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          '実作業: ${s.totalWork.inSeconds}s  中断: ${s.totalPause.inSeconds}s  合計: ${s.totalElapsed?.inSeconds ?? 0}s',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // テーブルは高さを固定して内部でスクロールさせる
                  SizedBox(
                    height: tableHeight,
                    child: MeasurementTable(
                      controllers: _controllers,
                      columnTitles: columnTitles,
                      selectedRow: _selectedRow,
                      selectedColumn: _selectedColumn,
                      validationErrors: _validationErrors,
                      onCellTap: (row, col) {
                        setState(() {
                          _selectedRow = row;
                          _selectedColumn = col;
                        });
                      },
                      onCellChanged: (row, col, value) {
                        // 元の onCellChanged の処理をそのまま保持
                        if (row == _controllers.length - 1 &&
                            value.isNotEmpty) {
                          final isLastRowEmpty =
                              _controllers.last.every((c) => c.text.isEmpty);
                          if (!isLastRowEmpty) {
                            setState(() {
                              _controllers.add(List.generate(
                                  columnTitles.length,
                                  (_) => TextEditingController()));
                              for (final controller in _controllers.last) {
                                controller.addListener(_onDataChanged);
                              }
                            });
                          }
                        }

                        // 電流(4), 電圧(5), 速度(6)等の再計算
                        if (col == 4 ||
                            col == 5 ||
                            col == 6 ||
                            col == 8 ||
                            col == 9) {
                          final weldingLength =
                              double.tryParse(_infoControllers[12].text);
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

                          String speedStr = '';
                          if (weldingLength != null && weldingTime > 0) {
                            double speedValue =
                                weldingLength / (weldingTime / 60);
                            speedStr = (speedValue).toStringAsFixed(2);
                          }
                          _suppressChangeNotifications = true;
                          _controllers[row][6].text = speedStr;
                          _suppressChangeNotifications = false;

                          final current =
                              double.tryParse(_controllers[row][4].text);
                          final voltage =
                              double.tryParse(_controllers[row][5].text);
                          final speed =
                              double.tryParse(_controllers[row][6].text);
                          String heatInput = '';
                          if (current != null &&
                              voltage != null &&
                              speed != null &&
                              speed != 0) {
                            heatInput =
                                ((current * voltage * 60) / (speed * 1000))
                                    .toStringAsFixed(2);
                          }
                          _suppressChangeNotifications = true;
                          _controllers[row][3].text = heatInput;
                          _suppressChangeNotifications = false;
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
                  const SizedBox(height: 12),

                  // TODO: dev-only - 開発専用デバッグボタン（後で削除）
                  _buildDevDebugPanel(),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        });
      }),
    );
  }

  // TODO: dev-only - 開発専用デバッグパネル（後で削除）
  Widget _buildDevDebugPanel() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final session = appState.currentSession;
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEBUG: Session State',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),

              // デバッグボタン
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ElevatedButton(
                    onPressed: () => appState.startStopwatch(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Start', style: TextStyle(fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: () => appState.pauseStopwatch(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Pause', style: TextStyle(fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: () => appState.resumeStopwatch(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Resume', style: TextStyle(fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: () => appState.stopStopwatch(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Stop', style: TextStyle(fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: () => appState.recordLap(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Record', style: TextStyle(fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: () => appState.resetStopwatch(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // セッション情報表示
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Info:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Work: ${session.totalWork.inSeconds.toStringAsFixed(1)}s',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      'Total Pause: ${session.totalPause.inSeconds.toStringAsFixed(1)}s',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      'Total Elapsed: ${session.totalElapsed?.inSeconds.toStringAsFixed(1) ?? 'null'}s',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      'Status: ${session.isRunning ? 'Running' : session.isPaused ? 'Paused' : 'Stopped'}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
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
      itemBuilder: (context, index) {
        // 材質（6番目）だけドロップダウンにする
        if (infoLabels[index] == '材質') {
          return ListTile(
            title: Text(infoLabels[index]),
            subtitle: DropdownButtonFormField<String>(
              value: _infoControllers[index].text.isNotEmpty
                  ? _infoControllers[index].text
                  : null,
              items: materialOptions
                  .map((mat) => DropdownMenuItem(
                        value: mat,
                        child: Text(mat),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _infoControllers[index].text = value ?? '';
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
            ),
          );
        }
        // ルート間隔（7番目）だけドロップダウンにする
        if (infoLabels[index] == 'ルート間隔') {
          return ListTile(
            title: Text(infoLabels[index]),
            subtitle: DropdownButtonFormField<String>(
              value: _infoControllers[index].text.isNotEmpty
                  ? _infoControllers[index].text
                  : null,
              items: rootGapOptions
                  .map((gap) => DropdownMenuItem(
                        value: gap,
                        child: Text(gap),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _infoControllers[index].text = value ?? '';
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
            ),
          );
        }
        // 溶接姿勢（8番目）だけドロップダウンにする
        if (infoLabels[index] == '溶接姿勢') {
          return ListTile(
            title: Text(infoLabels[index]),
            subtitle: DropdownButtonFormField<String>(
              value: _infoControllers[index].text.isNotEmpty
                  ? _infoControllers[index].text
                  : null,
              items: postureOptions
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _infoControllers[index].text = value ?? '';
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
            ),
          );
        }
        // 溶接技能者（9番目）だけドロップダウンにする
        if (infoLabels[index] == '溶接技能者') {
          return ListTile(
            title: Text(infoLabels[index]),
            subtitle: DropdownButtonFormField<String>(
              value: _infoControllers[index].text.isNotEmpty
                  ? _infoControllers[index].text
                  : null,
              items: welderOptions
                  .map((w) => DropdownMenuItem(
                        value: w,
                        child: Text(w),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _infoControllers[index].text = value ?? '';
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
            ),
          );
        }
        // 天気（14番目）だけドロップダウンにする
        if (infoLabels[index] == '天気') {
          return ListTile(
            title: Text(infoLabels[index]),
            subtitle: DropdownButtonFormField<String>(
              value: _infoControllers[index].text.isNotEmpty
                  ? _infoControllers[index].text
                  : null,
              items: weatherOptions
                  .map((w) => DropdownMenuItem(
                        value: w,
                        child: Text(w),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _infoControllers[index].text = value ?? '';
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
            ),
          );
        }
        // それ以外は従来通りTextField
        return ListTile(
          title: Text(infoLabels[index]),
          subtitle: TextField(
            controller: _infoControllers[index],
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              errorText: _validationErrors['info_$index'],
            ),
            onChanged: (_) {
              setState(() {}); // 入力内容を即時反映
            },
          ),
        );
      },
    );

    final infoDrawer = Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text('情報',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Expanded(child: infoList),
            // 保存状態表示
            if (_lastSavedTime != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '最終保存: ${DateFormat('MM/dd HH:mm').format(_lastSavedTime!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );

    return KeyboardShortcuts(
      onSave: _saveData,
      onExcelExport: _downloadExcel,
      onClearData: _clearAllData,
      onStartStopwatch: _toggleStopwatch,
      onStopStopwatch: _stopStopwatch,
      onResetStopwatch: _resetStopwatch,
      onRecordTime: _fillSelectedCellWithTime,
      child: Scaffold(
        // キーボード表示時に自動でレイアウト調整
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('測定データ'),
          actions: [
            // 保存ボタン
            if (_hasUnsavedChanges)
              IconButton(
                onPressed: _saveData,
                icon: const Icon(Icons.save),
                tooltip: '保存 (Ctrl+S)',
              ),
            // Excel出力ボタン
            ElevatedButton.icon(
              onPressed: _downloadExcel,
              icon: const Icon(Icons.file_download),
              label: const Text('Excel出力'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                elevation: 0,
              ),
            ),
            // ヘルプボタン
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ShortcutsHelpDialog(),
                );
              },
              icon: const Icon(Icons.help_outline),
              tooltip: 'ショートカットヘルプ',
            ),
            // メニューボタン
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'clear':
                    _clearAllData();
                    break;
                  case 'save':
                    _saveData();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text('手動保存'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text('データクリア', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        drawer: infoDrawer,
        body: Column(
          children: [
            Expanded(child: _buildMeasurementTableViewWidget()),
            // TODO: dev-only - ミニHUD（後で削除）
            Builder(
              builder: (context) {
                final app = context.watch<AppState>();
                final s = app.currentSession;
                final total = s.totalElapsed?.inSeconds ?? 0;
                final work  = s.totalWork.inSeconds;
                final pause = s.totalPause.inSeconds;
                return Container(
                  color: const Color(0x22FF0000), // dev-only HUD
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '⏱ work:${work}s  pause:${pause}s  total:${total}s  '
                    'running:${s.isRunning} paused:${s.isPaused}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
