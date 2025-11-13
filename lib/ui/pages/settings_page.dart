// lib/ui/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/member_spec_tile.dart';
import '../../widgets/form_section.dart';
import '../../widgets/date_field.dart';
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
    _humidityCtl.text = s.humidityPercent != null ? s.humidityPercent!.toString() : '';
    _weather = s.weather;
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
    if ((_projectNameCtl.text).trim().isEmpty) {
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
            contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
              // 工事情報
              FormSection(
                title: '工事情報',
                icon: Icons.apartment,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: labelW, child: Text('工事名 *', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: TextFormField(
                            controller: _projectNameCtl,
                            decoration: const InputDecoration(),
                            onChanged: (v) {
                              app.setProjectName(v.isEmpty ? null : v);
                              app.scheduleAutosave();
                            },
                            validator: (v) => (v == null || v.trim().isEmpty) ? '工事名は必須です' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: labelW, child: Text('測定日', style: TextStyle(fontWeight: FontWeight.bold))),
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

              // 部材情報
              FormSection(
                title: '部材情報',
                icon: Icons.settings,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: labelW, child: Text('製品符号', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: TextFormField(
                            controller: _productCodeCtl,
                            decoration: const InputDecoration(),
                            onChanged: (v) {
                              app.setProductCode(v.isEmpty ? null : v);
                              app.scheduleAutosave();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: labelW, child: Text('位置', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: TextFormField(
                            controller: _locationCtl,
                            decoration: const InputDecoration(),
                            onChanged: (v) {
                              app.setLocation(v.isEmpty ? null : v);
                              app.scheduleAutosave();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 種別 + 型式（MemberSpecTile 内で左ラベル「種別」とセル位置を他と揃える）
                    MemberSpecTile(
                      controller: _partCtl,
                      title: '型式',
                      showLabel: false,
                      useUnderline: true,
                      typeLabelOnLeft: true,
                      typeLabelWidth: labelW,
                      onChanged: () {
                        app.setComponent(_partCtl.text.trim().isEmpty ? null : _partCtl.text.trim());
                        app.scheduleAutosave();
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: labelW, child: Text('材質', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: SmallDropdown<String>(
                            label: '材質',
                            showLabel: false,
                            value: s.material != null && _materials.contains(s.material) ? s.material : null,
                            items: _materials.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
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

              // 施工条件
              FormSection(
                title: '施工条件',
                icon: Icons.build,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: labelW, child: Text('溶接長 (cm)', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: TextFormField(
                            controller: _weldingLengthCtl,
                            decoration: const InputDecoration(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) {
                              app.setWeldingLengthCm(double.tryParse(v));
                              app.scheduleAutosave();
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              return double.tryParse(v) == null ? '数値を入力してください' : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: labelW, child: Text('開先角度', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: SmallDropdown<String>(
                            label: '開先角度',
                            showLabel: false,
                            value: s.grooveAngle != null && _grooveAngles.contains(s.grooveAngle) ? s.grooveAngle : null,
                            items: _grooveAngles.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
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
                        const SizedBox(width: labelW, child: Text('ルート間隔', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: SmallDropdown<String>(
                            label: 'ルート間隔',
                            showLabel: false,
                            value: s.rootGap != null && _rootGaps.contains(s.rootGap) ? s.rootGap : null,
                            items: _rootGaps.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
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
                        const SizedBox(width: labelW, child: Text('溶接姿勢', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: SmallDropdown<String>(
                            label: '溶接姿勢',
                            showLabel: false,
                            value: s.posture != null && _postures.contains(s.posture) ? s.posture : null,
                            items: _postures.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
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

              // その他
              FormSection(
                title: 'その他',
                icon: Icons.more_horiz,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: labelW, child: Text('天候', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: SmallDropdown<String>(
                            label: '天候',
                            showLabel: false,
                            value: (_weather != null && _weathers.contains(_weather)) ? _weather : null,
                            items: _weathers.map((w) => DropdownMenuItem<String>(value: w, child: Text(w))).toList(),
                            onChanged: (v) {
                              setState(() => _weather = v);
                              app.setWeather(v);
                              app.scheduleAutosave();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: labelW, child: Text('気温 (°C)', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: TextFormField(
                            controller: _tempCtl,
                            decoration: const InputDecoration(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) {
                              app.setAmbientTempC(double.tryParse(v));
                              app.scheduleAutosave();
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              return double.tryParse(v.trim()) == null ? '数値を入力してください' : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: labelW, child: Text('湿度 (%)', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: TextFormField(
                            controller: _humidityCtl,
                            decoration: const InputDecoration(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) {
                              app.setHumidityPercent(double.tryParse(v));
                              app.scheduleAutosave();
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final d = double.tryParse(v.trim());
                              if (d == null) return '数値を入力してください';
                              if (d < 0 || d > 100) return '0〜100の範囲で入力してください';
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }
}

