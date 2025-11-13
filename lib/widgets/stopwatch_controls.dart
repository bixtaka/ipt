// lib/widgets/stopwatch_controls.dart
import 'package:flutter/material.dart';
import '../models/stopwatch_session.dart';

class StopwatchControls extends StatelessWidget {
  final String displayTime;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;
  final VoidCallback onRecord;
  final bool isRunning;

  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final bool? isPaused;
  final List<StopwatchEvent>? events;

  const StopwatchControls({
    super.key,
    required this.displayTime,
    required this.onStart,
    required this.onStop,
    required this.onReset,
    required this.onRecord,
    this.isRunning = false,
    this.onPause,
    this.onResume,
    this.isPaused,
    this.events,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isRunning ? Colors.green.shade700 : Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRunning ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRunning ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isRunning ? Icons.play_circle : Icons.pause_circle,
                color: isRunning ? Colors.green : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                displayTime,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: (isPaused == true && onResume != null)
                      ? ElevatedButton.icon(
                          onPressed: onResume,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('再開'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : (isRunning == true && onPause != null)
                          ? ElevatedButton.icon(
                              onPressed: onPause,
                              icon: const Icon(Icons.pause),
                              label: const Text('一時停止'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () =>
                                  isRunning ? onStop() : onStart(),
                              icon: Icon(
                                  isRunning ? Icons.pause : Icons.play_arrow),
                              label: Text(isRunning ? '停止' : '開始'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isRunning ? Colors.red : Colors.green,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('リセット'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: onRecord,
              icon: const Icon(Icons.timer),
              label: const Text('記録'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Space: 開姁E停止 | R: リセチE�� | Enter: 記録',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          if (events != null && events!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'イベントログ:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...events!.take(10).map((event) {
                    final timeStr = event.at.toString().substring(11, 19);
                    final typeStr = _getEventTypeString(event.type);
                    return Text(
                      '$timeStr: $typeStr',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getEventTypeString(StopwatchEventType type) {
    switch (type) {
      case StopwatchEventType.start:
        return '開姁E;
      case StopwatchEventType.pause:
        return '一時停止';
      case StopwatchEventType.resume:
        return '再開';
      case StopwatchEventType.stop:
        return '停止';
      case StopwatchEventType.record:
        return '記録';
      default:
        return type.name;
    }
  }
}

