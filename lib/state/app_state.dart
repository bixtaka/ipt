// lib/state/app_state.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert' show LineSplitter;

import '../models/job_settings.dart';
import '../models/pass_record.dart';
import '../models/stopwatch_session.dart';
import '../models/measurement_record.dart';

/// Central application state: settings, passes, and stopwatch sessions.
class AppState extends ChangeNotifier {
  // ----- Settings -----
  JobSettings _settings = JobSettings();
  String _defaultPassLayer = '1';
  JobSettings get settings => _settings;

  // ----- Pass table -----
  final List<PassRecord> _passes = List.generate(
    10,
    (i) => PassRecord(index: i + 1, passLayer: '1'),
  );
  List<PassRecord> get passes => List.unmodifiable(_passes);

  int _currentPassIndex = 0; // 0-based
  int get currentPassIndex => _currentPassIndex;

  // When loading a record from history, remember its id for potential update
  String? loadedRecordId;

  void setCurrentPassIndex(int index) {
    if (index < 0) return;
    // Auto-grow by one when stepping beyond the tail
    if (index >= _passes.length) {
      ensurePassCount(index + 1);
    }
    _currentPassIndex = index;
    notifyListeners();
  }

  void ensurePassCount(int count) {
    if (count <= _passes.length) return;
    final start = _passes.length;
    for (int i = start; i < count; i++) {
      _passes.add(PassRecord(index: i + 1, passLayer: _defaultPassLayer));
      _passSessions.add(WeldingSession.empty());
    }
    notifyListeners();
  }

  // ----- Per-pass sessions + global session -----
  final List<WeldingSession> _passSessions =
      List.generate(10, (_) => WeldingSession.empty());

  WeldingSession _globalSession = WeldingSession.empty();

  // Which pass is actively being measured (if any)
  int? measuringPassIndex;

  WeldingSession get currentSession {
    if (_currentPassIndex < 0 || _currentPassIndex >= _passSessions.length) {
      return WeldingSession.empty();
    }
    return _passSessions[_currentPassIndex];
  }

  bool get isMeasuring => _globalSession.isRunning;
  bool get isMeasuringPaused => _globalSession.isPaused;

  DateTime? get globalStartTime => _globalSession.startTime;
  DateTime? get globalEndTime => _globalSession.endTime;

  /// Effective global elapsed "work" time at [now].
  Duration globalElapsedAt(DateTime now) {
    // Sum of closed work segments + open work segment up to now.
    Duration base = _globalSession.totalWork;
    if (_globalSession.isRunning && _globalSession.works.isNotEmpty) {
      final last = _globalSession.works.last;
      if (last.end == null && now.isAfter(last.start)) {
        base += now.difference(last.start);
      }
    }
    return base;
  }

  // ----- Stopwatch controls -----
  void startStopwatch() {
    final now = DateTime.now();
    // Start global session if not already running/paused
    if (_globalSession.startTime == null || _globalSession.endTime != null) {
      _globalSession = _globalSession.start(now);
    }
    // Start or resume current pass session
    final idx = _currentPassIndex;
    _ensureSessionSizeForIndex(idx);
    var s = _passSessions[idx];
    if (s.startTime == null) {
      s = s.start(now);
    } else if (s.isPaused) {
      s = s.resume(now);
    } else if (!s.isRunning) {
      // Ended previously; start a new one
      s = WeldingSession.empty().start(now);
    }
    _passSessions[idx] = s;
    measuringPassIndex = idx;
    _reflectSessionToPassAt(idx, s);
    notifyListeners();
  }

  void pauseStopwatch() {
    final now = DateTime.now();
    final idx = _currentPassIndex;
    _ensureSessionSizeForIndex(idx);
    var s = _passSessions[idx];
    if (s.isRunning) {
      s = s.pause(now);
      _passSessions[idx] = s;
      measuringPassIndex = idx;
      _reflectSessionToPassAt(idx, s);
      // Note: global session keeps running per requirement
      notifyListeners();
    }
  }

