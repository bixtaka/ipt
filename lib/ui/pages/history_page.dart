import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/measurement_record.dart';
import '../../services/measurement_repository.dart';
import '../../state/app_state.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _repo = MeasurementRepository();
  final _searchController = TextEditingController();
  RecordSortField _sortField = RecordSortField.date;
  bool _ascending = false;
  Future<List<MeasurementRecord>>? _future;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = _repo.search(
        query: _searchController.text,
        sortField: _sortField,
        ascending: _ascending,
      );
    });
  }

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('測定履歴'),
        actions: [
          IconButton(
            tooltip: '並べ替え: 日付',
            icon: Icon(
              Icons.calendar_month,
              color: _sortField == RecordSortField.date ? Colors.blue : null,
            ),
            onPressed: () {
              setState(() {
                if (_sortField == RecordSortField.date) {
                  _ascending = !_ascending;
                } else {
                  _sortField = RecordSortField.date;
                }
              });
              _refresh();
            },
          ),
          IconButton(
            tooltip: '並べ替え: 工事名',
            icon: Icon(
              Icons.sort_by_alpha,
              color: _sortField == RecordSortField.projectName ? Colors.blue : null,
            ),
            onPressed: () {
              setState(() {
                if (_sortField == RecordSortField.projectName) {
                  _ascending = !_ascending;
                } else {
                  _sortField = RecordSortField.projectName;
                }
              });
              _refresh();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _refresh(),
              decoration: InputDecoration(
                hintText: '検索 (工事名・製品符号・位置)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _refresh();
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<MeasurementRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data!;
          if (records.isEmpty) {
            return const Center(child: Text('保存済みデータはありません'));
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              itemCount: records.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final r = records[index];
                final s = r.settings;
                final title = s.projectName?.isNotEmpty == true
                    ? s.projectName!
                    : '(工事名なし)';
                final subtitle = '${_fmtDate(s.measurementDate)}  •  '
                    '${s.productCode ?? ''}  ${s.location ?? ''}'.trim();
                return ListTile(
                  title: Text(title),
                  subtitle: Text(subtitle),
                  leading: const Icon(Icons.assignment),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      switch (v) {
                        case 'open':
                          if (!mounted) return;
                          context.read<AppState>().loadFromRecord(r);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('読み込みました')),
                          );
                          break;
                        case 'delete':
                          await _repo.delete(r.id);
                          if (mounted) _refresh();
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'open', child: Text('開く')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('削除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  onTap: () async {
                    context.read<AppState>().loadFromRecord(r);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('読み込みました')),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
