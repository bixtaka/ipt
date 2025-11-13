import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/measurement_record.dart';

enum RecordSortField { date, projectName }

class MeasurementRepository {
  static const String _recordsKey = 'measurement_records_v1';

  Future<List<MeasurementRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recordsKey);
    if (raw == null || raw.isEmpty) return <MeasurementRecord>[];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list
          .map((e) => MeasurementRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <MeasurementRecord>[];
    }
  }

  Future<void> _saveAll(List<MeasurementRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_recordsKey, raw);
  }

  Future<MeasurementRecord> add(MeasurementRecord record) async {
    final records = await loadAll();
    records.add(record.copyWith(updatedAt: DateTime.now()));
    await _saveAll(records);
    return record;
  }

  Future<void> update(MeasurementRecord record) async {
    final records = await loadAll();
    final idx = records.indexWhere((r) => r.id == record.id);
    if (idx == -1) return;
    records[idx] = record.copyWith(updatedAt: DateTime.now());
    await _saveAll(records);
  }

  Future<void> delete(String id) async {
    final records = await loadAll();
    records.removeWhere((r) => r.id == id);
    await _saveAll(records);
  }

  Future<MeasurementRecord?> findById(String id) async {
    final records = await loadAll();
    return records.cast<MeasurementRecord?>().firstWhere(
          (r) => r!.id == id,
          orElse: () => null,
        );
  }

  Future<List<MeasurementRecord>> search({
    String? query,
    RecordSortField sortField = RecordSortField.date,
    bool ascending = false,
  }) async {
    var records = await loadAll();
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      records = records.where((r) {
        final s = r.settings;
        final name = (s.projectName ?? '').toLowerCase();
        final code = (s.productCode ?? '').toLowerCase();
        final loc = (s.location ?? '').toLowerCase();
        return name.contains(q) || code.contains(q) || loc.contains(q);
      }).toList();
    }

    int cmp<T extends Comparable>(T a, T b) => a.compareTo(b);
    records.sort((a, b) {
      int c = 0;
      switch (sortField) {
        case RecordSortField.date:
          c = cmp(a.settings.measurementDate, b.settings.measurementDate);
          break;
        case RecordSortField.projectName:
          c = cmp(a.settings.projectName ?? '', b.settings.projectName ?? '');
          break;
      }
      return ascending ? c : -c;
    });

    return records;
  }
}