  void resumeStopwatch() {
    // Resume should start measuring on the NEXT pass.
    final now = DateTime.now();
    final activeIdx = measuringPassIndex ?? _currentPassIndex;
    // Close open pause on the previous pass at resume timing
    _ensureSessionSizeForIndex(activeIdx);
    final prevClosed = _passSessions[activeIdx].closeOpenEdges(now);
    _passSessions[activeIdx] = prevClosed;
    _reflectSessionToPassAt(activeIdx, prevClosed);

    final nextIdx = activeIdx + 1;
    ensurePassCount(nextIdx + 1);
    _currentPassIndex = nextIdx;

    _ensureSessionSizeForIndex(nextIdx);
    var nextSession = _passSessions[nextIdx];
    if (nextSession.startTime == null) {
      nextSession = nextSession.start(now);
    } else if (nextSession.isPaused) {
      nextSession = nextSession.resume(now);
    } else if (!nextSession.isRunning) {
      nextSession = WeldingSession.empty().start(now);
    }
    _passSessions[nextIdx] = nextSession;
    measuringPassIndex = nextIdx;
    _reflectSessionToPassAt(nextIdx, nextSession);
    notifyListeners();
  }

  void stopStopwatch() {
    final now = DateTime.now();
    final idx = _currentPassIndex;
    _ensureSessionSizeForIndex(idx);
    var s = _passSessions[idx];
    if (s.startTime != null && s.endTime == null) {
      s = s.stop(now);
      _passSessions[idx] = s;
      _reflectSessionToPassAt(idx, s);
      measuringPassIndex = null;
      // Global session continues per requirement (do not stop here)
      notifyListeners();
    }
  }

  /// Stop the active measuring session globally (measurement end).
  void stopActiveStopwatch() {
    final now = DateTime.now();
    // Stop currently measuring pass if any
    final mIdx = measuringPassIndex;
    if (mIdx != null && mIdx >= 0 && mIdx < _passSessions.length) {
      var s = _passSessions[mIdx];
      if (s.startTime != null && s.endTime == null) {
        s = s.stop(now);
        _passSessions[mIdx] = s;
        _reflectSessionToPassAt(mIdx, s);
      }
    }
    measuringPassIndex = null;

    // Stop global session
    if (_globalSession.startTime != null && _globalSession.endTime == null) {
      _globalSession = _globalSession.stop(now);
    }
    notifyListeners();
  }

  void resetStopwatch() {
    // Reset all sessions and clear per-pass values to initial state
    measuringPassIndex = null;
    _globalSession = WeldingSession.empty();
    _defaultPassLayer = '1';
    _currentPassIndex = 0; // Start from Pass 1 after reset
    for (int i = 0; i < _passSessions.length; i++) {
      _passSessions[i] = WeldingSession.empty();
    }
    for (int i = 0; i < _passes.length; i++) {
      _passes[i] = PassRecord(index: i + 1, passLayer: _defaultPassLayer);
    }
    notifyListeners();
    // Load test data asynchronously for testing
    _loadTestDataFromAssets();
    // Reset loaded id when starting fresh
    loadedRecordId = null;
  }

  // ----- Test data loader (assets/data/testdata.csv) -----
  void _loadTestDataFromAssets() async {
    try {
      final csv = await rootBundle.loadString('data/testdata.csv');
      if (csv.trim().isEmpty) return;
      final lines = const LineSplitter().convert(csv);
      if (lines.isEmpty) return;

      int row = 0;
      for (int i = 1; i < lines.length; i++) {
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
        final passLayerCsv = (cols.length > 5 ? cols[5].trim() : null);

        ensurePassCount(row + 1);
        var p = _passes[row];
        p = p.copyWith(tStart: tStart, tEnd: tEnd, amps: amps, volts: volts,
          passLayer: (passLayerCsv == null || passLayerCsv.isEmpty) ? p.passLayer : passLayerCsv);
        _passes[row] = p;

        row++;
      }
      notifyListeners();
    } catch (_) {
      // ignore in test mode
    }
  }

  void resumeActiveStopwatch() {
    final idx = measuringPassIndex ?? _currentPassIndex;
    if (idx < 0) return;
    final now = DateTime.now();
    _ensureSessionSizeForIndex(idx);
    var s = _passSessions[idx];
    if (s.startTime == null) {
      s = s.start(now);
    } else if (s.isPaused) {
      s = s.resume(now);
    }
    _passSessions[idx] = s;
    measuringPassIndex = idx;
    _reflectSessionToPassAt(idx, s);
    notifyListeners();
  }

  void pauseActiveStopwatch() {
    final idx = measuringPassIndex ?? _currentPassIndex;
    if (idx < 0) return;
    final now = DateTime.now();
    _ensureSessionSizeForIndex(idx);
    var s = _passSessions[idx];
    if (s.isRunning) {
      s = s.pause(now);
      _passSessions[idx] = s;
      _reflectSessionToPassAt(idx, s);
      notifyListeners();
    }
  }

