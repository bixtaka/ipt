import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'simple_keypad.dart';

class MemberSpecTile extends StatefulWidget {
  final TextEditingController controller;
  final String title;
  final VoidCallback? onChanged;
  final bool borderless;
  final bool useUnderline;
  final bool showLabel;
  final bool typeLabelOnLeft;
  final double? typeLabelWidth;
  final String? typeLabelText;

  const MemberSpecTile({
    super.key,
    required this.controller,
    required this.title,
    this.onChanged,
    this.borderless = false,
    this.useUnderline = false,
    this.showLabel = true,
    this.typeLabelOnLeft = false,
    this.typeLabelWidth,
    this.typeLabelText,
  });

  @override
  State<MemberSpecTile> createState() => _MemberSpecTileState();
}

class _MemberSpecTileState extends State<MemberSpecTile> {
  static const List<String> _types = ['H', 'BH', 'HY', 'SH', '□', 'P', 'PL'];

  late String _type;
  String _numeric = '';
  List<String> _suggestions = [];
  FocusNode? _inputFocus;
  bool _showKeypad = false;

  // H-section master (normalized)
  List<String>? _hList;
  bool _loadingList = false;
  String? _firstDigitForSuggest;

  @override
  void initState() {
    super.initState();
    final parsed = _parse(widget.controller.text);
    _type = parsed.$1;
    _numeric = parsed.$2;
    _ensureFocus();
  }

  (String, String) _parse(String raw) {
    final s = (raw).trim();
    for (final t in _types) {
      final pfx = '$t-';
      if (s.startsWith(pfx)) {
        return (t, s.substring(pfx.length));
      }
    }
    if (s.startsWith('SY-')) {
      return ('SH', s.substring(3));
    }
    return ('H', '');
  }

  void _notify() {
    widget.controller.text = '$_type-${_numeric.trim()}';
    widget.onChanged?.call();
  }

  void _ensureFocus() {
    if (_inputFocus != null) return;
    _inputFocus = FocusNode();
    _inputFocus!.addListener(() {
      if (!mounted) return;
      setState(() => _showKeypad = _inputFocus!.hasFocus);
    });
  }

  int _xCount() => RegExp(r'x').allMatches(_numeric).length;
  String _currentSegment() {
    final i = _numeric.lastIndexOf('x');
    return i == -1 ? _numeric : _numeric.substring(i + 1);
  }

  bool get _allowDot {
    final xCount = _xCount();
    if (_type == 'P') {
      // P: &x# → 小数は先頭セグメントのみ
      if (xCount != 0) return false;
      final seg = _currentSegment();
      if (seg.isEmpty) return false;
      if (seg.contains('.')) return false;
      return true;
    }
    if (_type == 'H') {
      // H: #x#x&x# → 3番目のみ小数可
      if (xCount != 2) return false;
      final seg = _currentSegment();
      if (seg.isEmpty) return false;
      if (seg.contains('.')) return false;
      return true;
    }
    return false;
  }

  int get _maxXCount {
    switch (_type) {
      case 'H':
      case 'BH':
      case 'HY':
      case 'SH':
        return 3;
      case '□':
        return 2;
      case 'P':
        return 1;
      case 'PL':
      default:
        return 0;
    }
  }

  void _onKey(String k) {
    setState(() {
      final wasEmpty = _numeric.isEmpty;
      if ('0123456789'.contains(k)) {
        _numeric += k;
        if (wasEmpty) {
          _firstDigitForSuggest = k;
          _suggestions = _buildFirstDigitSuggestionsSync(_type, k);
          _buildFirstDigitSuggestionsAsync(_type, k);
        } else {
          _suggestions = [];
        }
      } else if (k == 'x') {
        final xCount = _xCount();
        if (_maxXCount == 0) return;
        if (_numeric.isEmpty) return; // 先頭 x 不可
        if (_numeric.endsWith('x') || _numeric.endsWith('.')) return;
        if (xCount < _maxXCount) _numeric += 'x';
        _suggestions = [];
      } else if (k == '.') {
        if (!_allowDot) return;
        _numeric += '.';
        _suggestions = [];
      }
      _notify();
    });
  }

  void _onBackspace() {
    setState(() {
      if (_numeric.isNotEmpty) {
        _numeric = _numeric.substring(0, _numeric.length - 1);
      }
      _suggestions = [];
      _notify();
    });
  }

  void _onClear() {
    setState(() {
      _numeric = '';
      _suggestions = [];
      _notify();
    });
  }

  bool _isValid(String v) {
    final s = v.replaceAll(RegExp(r'\s+'), '');
    const x = r"x"; // 区切りは x のみ
    const d = r"\d+"; // 整数
    const n = r"(?:\d+(?:\.\d+)?)"; // 整数または小数
    final re = RegExp(
        r'^(?:H-' + d + x + d + x + n + x + d +
            r'|BH-' + d + x + d + x + d + x + d +
            r'|HY-' + d + x + d + x + d + x + d +
            r'|SH-' + d + x + d + x + d + x + d +
            r'|□-' + d + x + d + x + d +
            r'|P-' + n + x + d +
            r'|PL-' + d + r')$');
    return re.hasMatch(s);
  }

