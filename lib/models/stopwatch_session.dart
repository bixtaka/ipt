// lib/models/stopwatch_session.dart
import 'package:flutter/foundation.dart';

/// 操作種別
enum StopwatchEventType { start, pause, resume, stop, record }

String _eventTypeToString(StopwatchEventType t) => t.name;
StopwatchEventType _eventTypeFromString(String s) =>
    StopwatchEventType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => StopwatchEventType.record,
    );

@immutable
class StopwatchEvent {
  final DateTime at;
  final StopwatchEventType type;
  final String? note;

  const StopwatchEvent({
    required this.at,
    required this.type,
    this.note,
  });

  StopwatchEvent copyWith({
    DateTime? at,
    StopwatchEventType? type,
    String? note,
  }) =>
      StopwatchEvent(
        at: at ?? this.at,
        type: type ?? this.type,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'type': _eventTypeToString(type),
        'note': note,
      };

  factory StopwatchEvent.fromJson(Map<String, dynamic> j) => StopwatchEvent(
        at: DateTime.parse(j['at'] as String),
        type: _eventTypeFromString(j['type'] as String),
        note: j['note'] as String?,
      );

  @override
  String toString() => 'StopwatchEvent(${type.name} @ ${at.toIso8601String()})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StopwatchEvent &&
          at == other.at &&
          type == other.type &&
          note == other.note;

  @override
  int get hashCode => Object.hash(at, type, note);
}

@immutable
class PausePeriod {
  final DateTime start;
  final DateTime? end;

  const PausePeriod({required this.start, this.end});

  bool get isOpen => end == null;

  Duration get duration => end == null ? Duration.zero : end!.difference(start);

  PausePeriod close(DateTime endTime) =>
      isOpen ? PausePeriod(start: start, end: endTime) : this;

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
      };

  factory PausePeriod.fromJson(Map<String, dynamic> j) => PausePeriod(
        start: DateTime.parse(j['start'] as String),
        end: j['end'] != null ? DateTime.parse(j['end'] as String) : null,
      );

  @override
  String toString() =>
      'Pause(${start.toIso8601String()} .. ${end?.toIso8601String()})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PausePeriod && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

@immutable
class WorkSegment {
  final DateTime start;
  final DateTime? end;

  const WorkSegment({required this.start, this.end});

  bool get isOpen => end == null;

  Duration get duration => end == null ? Duration.zero : end!.difference(start);

  WorkSegment close(DateTime endTime) =>
      isOpen ? WorkSegment(start: start, end: endTime) : this;

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
      };

  factory WorkSegment.fromJson(Map<String, dynamic> j) => WorkSegment(
        start: DateTime.parse(j['start'] as String),
        end: j['end'] != null ? DateTime.parse(j['end'] as String) : null,
      );

  @override
  String toString() =>
      'Work(${start.toIso8601String()} .. ${end?.toIso8601String()})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkSegment && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// 1パス分の計測セッション（不変オブジェクト）
/// - 実作業(works) と 中断(pauses) をセグメントで保持
/// - 合計は getter で都度計算
@immutable
class WeldingSession {
  final DateTime? startTime;
  final DateTime? endTime;
  final List<StopwatchEvent> events;
  final List<PausePeriod> pauses;
  final List<WorkSegment> works;

  const WeldingSession({
    required this.startTime,
    required this.endTime,
    required this.events,
    required this.pauses,
    required this.works,
  });

  factory WeldingSession.empty() => const WeldingSession(
        startTime: null,
        endTime: null,
        events: [],
        pauses: [],
        works: [],
      );

  /// 現在「実行中（走行中）」か
  bool get isRunning =>
      startTime != null &&
      endTime == null &&
      (pauses.isEmpty || !pauses.last.isOpen) &&
      (works.isNotEmpty && works.last.isOpen);

  /// 現在「一時停止中」か
  bool get isPaused =>
      startTime != null &&
      endTime == null &&
      (pauses.isNotEmpty && pauses.last.isOpen) &&
      (works.isNotEmpty && !works.last.isOpen);

  /// 実作業合計
  Duration get totalWork => works.fold(Duration.zero, (a, s) => a + s.duration);

  /// 停止合計
  Duration get totalPause =>
      pauses.fold(Duration.zero, (a, p) => a + p.duration);

  /// セッションの総経過（開始〜終了）。終了前は null
  Duration? get totalElapsed => (startTime == null || endTime == null)
      ? null
      : endTime!.difference(startTime!);

  // ---------- 状態遷移（新インスタンスを返す） ----------

  /// 初回開始。既に開始済みなら no-op で this を返す。
  WeldingSession start(DateTime t, {String? note}) {
    if (startTime != null) return this; // 再スタートしない
    return WeldingSession(
      startTime: t,
      endTime: null,
      events: [
        ...events,
        StopwatchEvent(at: t, type: StopwatchEventType.start, note: note)
      ],
      pauses: pauses,
      works: [...works, WorkSegment(start: t)],
    );
  }

  /// 実行中 ⇒ 一時停止。実行中でない場合は no-op。
  WeldingSession pause(DateTime t, {String? note}) {
    if (!isRunning) return this;
    final newWorks = List<WorkSegment>.from(works);
    newWorks[newWorks.length - 1] = newWorks.last.close(t);
    return WeldingSession(
      startTime: startTime,
      endTime: null,
      events: [
        ...events,
        StopwatchEvent(at: t, type: StopwatchEventType.pause, note: note)
      ],
      pauses: [...pauses, PausePeriod(start: t)],
      works: newWorks,
    );
  }

