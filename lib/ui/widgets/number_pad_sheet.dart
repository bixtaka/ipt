import 'package:flutter/material.dart';
import '../styles.dart';

class NumberPadSheet extends StatefulWidget {
  final String field;
  final int? currentValue;
  final Function(int) onValueChanged;

  const NumberPadSheet({
    super.key,
    required this.field,
    required this.currentValue,
    required this.onValueChanged,
  });

  @override
  State<NumberPadSheet> createState() => _NumberPadSheetState();
}

class _NumberPadSheetState extends State<NumberPadSheet> {
  late TextEditingController _controller;
  late List<int> _presetValues;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentValue?.toString() ?? '0',
    );

    // Set preset values based on field type
    switch (widget.field) {
      case 'amps':
        _presetValues = [170, 180, 190];
        break;
      case 'volts':
        _presetValues = [22, 24, 26];
        break;
      default:
        _presetValues = [];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Field name and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getFieldLabel(widget.field),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preset chips (for amps/volts)
          if (_presetValues.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              children: _presetValues.map((preset) {
                return ActionChip(
                  label: Text('$preset'),
                  onPressed: () {
                    widget.onValueChanged(preset);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Current value display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _controller.text.isEmpty ? '0' : _controller.text,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Number keypad
          Column(
            children: [
              // Row 1: 1, 2, 3
              Row(
                children: [
                  Expanded(child: _buildNumberButton('1')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumberButton('2')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumberButton('3')),
                ],
              ),
              const SizedBox(height: 8),
              // Row 2: 4, 5, 6
              Row(
                children: [
                  Expanded(child: _buildNumberButton('4')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumberButton('5')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumberButton('6')),
                ],
              ),
              const SizedBox(height: 8),
              // Row 3: 7, 8, 9
              Row(
                children: [
                  Expanded(child: _buildNumberButton('7')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumberButton('8')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumberButton('9')),
                ],
              ),
              const SizedBox(height: 8),
              // Row 4: ±1, 0, ±5
              Row(
                children: [
                  Expanded(child: _buildStepButton('±1', () => _stepValue(1))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumberButton('0')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStepButton('±5', () => _stepValue(5))),
                ],
              ),
              const SizedBox(height: 8),
              // Row 5: Backspace, OK
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      '⌫',
                      Colors.orange,
                      () => _backspace(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      'OK',
                      Colors.green,
                      () => _confirmValue(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return SizedBox(
      height: AppStyles.buttonHeight,
      child: ElevatedButton(
        onPressed: () => _addNumber(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.black87,
          minimumSize: const Size(0, AppStyles.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusS),
          ),
        ),
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: AppStyles.buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade100,
          foregroundColor: Colors.blue.shade800,
          minimumSize: const Size(0, AppStyles.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusS),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: AppStyles.buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, AppStyles.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusS),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _addNumber(String number) {
    if (_controller.text == '0') {
      _controller.text = number;
    } else {
      _controller.text += number;
    }
    setState(() {});
  }

  void _backspace() {
    if (_controller.text.isNotEmpty) {
      _controller.text =
          _controller.text.substring(0, _controller.text.length - 1);
      if (_controller.text.isEmpty) {
        _controller.text = '0';
      }
      setState(() {});
    }
  }

  void _stepValue(int step) {
    final currentValue = int.tryParse(_controller.text) ?? 0;
    final newValue = currentValue + step;
    if (newValue >= 0) {
      _controller.text = newValue.toString();
      setState(() {});
    }
  }

  void _confirmValue() {
    final value = int.tryParse(_controller.text);
    if (value != null) {
      widget.onValueChanged(value);
      Navigator.pop(context);
    }
  }

  String _getFieldLabel(String field) {
    switch (field) {
      case 'tStart':
        return '開始温度';
      case 'tEnd':
        return '終了温度';
      case 'amps':
        return '電流 (A)';
      case 'volts':
        return '電圧 (V)';
      default:
        return '数値入力';
    }
  }
}

