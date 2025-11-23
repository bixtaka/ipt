import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ipt/factory_db/factory_database.dart';
import 'package:ipt/state/app_state.dart';

class InfoForm extends StatefulWidget {
  final List<String> infoLabels;
  final List<TextEditingController> controllers;
  final void Function(int index) onChanged;

  const InfoForm({
    super.key,
    required this.infoLabels,
    required this.controllers,
    required this.onChanged,
  });

  @override
  State<InfoForm> createState() => _InfoFormState();
}

class _InfoFormState extends State<InfoForm> {
  int? _selectedProjectId;
  int? _selectedProductId;
  bool _initialized = false;

  int get _projectFieldIndex => widget.infoLabels.indexOf('工事名');
  int get _productFieldIndex => widget.infoLabels.indexOf('製品符号');

  bool _isProjectField(int index) {
    return widget.infoLabels[index] == '工事名';
  }

  bool _isProductField(int index) {
    return widget.infoLabels[index] == '製品符号';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final settings = context.read<AppState>().settings;
    _selectedProjectId = settings.projectId;
    _selectedProductId = settings.productId;
    _initialized = true;
    _hydrateIdsFromExistingText();
  }

  void _hydrateIdsFromExistingText() {
    Future.microtask(() async {
      await _resolveProjectIdFromExistingText();
      await _resolveProductIdFromExistingText();
    });
  }

  Future<void> _resolveProjectIdFromExistingText() async {
    if (_selectedProjectId != null) return;
    final index = _projectFieldIndex;
    if (index == -1) return;
    final projectName = widget.controllers[index].text.trim();
    if (projectName.isEmpty) return;
    try {
      final projects = await FactoryDatabase.instance.getProjects();
      for (final project in projects) {
        final name = project['name']?.toString() ?? '';
        if (name == projectName) {
          final id = project['id'] as int?;
          if (id != null) {
            if (!mounted) return;
            setState(() {
              _selectedProjectId = id;
            });
            context.read<AppState>().setProjectId(id);
          }
          break;
        }
      }
    } catch (_) {
      // 既存データに ID が無い場合はそのまま null を維持
    }
  }

  Future<void> _resolveProductIdFromExistingText() async {
    if (_selectedProductId != null) return;
    final projectId = _selectedProjectId;
    if (projectId == null) return;
    final index = _productFieldIndex;
    if (index == -1) return;
    final productCode = widget.controllers[index].text.trim();
    if (productCode.isEmpty) return;
    try {
      final products =
          await FactoryDatabase.instance.getProductsByProject(projectId);
      for (final product in products) {
        final code = product['product_code']?.toString() ?? '';
        if (code == productCode) {
          final id = product['id'] as int?;
          if (id != null) {
            if (!mounted) return;
            setState(() {
              _selectedProductId = id;
            });
            context.read<AppState>().setProductId(id);
          }
          break;
        }
      }
    } catch (_) {
      // 後方互換用なので失敗しても致命ではない
    }
  }

  Future<void> _openProjectDialog(int index) async {
    try {
      final projects = await FactoryDatabase.instance.getProjects();
      if (!mounted) return;

      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('工事名を選択'),
            children: projects.isEmpty
                ? <Widget>[
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('projects テーブルにデータがありません。'),
                    ),
                  ]
                : projects.map((project) {
                    final name = project['name']?.toString() ?? '';
                    return SimpleDialogOption(
                      onPressed: () => Navigator.of(context).pop(project),
                      child: Text(name),
                    );
                  }).toList(),
          );
        },
      );

      if (selected != null) {
        final app = context.read<AppState>();
        setState(() {
          _selectedProjectId = selected['id'] as int?;
          widget.controllers[index].text =
              selected['name']?.toString() ?? '';
          _clearProductSelection(app, notifyParent: false);
        });
        app.setProjectName(widget.controllers[index].text);
        app.setProjectId(_selectedProjectId);
        widget.onChanged(index);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('工事名の取得に失敗しました: $e')),
      );
    }
  }

  Future<void> _openProductDialog(int index) async {
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先に工事名を選択してください。')),
      );
      return;
    }

    try {
      final products = await FactoryDatabase.instance
          .getProductsByProject(_selectedProjectId!);
      if (!mounted) return;

      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('製品符号を選択'),
            children: products.isEmpty
                ? <Widget>[
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('選択された工事に対応する製品がありません。'),
                    ),
                  ]
                : products.map((product) {
                    final code = product['product_code']?.toString() ?? '';
                    return SimpleDialogOption(
                      onPressed: () => Navigator.of(context).pop(product),
                      child: Text(code),
                    );
                  }).toList(),
          );
        },
      );

      if (selected != null) {
        final app = context.read<AppState>();
        setState(() {
          _selectedProductId = selected['id'] as int?;
          widget.controllers[index].text =
              selected['product_code']?.toString() ?? '';
        });
        app.setProductCode(widget.controllers[index].text);
        app.setProductId(_selectedProductId);
        widget.onChanged(index);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('製品符号の取得に失敗しました: $e')),
      );
    }
  }

  void _clearProductSelection(AppState app, {bool notifyParent = true}) {
    _selectedProductId = null;
    final productIndex = _productFieldIndex;
    if (productIndex != -1) {
      widget.controllers[productIndex].clear();
      if (notifyParent) {
        widget.onChanged(productIndex);
      }
    }
    app.setProductCode(null);
    app.setProductId(null);
  }

  void _onSearchPressed(int index) {
    if (_isProjectField(index)) {
      _openProjectDialog(index);
    } else if (_isProductField(index)) {
      _openProductDialog(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: List.generate(widget.infoLabels.length, (index) {
        final isProject = _isProjectField(index);
        final isProduct = _isProductField(index);
        final showSearchButton = isProject || isProduct;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  widget.infoLabels[index],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.controllers[index],
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        ),
                        onChanged: (value) {
                          final app = context.read<AppState>();
                          if (isProject) {
                            setState(() {
                              _selectedProjectId = null;
                              _clearProductSelection(app,
                                  notifyParent: false);
                            });
                            app.setProjectId(null);
                          } else if (isProduct) {
                            setState(() {
                              _selectedProductId = null;
                            });
                            app.setProductId(null);
                          }
                          widget.onChanged(index);
                        },
                      ),
                    ),
                    if (showSearchButton)
                      IconButton(
                        icon: const Icon(Icons.search),
                        tooltip: isProject ? '工事名を検索' : '製品符号を検索',
                        onPressed: () => _onSearchPressed(index),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
