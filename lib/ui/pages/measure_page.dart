import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../state/app_state.dart';
import '../styles.dart';
// import '../widgets/quick_input_bar.dart';
// import '../../widgets/session_hud.dart';
import '../widgets/pass_card.dart';
import '../../models/stopwatch_session.dart'; // 以前の effectiveWorkAt 表示で使用
import '../widgets/measure_pass_controls.dart';
import '../widgets/top_global_controls.dart';

class MeasurePage extends StatefulWidget {
  const MeasurePage({super.key});

  @override
  State<MeasurePage> createState() => _MeasurePageState();
}

class _MeasurePageState extends State<MeasurePage>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  String _displayTime = '00:00';

  @override
  void initState() {
    super.initState();
    // 画面の表示を更新するためのティッカー。1秒ごとに描画を更新する
    _ticker = Ticker(_onTick)..start();
    // 初回のみ：パスが空なら CSV から初期値を読み込む（data/testdata.csv）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCsvPassesIfEmpty();
    });
  }

  void _onTick(Duration elapsed) {
    // セッションの“見かけ時間”：走行中は (now - start) - totalPause、停止/一時停止中は totalWork
    final app = context.read<AppState>();
    // 秒の表示は四捨五入。表示はカレントパスの実作業時間に合わせる
    final ms = app.globalElapsedAt(DateTime.now()).inMilliseconds;
    final secs = (ms / 1000.0).round();
    final mm = (secs ~/ 60).toString().padLeft(2, '0');
    final ss = (secs % 60).toString().padLeft(2, '0');
    if (mounted) {
      setState(() {
        _displayTime = '$mm:$ss';
      });
    }
  }

  void _onPrimaryPressed() {
    final app = context.read<AppState>();
    final s = app.currentSession;
    if (s.startTime == null) {
      app.startStopwatch();
    } else if (s.isRunning) {
      app.pauseStopwatch();
    } else if (s.isPaused) {
      app.resumeStopwatch();
    } else {
      // 停止済みで
    }
  }

  void _onStopPressed() {
    context.read<AppState>().stopStopwatch();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('測定')),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final s = appState.currentSession;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stopwatch panel moved above the start button
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingM),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _displayTime,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const TopGlobalControls(),
              const SizedBox(height: 8),
              // ──────────────── 上部タイマーとセッションに統一────────────────
              if (false) Container(
                padding: const EdgeInsets.all(AppStyles.spacingM),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // セッション時間で表示
                    Text(
                      _displayTime,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacingM),

                    // 操作ボタン（セッションAPIに接続！）
                    /* Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: _onPrimaryPressed,
                            icon: Icon(
                              s.startTime == null
                                  ? Icons.play_arrow // Start
                                  : (s.isRunning
                                      ? Icons.pause // Pause
                                      : Icons.play_arrow), // Resume
                            ),
                            label: Text(
                              s.startTime == null
                                  ? 'Start'
                                  : (s.isRunning ? 'Pause' : 'Resume'),
                            ),
                            style: AppStyles.primaryButtonStyle.copyWith(
                              backgroundColor: MaterialStateProperty.all(
                                s.startTime == null
                                    ? Colors.green
                                    : (s.isRunning
                                        ? Colors.orange
                                        : Colors.green),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacingS),
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: _onStopPressed,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                            style: AppStyles.dangerButtonStyle,
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacingS),
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // 次のパスへ
                              if (appState.currentPassIndex <
                                  appState.passes.length - 1) {
                                appState.setCurrentPassIndex(
                                    appState.currentPassIndex + 1);
                              }
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('NEXT'),
                            style: AppStyles.primaryButtonStyle,
                          ),
                        ),
                      ],
                    ), */
                  ],
                ),
              ),

              // ──────────────── Quick input bar ────────────────
              // const QuickInputBar(), // 一時的に非表示。開始温度/終了温度/電流/電圧/備考
              // ──────────────── （任意）開発用の直接操作ボタン ────────────────
              // 必要なければこのブロックごと削除してOK
              /* Builder(builder: (context) {
                final app = context.read<AppState>();
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppStyles.spacingM),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                          onPressed: app.startStopwatch,
                          child: const Text('Start')),
                      ElevatedButton(
                          onPressed: app.pauseStopwatch,
                          child: const Text('Pause')),
                      ElevatedButton(
                          onPressed: app.resumeStopwatch,
                          child: const Text('Resume')),
                      ElevatedButton(
                          onPressed: app.stopStopwatch,
                          child: const Text('Stop')),
                      ElevatedButton(
                          onPressed: () => app.recordLap(),
                          child: const Text('Record')),
                      ElevatedButton(
                          onPressed: app.resetStopwatch,
                          child: const Text('Reset')),
                    ],
                  ),
                );
              }), */

              const SizedBox(height: 8),

              // ──────────────── Pass card ────────────────
              // 小さな画面で "BOTTOM OVERFLOWED" が出る時は、余白を減らすか
              // PassCard 自体をスクロール可能にする対応を後で入れます（今は一旦このまま）
              const Expanded(child: PassCard()),

              // ──────────────── HUDと開発用の見える化────────────────
              // const SessionHud(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadCsvPassesIfEmpty() async {
    try {
      final app = context.read<AppState>();
      final hasAny = app.passes.any((p) =>
          p.tStart != null || p.tEnd != null || p.amps != null || p.volts != null);
      if (hasAny) return;

      final csv = await rootBundle.loadString('data/testdata.csv');
      if (csv.trim().isEmpty) return;
      final lines = csv.split(RegExp(r"\r?\n"));
      if (lines.isEmpty) return;

      int row = 0;
      for (int i = 1; i < lines.length; i++) { // header skip
        if (row >= app.passes.length) break;
        final raw = lines[i].trim();
        if (raw.isEmpty) continue;
        final cols = raw.split(',');

        int? _toInt(String? s) => s == null ? null : int.tryParse(s.trim());
        int? _toIntFromNum(String? s) {
          if (s == null) return null;
          final t = s.trim();
          final asInt = int.tryParse(t);
          if (asInt != null) return asInt;
          final asDouble = double.tryParse(t);
          return asDouble == null ? null : asDouble.round();
        }

        final tStart = cols.length > 1 ? _toInt(cols[1]) : null;
        final tEnd = cols.length > 2 ? _toInt(cols[2]) : null;
        final amps = cols.length > 3 ? _toInt(cols[3]) : null;
        final volts = cols.length > 4 ? _toIntFromNum(cols[4]) : null;
        final passLayerCsv = cols.length > 5 ? cols[5].trim() : null;

        if (tStart != null) app.setPassTStart(row, tStart);
        if (tEnd != null) app.setPassTEnd(row, tEnd);
        if (amps != null) app.setPassAmps(row, amps);
        if (volts != null) app.setPassVolts(row, volts);
        if (passLayerCsv != null && passLayerCsv.isNotEmpty) {
          app.setPassLayer(row, passLayerCsv);
        }
        row++;
      }
    } catch (_) {}
  }}









