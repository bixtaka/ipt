// lib/state/app_state.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/job_settings.dart';
import '../models/pass_record.dart';
import '../models/stopwatch_session.dart';

/// ---------- Undo 用のメメント（トップレベルに定義！） ----------
class _Memento {
  final JobSettings settings;
  final List<PassRecord> passes;
  final int currentPassIndex;
  _Memento({
    required this.settings,
    required this.passes,
    required this.currentPassIndex,
  });
}

/// ===================================================================
///                         アプリ全体の状態
/// ===================================================================
class AppState extends ChangeNotifier {
  /// 基本状態（final にしない：Undoで代入するため）
  JobSettings settings = JobSettings();

  /// パスは 10 件で初期化。PassRecord.index は 1 始まりで振る
  List<PassRecord> passes = List.generate(10, (i) => PassRecord(index: i + 1));

  /// 現在選択中パスの **0 始まり**インデックス
  int currentPassIndex = 0;

  /// ストップウォッチセッション管理
  final Map<int, WeldingSession> _sessions = {};

  /// 現在のパスに対応するセッション
  WeldingSession get currentSession =>
      _sessions[currentPassIndex] ?? WeldingSession.empty();

  // ---------- 保存インジケータ ----------
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isDirty = false;
  bool get isDirty => _isDirty;

  Timer? _saveDebounce;

  // ---------- セッション管理（内部関数） ----------
  void _saveSession(WeldingSession s) {
    _sessions[currentPassIndex] = s;
    notifyListeners();
  }

  // ---------- 設定の更新（必要に応じて他のsetterも追加） ----------
  void updateSettings(JobSettings newSettings) {
    settings = newSettings;
    notifyListeners();
  }

  // ---------- パスの差し替え ----------
  void setPassRecord(PassRecord rec) {
    // ※ PassRecord.index を 1 始まりにしている場合
    final idx = rec.index - 1;
    // もし 0 始まりを使っているなら ↑ を  final idx = rec.index; に変更
    if (idx >= 0 && idx < passes.length) {
      passes[idx] = rec;
      notifyListeners();
    }
  }

  void setCurrentPass(int zeroBased) {
    if (zeroBased >= 0 && zeroBased < passes.length) {
      currentPassIndex = zeroBased;
      notifyListeners();
    }
  }

  // ---------- 計算（ダミー値；後で本式に差し替え） ----------
  void computeDerivedFor(PassRecord rec) {
    final hasAny = rec.amps != null ||
        rec.volts != null ||
        rec.tStart != null ||
        rec.tEnd != null;

    final updated = rec.copyWith(
      weldTimeSec: hasAny ? 3.0 : null,
      speed: hasAny ? 10.0 : null,
      heatInput: hasAny ? 100.0 : null,
    );

    setPassRecord(updated);
  }

  // ---------- オートセーブ（1秒デバウンス） ----------
  void scheduleAutosave() {
    _isDirty = true;
    _isSaving = true;
    notifyListeners();

    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 1), () {
      // TODO: 実保存処理（ローカル/クラウド）をここに実装
      _isSaving = false;
      _isDirty = false;
      notifyListeners();
    });
  }

  // ---------- Undo（最小実装） ----------
  final List<_Memento> _history = [];

  void pushMemento() {
    _history.add(_Memento(
      settings: settings, // JobSettings は不変想定。可変なら deep copy を
      passes: passes.map((e) => e.copyWith()).toList(),
      currentPassIndex: currentPassIndex,
    ));
  }

  bool undoLastChange() {
    if (_history.isEmpty) return false;
    final m = _history.removeLast();
    settings = m.settings;
    passes = m.passes;
    currentPassIndex = m.currentPassIndex;
    notifyListeners();
    return true;
  }