  void recordLap() {
    final idx = measuringPassIndex ?? _currentPassIndex;
    if (idx < 0 || idx >= _passSessions.length) return;
    var s = _passSessions[idx];
    s = s.record(DateTime.now());
    _passSessions[idx] = s;
    notifyListeners();
  }

  void _ensureSessionSizeForIndex(int index) {
    if (index < _passSessions.length) return;
    final toAdd = index + 1 - _passSessions.length;
    for (int i = 0; i < toAdd; i++) {
      _passSessions.add(WeldingSession.empty());
    }
  }

  // ----- Reflect session metrics into pass rows -----
  void _reflectSessionToPass(WeldingSession s) {
    _reflectSessionToPassAt(_currentPassIndex, s);
  }

  void _reflectSessionToPassAt(int idx, WeldingSession s) {
    if (idx < 0 || idx >= _passes.length) return;
    final now = DateTime.now();

    // Work (welding) duration up to now
    Duration weld = s.totalWork;
    if (s.isRunning && s.works.isNotEmpty && s.works.last.end == null) {
      weld += now.difference(s.works.last.start);
    }

    // Pause duration up to now
    Duration pause = s.totalPause;
    if (s.isPaused && s.pauses.isNotEmpty && s.pauses.last.end == null) {
      pause += now.difference(s.pauses.last.start);
    }

    // Total elapsed = (end or now) - start
    double totalSec = 0;
    if (s.startTime != null) {
      final end = s.endTime ?? now;
      totalSec = end.difference(s.startTime!).inMilliseconds / 1000.0;
    }

    final weldSec = weld.inMilliseconds / 1000.0;
    final pauseSec = pause.inMilliseconds / 1000.0;

    // Update pass with derived values
    final old = _passes[idx];
    _passes[idx] = old.copyWith(
      weldTimeSec: weldSec > 0 ? weldSec : null,
      pauseSec: pauseSec > 0 ? pauseSec : null,
      totalSec: totalSec > 0 ? totalSec : null,
    );

    _recomputeSpeedAndHeatFor(idx);
  }

  void _recomputeSpeedAndHeatFor(int idx) {
    if (idx < 0 || idx >= _passes.length) return;
    final p = _passes[idx];
    final lengthCm = _settings.weldingLengthCm;
    double? speed; // cm/min
    if (lengthCm != null && p.weldTimeSec != null && p.weldTimeSec! > 0) {
      speed = lengthCm * 60.0 / p.weldTimeSec!;
    }
    double? heat;
    if (p.amps != null && p.volts != null && speed != null && speed > 0) {
      // kJ/cm = (I[A] * V[V] * 60) / (speed[cm/min] * 1000)
      heat = (p.amps! * p.volts! * 60) / (speed * 1000);
    }
    _passes[idx] = p.copyWith(
      speed: speed,
      heatInput: heat,
    );
  }

  // ----- Pass value setters -----
  void setPassRecord(int idx, PassRecord record) {
    if (idx < 0) return;
    ensurePassCount(idx + 1);
    _passes[idx] = record;
    _recomputeSpeedAndHeatFor(idx);
    notifyListeners();
  }

  void setPassTStart(int idx, int? value) {
    if (idx < 0) return;
    ensurePassCount(idx + 1);
    _passes[idx] = _passes[idx].copyWith(tStart: value);
    notifyListeners();
  }

  void setPassTEnd(int idx, int? value) {
    if (idx < 0) return;
    ensurePassCount(idx + 1);
    _passes[idx] = _passes[idx].copyWith(tEnd: value);
    notifyListeners();
  }

  void setPassAmps(int idx, int? value) {
    if (idx < 0) return;
    ensurePassCount(idx + 1);
    _passes[idx] = _passes[idx].copyWith(amps: value);
    _recomputeSpeedAndHeatFor(idx);
    notifyListeners();
  }

  void setPassVolts(int idx, int? value) {
    if (idx < 0) return;
    ensurePassCount(idx + 1);
    _passes[idx] = _passes[idx].copyWith(volts: value);
    _recomputeSpeedAndHeatFor(idx);
    notifyListeners();
  }

  void setPassNote(int idx, String? note) {
    if (idx < 0) return;
    ensurePassCount(idx + 1);
    _passes[idx] = _passes[idx].copyWith(note: note);
    notifyListeners();
  }

