// lib/ui/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../factory_db/factory_database.dart';
import '../../state/app_state.dart';
import '../../widgets/date_field.dart';
import '../../widgets/form_section.dart';
import '../../widgets/member_spec_tile.dart';
import '../../widgets/small_dropdown.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  static const _materials = ['SS400', 'SN400B', 'SN490A', 'SN490B'];
  static const _grooveAngles = ['35°', '45°', '60°'];
  static const _rootGaps = ['2mm', '3mm', '4mm', '5mm', '6mm', '7mm', '8mm'];
  static const _postures = ['下向', '横向'];
  static const _weathers = ['晴れ', '曇り', '雨', '雪', '風'];

  late final TextEditingController _projectNameCtl;
  late final TextEditingController _productCodeCtl;
  late final TextEditingController _locationCtl;
  late final TextEditingController _partCtl;
  late final TextEditingController _weldingLengthCtl;
  final TextEditingController _tempCtl = TextEditingController();
  final TextEditingController _humidityCtl = TextEditingController();
  String? _weather;
  int? _selectedProjectId;
  int? _selectedProductId;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().settings;
    _projectNameCtl = TextEditingController(text: s.projectName ?? '');
    _productCodeCtl = TextEditingController(text: s.productCode ?? '');
    _locationCtl = TextEditingController(text: s.location ?? '');
    _partCtl = TextEditingController(text: s.part ?? '');
    _weldingLengthCtl = TextEditingController(
      text: s.weldingLengthCm != null ? s.weldingLengthCm!.toString() : '',
    );
    _tempCtl.text = s.ambientTempC != null ? s.ambientTempC!.toString() : '';
    _humidityCtl.text =
        s.humidityPercent != null ? s.humidityPercent!.toString() : '';
    _weather = s.weather;
    _selectedProjectId = s.projectId;
    _selectedProductId = s.productId;
    Future.microtask(_syncSelectionsFromControllers);
  }

  @override
  void dispose() {
    _projectNameCtl.dispose();
    _productCodeCtl.dispose();
    _locationCtl.dispose();
    _partCtl.dispose();
    _weldingLengthCtl.dispose();
    _tempCtl.dispose();
    _humidityCtl.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    if (_projectNameCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('工事名は必須です')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存しました')),
    );
  }

  Future<void> _syncSelectionsFromControllers() async {
    if (!mounted) return;
    final app = context.read<AppState>();
    if (_selectedProjectId == null) {
      final projectName = _projectNameCtl.text.trim();
      if (projectName.isNotEmpty) {
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
                app.setProjectId(id);
              }
              break;
            }
          }
        } catch (_) {
          // DB のマスタが空の場合は後で選択し直してもらう
        }
      }
    }

    if (_selectedProjectId != null &&
        _selectedProductId == null &&
        _productCodeCtl.text.trim().isNotEmpty) {
      try {
        final products = await FactoryDatabase.instance
            .getProductsByProject(_selectedProjectId!);
        for (final product in products) {
          final code = product['product_code']?.toString() ?? '';
          if (code == _productCodeCtl.text.trim()) {
            final id = product['id'] as int?;
            if (id != null) {
              if (!mounted) return;
              setState(() {
                _selectedProductId = id;
              });
              app.setProductId(id);
            }
            break;
          }
        }
      } catch (_) {
        // 無し
      }
    }
  }

  Future<bool> _ensureProjectSelectionIsKnown() async {
    if (_selectedProjectId != null) {
      return true;
    }
    await _syncSelectionsFromControllers();
    return _selectedProjectId != null;
  }

  Future<void> _openProjectDialog() async {
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
          _projectNameCtl.text = selected['name']?.toString() ?? '';
          _clearProductSelection(app, clearText: true);
        });
        app.setProjectName(_projectNameCtl.text);
        app.setProjectId(_selectedProjectId);
        app.scheduleAutosave();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('工事名の取得に失敗しました: $e')),
      );
    }
  }

  Future<void> _openProductDialog() async {
    if (!await _ensureProjectSelectionIsKnown()) {
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
          _productCodeCtl.text = selected['product_code']?.toString() ?? '';
        });
        app.setProductCode(_productCodeCtl.text.isEmpty
            ? null
            : _productCodeCtl.text.trim());
        app.setProductId(_selectedProductId);
        app.scheduleAutosave();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('製品符号の取得に失敗しました: $e')),
      );
    }
  }

  void _clearProductSelection(AppState app, {bool clearText = false}) {
    _selectedProductId = null;
    if (clearText) {
      _productCodeCtl.clear();
      app.setProductCode(null);
    }
    app.setProductId(null);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.settings;
    const labelW = 96.0;

    final base = Theme.of(context);
    final cs = base.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('条件入力'),
      ),
      body: Theme(
        data: base.copyWith(
          inputDecorationTheme: base.inputDecorationTheme.copyWith(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            border: const UnderlineInputBorder(),
            enabledBorder: const UnderlineInputBorder(),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: cs.error),
            ),
            focusedErrorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: cs.error, width: 2),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.never,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              FormSection(
                title: '工事情報',
                icon: Icons.apartment,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: labelW,
                          child: Text(
                            '工事名 *',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _projectNameCtl,
                                  decoration: const InputDecoration(),
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedProjectId = null;
                                      _clearProductSelection(app);
                                    });
                                    app.setProjectId(null);
                                    app.setProjectName(
                                        v.isEmpty ? null : v.trim());
                                    app.scheduleAutosave();
                                  },
                                  validator: (v) => (v == null ||
                                          v.trim().isEmpty)
                                      ? '工事名は必須です'
                                      : null,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.search),
                                tooltip: '工事名を検索',
                                onPressed: _openProjectDialog,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(
                          width: labelW,
                          child: Text(
                            '測定日',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: DateField(
                            label: '測定日',
                            showLabel: false,
                            value: s.measurementDate,
                            onChanged: (picked) {
                              app.setMeasurementDate(picked);
                              app.scheduleAutosave();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FormSection(
                title: '部材情報',
                icon: Icons.settings,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: labelW,
                          child: Text(
                            '製品符号',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _productCodeCtl,
                                  decoration: const InputDecoration(),
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedProductId = null;
                                    });
                                    app.setProductId(null);
                                    app.setProductCode(
                                        v.isEmpty ? null : v.trim());
                                    app.scheduleAutosave();
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.search),
                                tooltip: '製品符号を検索',
                                onPressed: _openProductDialog,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(
                          width: labelW,
                          child: Text(
                            '位置',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _locationCtl,
                            decoration: const InputDecoration(),
                            onChanged: (v) {
                              app.setLocation(v.isEmpty ? null : v.trim());
                              app.scheduleAutosave();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    MemberSpecTile(
                      controller: _partCtl,
                      title: '型式',
                      showLabel: false,
                      useUnderline: true,
                      typeLabelOnLeft: true,
                      typeLabelWidth: labelW,
                      onChanged: () {
                        app.setComponent(_partCtl.text.trim().isEmpty
                            ? null
                            : _partCtl.text.trim());
                        app.scheduleAutosave();
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(
                          width: labelW,
                          child: Text(
                            '材質',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: SmallDropdown<String>(
                            label: '材質',
                            showLabel: false,
                            value: s.material != null &&
                                    _materials.contains(s.material)
                                ? s.material
                                : null,
                            items: _materials
                                .map((m) =>
                                    DropdownMenuItem(value: m, child: Text(m)))
                                .toList(),
                            onChanged: (val) {
                              app.setMaterial(val);
                              app.scheduleAutosave();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FormSection(
                title: '施工条件',
                icon: Icons.build,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: labelW,
                          child: Text(
                            '溶接長 (cm)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _weldingLengthCtl,
                            decoration: const InputDecoration(),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (v) {
                              app.setWeldingLengthCm(double.tryParse(v));
                              app.scheduleAutosave();
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              return double.tryParse(v.trim()) == null
                                  ? '数値を入力してください'
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(
                          width: labelW,
                          child: Text(
                            '開先角度',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: SmallDropdown<String>(
                            label: '開先角度',
                            showLabel: false,
                            value: s.grooveAngle != null &&
                                    _grooveAngles.contains(s.grooveAngle)
                                ? s.grooveAngle
                                : null,
                            items: _grooveAngles
                                .map((g) =>
                                    DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (val) {
                              app.setGrooveAngle(val);
                              app.scheduleAutosave();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(
                          width: labelW,
                          child: Text(
                            'ルート間隔',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: SmallDropdown<String>(
                            label: 'ルート間隔',
                            showLabel: false,
                            value: s.rootGap != null &&
                                    _rootGaps.contains(s.rootGap)
                                ? s.rootGap
                                : null,
                            items: _rootGaps
                                .map((g) =>
                                    DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (val) {
                              app.setRootGap(val);
                              app.scheduleAutosave();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(
                          width: labelW,
                          child: Text(
                            '溶接姿勢',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: SmallDropdown<String>(
                            label: '溶接姿勢',
                            showLabel: false,
                            value: s.posture != null &&
                                    _postures.contains(s.posture)
                                ? s.posture
                                : null,
                            items: _postures
                                .map((p) =>
                                    DropdownMenuItem(value: p, child: Text(p)))
                                .toList(),
                            onChanged: (val) {
                              app.setWeldingPosition(val);
                              app.scheduleAutosave();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FormSection(
                title: 'その他',
                icon: Icons.more_horiz,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: labelW,
                          child: Text(
                            '天候',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: SmallDropdown<String>(
                            label: '天候',
                            showLabel: false,
                            value: (_weather != null &&
                                    _weathers.contains(_weather))
                                ? _weather
                                : null,
                            items: _weathers
                                .map((w) => DropdownMenuItem(
                                    value: w, child: Text(w)))
                                .toList(),
                            onChanged: (val) {
                              setState(() => _weather = val);
                              app.setWeather(val);
                              app.scheduleAutosave();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(
                          width: labelW,
                          child: Text(
                            '気温 (°C)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _tempCtl,
                            decoration: const InputDecoration(),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (v) {
                              app.setAmbientTempC(double.tryParse(v));
                              app.scheduleAutosave();
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              return double.tryParse(v.trim()) == null
                                  ? '数値を入力してください'
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(
                          width: labelW,
                          child: Text(
                            '湿度 (%)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _humidityCtl,
                            decoration: const InputDecoration(),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (v) {
                              app.setHumidityPercent(double.tryParse(v));
                              app.scheduleAutosave();
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final value = double.tryParse(v.trim());
                              if (value == null) {
                                return '数値を入力してください';
                              }
                              if (value < 0 || value > 100) {
                                return '0〜100の範囲で入力してください';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _onSavePressed,
            icon: const Icon(Icons.save),
            label: const Text('保存'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
