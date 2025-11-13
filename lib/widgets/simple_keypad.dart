import 'package:flutter/material.dart';

class SimpleKeypad extends StatelessWidget {
  final void Function(String) onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final bool showDot;
  final bool showX;

  const SimpleKeypad({
    super.key,
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
    this.showDot = false,
    this.showX = true,
  });

  @override
  Widget build(BuildContext context) {
    final keys = <String>['7', '8', '9', '4', '5', '6', '1', '2', '3'];
    final bottomRow = <Widget>[
      _buildKey('0'),
      if (showDot) _buildKey('.') else const SizedBox.shrink(),
      if (showX) _buildKey('x') else const SizedBox.shrink(),
    ];

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 2.2,
          children: [
            for (final k in keys) _buildKey(k),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: bottomRow[0]),
            const SizedBox(width: 6),
            Expanded(child: bottomRow[1]),
            const SizedBox(width: 6),
            Expanded(child: bottomRow[2]),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: onBackspace,
                icon: const Icon(Icons.backspace_outlined, size: 16),
                label: const Text('Back', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: onClear,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String k) {
    return ElevatedButton(
      onPressed: () => onKey(k),
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
      child: Text(k, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