  void setPassLayer(int idx, String? v) {
    if (idx < 0) return;
    ensurePassCount(idx + 1);
    _passes[idx] = _passes[idx].copyWith(passLayer: v);
    // Update default to the latest entered non-empty value, and propagate to
    // subsequent passes where the value is still at the previous default or empty.
    if (v != null && v.trim().isNotEmpty) {
      final prevDefault = _defaultPassLayer;
      final newDefault = v.trim();
      _defaultPassLayer = newDefault;
      for (int i = idx + 1; i < _passes.length; i++) {
        final existing = _passes[i].passLayer;
        if (existing == null || existing.isEmpty || existing == prevDefault) {
          _passes[i] = _passes[i].copyWith(passLayer: newDefault);
        }
      }
    }
    notifyListeners();
  }

  void setPassSlag(int idx, String? v) {
    if (idx < 0) return;
    ensurePassCount(idx + 1);
    _passes[idx] = _passes[idx].copyWith(slag: v);
    notifyListeners();
  }

  // Optionally allow writing derived values from other components
  void setPassDerived(int idx, {double? speed, double? heatInput}) {
    if (idx < 0) return;
    ensurePassCount(idx + 1);
    _passes[idx] = _passes[idx].copyWith(speed: speed, heatInput: heatInput);
    notifyListeners();
  }

  // ----- Settings setters -----
  void setProjectName(String? v) {
    _settings = _settings.copyWith(projectName: v);
    notifyListeners();
  }

  void setMeasurementDate(DateTime v) {
    _settings = _settings.copyWith(measurementDate: v);
    notifyListeners();
  }

  void setWeldingLengthCm(double? v) {
    _settings = _settings.copyWith(weldingLengthCm: v);
    // Recompute speed/heat for all rows when length changes
    for (int i = 0; i < _passes.length; i++) {
      _recomputeSpeedAndHeatFor(i);
    }
    notifyListeners();
  }

  void setProductCode(String? v) {
    _settings = _settings.copyWith(productCode: v);
    notifyListeners();
  }

  void setLocation(String? v) {
    _settings = _settings.copyWith(location: v);
    notifyListeners();
  }

  void setComponent(String? v) {
    // Map to JobSettings.part
    _settings = _settings.copyWith(part: v);
    notifyListeners();
  }

  void setMaterial(String? v) {
    _settings = _settings.copyWith(material: v);
    notifyListeners();
  }

  void setGrooveAngle(String? v) {
    _settings = _settings.copyWith(grooveAngle: v);
    notifyListeners();
  }

  void setRootGap(String? v) {
    _settings = _settings.copyWith(rootGap: v);
    notifyListeners();
  }

  void setWeldingPosition(String? v) {
    // Map to JobSettings.posture
    _settings = _settings.copyWith(posture: v);
    notifyListeners();
  }

  // New: misc conditions
  void setWeather(String? v) {
    _settings = _settings.copyWith(weather: v);
    notifyListeners();
  }

  void setAmbientTempC(double? v) {
    _settings = _settings.copyWith(ambientTempC: v);
    notifyListeners();
  }

  void setHumidityPercent(double? v) {
    _settings = _settings.copyWith(humidityPercent: v);
    notifyListeners();
  }

  // ----- Autosave debounce (no-op storage hook) -----
  Timer? _saveDebounce;
  void scheduleAutosave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 1), () {
      // Hook for persistence layer if needed.
      // Currently just notify to reflect any pending UI state.
      notifyListeners();
    });
  }

  // ----- Periodic ticker to refresh time-dependent UI -----
  Timer? _ticker;
  AppState() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      // Refresh active sessions' derived values so UI reflects weld/stop time live.
      for (int i = 0; i < _passSessions.length; i++) {
        final s = _passSessions[i];
        if (s.startTime != null && s.endTime == null) {
          _reflectSessionToPassAt(i, s);
        }
      }
      // Also notify to refresh any time-based displays (e.g., global stopwatch HUD)
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _saveDebounce?.cancel();
    super.dispose();
  }

  // ----- Record I/O helpers -----
  MeasurementRecord toRecord() {
    return MeasurementRecord.newRecord(
      settings: _settings,
      passes: List<PassRecord>.from(_passes),
    );
  }

  void loadFromRecord(MeasurementRecord record) {
    // Reset sessions/state and load settings/passes from the record
    measuringPassIndex = null;
    _globalSession = WeldingSession.empty();
    _currentPassIndex = 0;

    _settings = record.settings;

    // Remember the source id for potential update-save
    loadedRecordId = record.id;

    // Replace passes list contents
    _passes
      ..clear()
      ..addAll(record.passes.map((p) => p.copyWith()));

    // Resize sessions to match passes
    _passSessions
      ..clear()
      ..addAll(List<WeldingSession>.generate(_passes.length, (_) => WeldingSession.empty()));

    notifyListeners();
  }
}