// ========== SettingsPage 用 ==========
  void setProjectName(String? name) {
    settings = settings.copyWith(projectName: name);
    notifyListeners();
  }

  void setMeasurementDate(DateTime date) {
    settings = settings.copyWith(measurementDate: date);
    notifyListeners();
  }

  void setProductCode(String? code) {
    settings = settings.copyWith(productCode: code);
    notifyListeners();
  }

  void setLocation(String? loc) {
    settings = settings.copyWith(location: loc);
    notifyListeners();
  }

  void setComponent(String? comp) {
    settings = settings.copyWith(part: comp);
    notifyListeners();
  }

  void setMaterial(String? mat) {
    settings = settings.copyWith(material: mat);
    notifyListeners();
  }

  void setGrooveAngle(String? angle) {
    settings = settings.copyWith(grooveAngle: angle);
    notifyListeners();
  }

  void setRootGap(String? gap) {
    settings = settings.copyWith(rootGap: gap);
    notifyListeners();
  }

  void setWeldingPosition(String? pos) {
    settings = settings.copyWith(posture: pos);
    notifyListeners();
  }

// ========== PassRecord 用 ==========
  void setPassTStart(int passIndex, int? value) {
    passes[passIndex] = passes[passIndex].copyWith(tStart: value);
    notifyListeners();
  }

  void setPassTEnd(int passIndex, int? value) {
    passes[passIndex] = passes[passIndex].copyWith(tEnd: value);
    notifyListeners();
  }

  void setPassAmps(int passIndex, int? value) {
    passes[passIndex] = passes[passIndex].copyWith(amps: value);
    notifyListeners();
  }

  void setPassVolts(int passIndex, int? value) {
    passes[passIndex] = passes[passIndex].copyWith(volts: value);
    notifyListeners();
  }

  void setPassNote(int passIndex, String? value) {
    passes[passIndex] = passes[passIndex].copyWith(note: value);
    notifyListeners();
  }

// タブ間連携で使われているメソッド
  void setCurrentPassIndex(int zeroBased) {
    if (zeroBased >= 0 && zeroBased < passes.length) {
      currentPassIndex = zeroBased;
      notifyListeners();
    }
  }

  // ---------- ストップウォッチAPI（UIから呼べる最小セット） ----------
  void startStopwatch() {
    final s = currentSession;
    if (s.startTime != null) return; // 二重開始防止
    _saveSession(s.start(DateTime.now()));
  }

  void pauseStopwatch() {
    final s = currentSession;
    if (!s.isRunning) return;
    _saveSession(s.pause(DateTime.now()));
  }

  void resumeStopwatch() {
    final s = currentSession;
    if (!s.isPaused) return;
    _saveSession(s.resume(DateTime.now()));
  }

  void stopStopwatch() {
    final s = currentSession;
    if (s.startTime == null || s.endTime != null) return;
    final stopped = s.stop(DateTime.now());
    _saveSession(stopped);
    _reflectSessionToPass(stopped);
    
    // TODO: dev-only - デバッグ出力（後で削除）
    debugPrint('[session] work=${stopped.totalWork.inSeconds}s pause=${stopped.totalPause.inSeconds}s total=${stopped.totalElapsed?.inSeconds}');
  }

  void resetStopwatch() {
    _sessions.remove(currentPassIndex);
    notifyListeners();
  }

  void recordLap() {
    _reflectSessionToPass(currentSession);
  }

  // ---------- セッション反映（内部関数） ----------
  void _reflectSessionToPass(WeldingSession s) {
    final idx = currentPassIndex;
    if (idx < 0 || idx >= passes.length) return;

    final workSec = s.totalWork.inMilliseconds / 1000.0;
    final pauseSec = s.totalPause.inMilliseconds / 1000.0;
    final totalSec =
        s.totalElapsed == null ? null : s.totalElapsed!.inMilliseconds / 1000.0;

    final old = passes[idx];
    final updated = old.copyWith(
      weldTimeSec: workSec, // 既存の入熱計算で使用する時間は実作業
      pauseSec: pauseSec,
      totalSec: totalSec,
    );

    passes[idx] = updated;

    // TODO: dev-only - デバッグ出力（後で削除）
    debugPrint('[reflect] pass[$idx] weldTimeSec=${updated.weldTimeSec} pauseSec=${updated.pauseSec} totalSec=${updated.totalSec}');

    // 既存の導出計算がある場合は呼び出し（関数名が異なる場合はスキップしてください）
    try {
      // ignore: avoid_print
      computeDerivedFor(updated);
    } catch (_) {
      // 導出計算が無い/非公開なら無視
    }

    notifyListeners();
  }
}
