import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

enum HCategory { HS, HM, HW, HL }

extension HCategoryLabel on HCategory {
  String get label {
    switch (this) {
      case HCategory.HS:
        return 'HS (Small)';
      case HCategory.HM:
        return 'HM (Medium)';
      case HCategory.HW:
        return 'HW (Wide)';
      case HCategory.HL:
        return 'HL (Lightweight)';
    }
  }

  String get key => toString().split('.').last; // e.g., "HS"
}

class SteelSettingTab extends StatefulWidget {
  const SteelSettingTab({super.key, this.onSelected});
  final ValueChanged<String>? onSelected;

  @override
  State<SteelSettingTab> createState() => _SteelSettingTabState();
}

class _SteelSettingTabState extends State<SteelSettingTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  final Map<HCategory, List<String>> _all = {
    for (final c in HCategory.values) c: <String>[],
  };
  final Map<HCategory, List<String>> _filtered = {
    for (final c in HCategory.values) c: <String>[],
  };

  String? _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: HCategory.values.length, vsync: this);
    _loadData();
    _searchCtrl.addListener(_applyFilter);
  }

  Future<void> _loadData() async {
    try {
      final raw = await rootBundle.loadString('assets/h_steel_jis.json');
      final Map<String, dynamic> jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      for (final c in HCategory.values) {
        final list = (jsonMap[c.key] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];
        _all[c] = list;
        _filtered[c] = List<String>.from(list);
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load H-steel list: ' + e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      for (final c in HCategory.values) {
        _filtered[c] = List<String>.from(_all[c]!);
      }
    } else {
      for (final c in HCategory.values) {
        _filtered[c] = _all[c]!
            .where((s) => s.toLowerCase().contains(q.toLowerCase()))
            .toList();
      }
    }
    setState(() {});
  }

  Future<void> _showCustomInputDialog() async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(text: _searchCtrl.text.trim());
    final sizeRegex = RegExp(r'^H-\d+[×x]\d+[×x]\d+(?:\.\d+)?[×x]\d+(?:\.\d+)?$');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Enter Custom Size'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. H-300x100x9.5x12',
                helperText: 'Format: H-HEIGHT x WIDTH x WEB_THK x FLANGE_THK',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Please enter a value';
                if (!sizeRegex.hasMatch(t)) {
                  return 'Invalid format (e.g. H-300x100x9.5x12)';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (formKey.currentState!.validate()) {
                  Navigator.of(ctx).pop(ctrl.text.trim());
                }
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(ctx).pop(ctrl.text.trim());
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      widget.onSelected?.call(result);
      Navigator.of(context).pop<String>(result);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = HCategory.values.map((c) => Tab(text: c.label)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Section Settings - H-Sections'),
        bottom:
            TabBar(controller: _tabController, tabs: tabs, isScrollable: true),
        actions: [
          IconButton(
            tooltip: 'Manual input',
            icon: const Icon(Icons.edit),
            onPressed: _showCustomInputDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          labelText: 'Search size (e.g. 300x100, 13x4)',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (_selected != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Selected: ' + (_selected ?? ''))),
                            TextButton(
                              onPressed: () => setState(() => _selected = null),
                              child: const Text('Clear'),
                            )
                          ],
                        ),
                      ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: HCategory.values.map((c) {
                          final list = _filtered[c]!;
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            itemCount: list.length + 1,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              if (i == list.length) {
                                return ListTile(
                                  title: const Text('Not listed? Enter manually…'),
                                  leading: const Icon(Icons.edit),
                                  onTap: _showCustomInputDialog,
                                );
                              }
                              final size = list[i];
                              final isSelected = size == _selected;
                              return ListTile(
                                title: Text(size),
                                trailing: isSelected
                                    ? const Icon(Icons.radio_button_checked)
                                    : const Icon(Icons.radio_button_off),
                                onTap: () {
                                  setState(() => _selected = size);
                                  widget.onSelected?.call(size);
                                  Navigator.of(context).pop<String>(size);
                                },
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
    );
  }
}