  /// 一時停止 ⇒ 再開。一時停止でない場合は no-op。
  WeldingSession resume(DateTime t, {String? note}) {
    if (!isPaused) return this;
    final newPauses = List<PausePeriod>.from(pauses);
    newPauses[newPauses.length - 1] = newPauses.last.close(t);
    return WeldingSession(
      startTime: startTime,
      endTime: null,
      events: [
        ...events,
        StopwatchEvent(at: t, type: StopwatchEventType.resume, note: note)
      ],
      pauses: newPauses,
      works: [...works, WorkSegment(start: t)],
    );
  }

  /// 停止（完了）。未開始または既停止なら no-op。
  WeldingSession stop(DateTime t, {String? note}) {
    if (startTime == null || endTime != null) return this;

    // 未クローズ要素をクローズ
    final closedPauses = (pauses.isNotEmpty && pauses.last.isOpen)
        ? (List<PausePeriod>.from(pauses)
          ..[pauses.length - 1] = pauses.last.close(t))
        : pauses;

    final closedWorks = (works.isNotEmpty && works.last.isOpen)
        ? (List<WorkSegment>.from(works)
          ..[works.length - 1] = works.last.close(t))
        : works;

    return WeldingSession(
      startTime: startTime,
      endTime: t,
      events: [
        ...events,
        StopwatchEvent(at: t, type: StopwatchEventType.stop, note: note)
      ],
      pauses: closedPauses,
      works: closedWorks,
    );
  }

  /// 任意のタイムスタンプを操作ログに追加（計算値は変えない）
  WeldingSession record(DateTime t, {String? note}) => WeldingSession(
        startTime: startTime,
        endTime: endTime,
        events: [
          ...events,
          StopwatchEvent(at: t, type: StopwatchEventType.record, note: note)
        ],
        pauses: pauses,
        works: works,
      );

  /// 開いている作業/停止セグメントだけを時刻tでクローズ（セッションは継続）
  WeldingSession closeOpenEdges(DateTime t) {
    final closedPauses = (pauses.isNotEmpty && pauses.last.isOpen)
        ? (List<PausePeriod>.from(pauses)
          ..[pauses.length - 1] = pauses.last.close(t))
        : pauses;

    final closedWorks = (works.isNotEmpty && works.last.isOpen)
        ? (List<WorkSegment>.from(works)
          ..[works.length - 1] = works.last.close(t))
        : works;

    return WeldingSession(
      startTime: startTime,
      endTime: endTime,
      events: events,
      pauses: closedPauses,
      works: closedWorks,
    );
  }

  // ---------- 補助 ----------

  WeldingSession copyWith({
    DateTime? startTime,
    DateTime? endTime,
    List<StopwatchEvent>? events,
    List<PausePeriod>? pauses,
    List<WorkSegment>? works,
  }) =>
      WeldingSession(
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        events: events ?? this.events,
        pauses: pauses ?? this.pauses,
        works: works ?? this.works,
      );

  Map<String, dynamic> toJson() => {
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'events': events.map((e) => e.toJson()).toList(),
        'pauses': pauses.map((p) => p.toJson()).toList(),
        'works': works.map((w) => w.toJson()).toList(),
      };

  factory WeldingSession.fromJson(Map<String, dynamic> j) => WeldingSession(
        startTime: j['startTime'] != null
            ? DateTime.parse(j['startTime'] as String)
            : null,
        endTime: j['endTime'] != null
            ? DateTime.parse(j['endTime'] as String)
            : null,
        events: (j['events'] as List<dynamic>? ?? const [])
            .map((e) => StopwatchEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        pauses: (j['pauses'] as List<dynamic>? ?? const [])
            .map((p) => PausePeriod.fromJson(p as Map<String, dynamic>))
            .toList(),
        works: (j['works'] as List<dynamic>? ?? const [])
            .map((w) => WorkSegment.fromJson(w as Map<String, dynamic>))
            .toList(),
      );

  @override
  String toString() =>
      'WeldingSession(start:$startTime end:$endTime work:${totalWork.inSeconds}s pause:${totalPause.inSeconds}s)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WeldingSession) return false;
    return startTime == other.startTime &&
        endTime == other.endTime &&
        listEquals(events, other.events) &&
        listEquals(pauses, other.pauses) &&
        listEquals(works, other.works);
  }

  @override
  int get hashCode => Object.hash(
        startTime,
        endTime,
        Object.hashAll(events),
        Object.hashAll(pauses),
        Object.hashAll(works),
      );
}

/// 表示用ユーティリティ：
/// 実行中は (now - start) - totalPause、
/// 一時停止/停止中は totalWork を返す。
extension WeldingSessionDisplay on WeldingSession {
  Duration effectiveWorkAt(DateTime now) {
    if (startTime == null) return Duration.zero;
    if (isPaused || endTime != null) return totalWork;

    // running
    final elapsedSinceStart = now.difference(startTime!);
    final paused = totalPause;
    final d = elapsedSinceStart - paused;
    return d.isNegative ? Duration.zero : d;
  }
}
