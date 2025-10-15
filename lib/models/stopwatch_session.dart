import 'package:flutter/foundation.dart';

@immutable
class StopwatchEvent {
  final DateTime at;
  final String type; // 'start' | 'pause' | 'resume' | 'stop' | 'record'
  final String? note;
  const StopwatchEvent({required this.at, required this.type, this.note});

  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'type': type,
    'note': note,
  };

  factory StopwatchEvent.fromJson(Map<String, dynamic> j) =>
      StopwatchEvent(
        at: DateTime.parse(j['at'] as String),
        type: j['type'] as String,
        note: j['note'] as String?,
      );
}

class PausePeriod {
  final DateTime start;
  final DateTime? end;
  const PausePeriod({required this.start, this.end});

  Duration get duration => end == null ? Duration.zero : end!.difference(start);

  PausePeriod close(DateTime endTime) => PausePeriod(start: start, end: endTime);

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end?.toIso8601String(),
  };

  factory PausePeriod.fromJson(Map<String, dynamic> j) =>
      PausePeriod(
        start: DateTime.parse(j['start'] as String),
        end: j['end'] != null ? DateTime.parse(j['end'] as String) : null,
      );
}

class WorkSegment {
  final DateTime start;
  final DateTime? end;
  const WorkSegment({required this.start, this.end});

  Duration get duration => end == null ? Duration.zero : end!.difference(start);

  WorkSegment close(DateTime endTime) => WorkSegment(start: start, end: endTime);

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end?.toIso8601String(),
  };

  factory WorkSegment.fromJson(Map<String, dynamic> j) =>
      WorkSegment(
        start: DateTime.parse(j['start'] as String),
        end: j['end'] != null ? DateTime.parse(j['end'] as String) : null,
      );
}

/// 1パス分の計測セッション
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

  bool get isRunning =>
      startTime != null && endTime == null &&
      (pauses.isEmpty || pauses.last.end != null);

  bool get isPaused =>
      startTime != null && endTime == null &&
      pauses.isNotEmpty && pauses.last.end == null;

  Duration get totalWork =>
      works.fold(Duration.zero, (a, s) => a + s.duration);

  Duration get totalPause =>
      pauses.fold(Duration.zero, (a, p) => a + p.duration);

  Duration? get totalElapsed =>
      (startTime == null || endTime == null) ? null : endTime!.difference(startTime!);

  // ---- immutable updates ----
  WeldingSession addEvent(StopwatchEvent e) =>
      WeldingSession(
        startTime: startTime,
        endTime: endTime,
        events: [...events, e],
        pauses: pauses,
        works: works,
      );

  WeldingSession start(DateTime t) =>
      WeldingSession(
        startTime: t,
        endTime: null,
        events: [...events, StopwatchEvent(at: t, type: 'start')],
        pauses: pauses,
        works: [...works, WorkSegment(start: t)],
      );

  WeldingSession pause(DateTime t) {
    final newPauses = [...pauses, PausePeriod(start: t)];
    final newWorks = works.isNotEmpty && works.last.end == null
        ? [...works..last = works.last.close(t)]
        : works;
    return WeldingSession(
      startTime: startTime,
      endTime: null,
      events: [...events, StopwatchEvent(at: t, type: 'pause')],
      pauses: newPauses,
      works: newWorks,
    );
  }

  WeldingSession resume(DateTime t) {
    final newPauses = pauses.isNotEmpty && pauses.last.end == null
        ? [...pauses..last = pauses.last.close(t)]
        : pauses;
    return WeldingSession(
      startTime: startTime,
      endTime: null,
      events: [...events, StopwatchEvent(at: t, type: 'resume')],
      pauses: newPauses,
      works: [...works, WorkSegment(start: t)],
    );
  }

  WeldingSession stop(DateTime t) {
    final closedPauses = pauses.isNotEmpty && pauses.last.end == null
        ? [...pauses..last = pauses.last.close(t)]
        : pauses;
    final closedWorks = works.isNotEmpty && works.last.end == null
        ? [...works..last = works.last.close(t)]
        : works;
    return WeldingSession(
      startTime: startTime,
      endTime: t,
      events: [...events, StopwatchEvent(at: t, type: 'stop')],
      pauses: closedPauses,
      works: closedWorks,
    );
  }

  Map<String, dynamic> toJson() => {
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'events': events.map((e) => e.toJson()).toList(),
    'pauses': pauses.map((p) => p.toJson()).toList(),
    'works': works.map((w) => w.toJson()).toList(),
  };

  factory WeldingSession.fromJson(Map<String, dynamic> j) => WeldingSession(
    startTime: j['startTime'] != null ? DateTime.parse(j['startTime'] as String) : null,
    endTime: j['endTime'] != null ? DateTime.parse(j['endTime'] as String) : null,
    events: (j['events'] as List<dynamic>? ?? []).map((e) => StopwatchEvent.fromJson(e as Map<String, dynamic>)).toList(),
    pauses: (j['pauses'] as List<dynamic>? ?? []).map((e) => PausePeriod.fromJson(e as Map<String, dynamic>)).toList(),
    works: (j['works'] as List<dynamic>? ?? []).map((e) => WorkSegment.fromJson(e as Map<String, dynamic>)).toList(),
  );
}