  // fallback: 即時候補（資産未ロード時）
  List<String> _buildFirstDigitSuggestionsSync(String type, String firstDigit) {
    if (type != 'H' || firstDigit.isEmpty || !'0123456789'.contains(firstDigit)) {
      return const [];
    }
    final height = '${firstDigit}00';
    final base = 'H-$height';
    if (firstDigit == '9') {
      return [base, '${base}x300', '${base}x300x16', '${base}x300x16x28'];
    }
    return [base];
  }

  // リスト連動: H セクション資産から抽出
  Future<void> _buildFirstDigitSuggestionsAsync(String type, String firstDigit) async {
    if (!mounted) return;
    if (type != 'H' || firstDigit.isEmpty || !'0123456789'.contains(firstDigit)) return;
    if (_loadingList) return;
    if (_hList == null) {
      _loadingList = true;
      try {
        final raw = await rootBundle.loadString('assets/h_steel_jis.json');
        final map = convert.jsonDecode(raw) as Map<String, dynamic>;
        final all = <String>[];
        for (final v in map.values) {
          if (v is List) {
            for (final e in v) {
              if (e is String) {
                final n = _normalizeSteelText(e);
                if (n.startsWith('H-')) all.add(n);
              }
            }
          }
        }
        _hList = all;
      } catch (_) {
        // ignore errors; keep fallback suggestions
      } finally {
        _loadingList = false;
      }
    }
    if (!mounted) return;
    if (_hList != null && _firstDigitForSuggest == firstDigit) {
      final re = RegExp('^H-${RegExp.escape(firstDigit)}\\d{2}');
      final filtered = _hList!.where((s) => re.hasMatch(s)).toList()..sort();
      if (filtered.isNotEmpty) {
        setState(() {
          _suggestions = filtered.take(12).toList();
        });
      }
    }
  }

  String _normalizeSteelText(String s) {
    var t = s;
    t = t.replaceAll('×', 'x');
    t = t.replaceAll('ｘ', 'x');
    t = t.replaceAll('ÁE', 'x'); // simple mojibake fallback
    t = t.replaceAll(RegExp(r'\s+'), ''); // trim whitespaces
    return t;
  }

  @override
  void dispose() {
    _inputFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = '$_type-${_numeric.trim()}';
    final hasInput = _numeric.trim().isNotEmpty;
    final error = !hasInput || _isValid(value)
        ? null
        : '形式: H/BH/HY/SH = #x#x#x#、□ = #x#x#、P = &x#、PL = #';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_inputFocus?.hasFocus ?? false) {
          _inputFocus!.unfocus();
        }
        setState(() => _showKeypad = false);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (context) {
              final dd = DropdownButtonFormField<String>(
                value: _type,
                decoration: widget.typeLabelOnLeft
                    ? const InputDecoration()
                    : InputDecoration(labelText: String.fromCharCodes([0x92FC, 0x7A2E])),
                items: _types
                    .map((t) => DropdownMenuItem<String>(
                          value: t,
                          child: Text(t),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _type = v;
                    _numeric = '';
                    _suggestions = [];
                    _notify();
                  });
                },
              );
              if (!widget.typeLabelOnLeft) return dd;
              final lw = widget.typeLabelWidth ?? 96.0;
              return Row(
                children: [
                  SizedBox(
                    width: lw,
                    child: Text(widget.typeLabelText ?? String.fromCharCodes([0x92FC, 0x7A2E]),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(child: dd),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final tf = TextFormField(
                readOnly: true,
                controller: TextEditingController(text: hasInput ? value : ''),
                focusNode: _inputFocus,
                onTap: () {
                  _ensureFocus();
                  _inputFocus!.requestFocus();
                  setState(() => _showKeypad = true);
                },
                decoration: InputDecoration(
                  labelText: widget.showLabel ? '型式' : null,
                  hintText: () {
                    switch (_type) {
                      case 'H':
                      case 'BH':
                      case 'HY':
                      case 'SH':
                        return '$_type-#x#x#x#';
                      case '□':
                        return '□-#x#x#';
                      case 'P':
                        return 'P-&x#';
                      case 'PL':
                        return 'PL-#';
                      default:
                        return null;
                    }
                  }(),
                  border: widget.borderless
                      ? InputBorder.none
                      : (widget.useUnderline
                          ? const UnderlineInputBorder()
                          : const OutlineInputBorder()),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                ),
              );
              if (!widget.typeLabelOnLeft) return tf;
              final lw = widget.typeLabelWidth ?? 96.0;
              return Row(
                children: [
                  SizedBox(
                    width: lw,
                    child: Text(
                      String.fromCharCodes([0x65AD, 0x9762, 0x5BF8, 0x6CD5]), // 断面寸法
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(child: tf),
                ],
              );
            },
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              elevation: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, i) {
                    final s = _suggestions[i];
                    return ListTile(
                      dense: true,
                      title: Text(s),
                      trailing: const Icon(Icons.north_west, size: 16),
                      onTap: () {
                        setState(() {
                          final dash = s.indexOf('-');
                          _numeric = dash >= 0 ? s.substring(dash + 1) : s;
                          _suggestions = [];
                          _notify();
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (_showKeypad)
            SimpleKeypad(
              onKey: _onKey,
              onBackspace: _onBackspace,
              onClear: _onClear,
              showDot: _allowDot,
              showX: _maxXCount > 0,
            ),
        ],
      ),
    );
  }
}






