// lib/widgets/stopwatch_controls.dart
import 'package:flutter/material.dart';

class StopwatchControls extends StatelessWidget {
  final String displayTime;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;
  final VoidCallback onRecord;
  final VoidCallback onCalculateHeat;

  const StopwatchControls({
    super.key,
    required this.displayTime,
    required this.onStart,
    required this.onStop,
    required this.onReset,
    required this.onRecord,
    required this.onCalculateHeat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('⏱ $displayTime', style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: onStart, child: const Text('Start')),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: onStop, child: const Text('Stop')),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: onReset, child: const Text('Reset')),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: onRecord, child: const Text('記録')),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: onCalculateHeat, child: const Text('入熱')),
          ],
        ),
      ],
    );
  }
}
