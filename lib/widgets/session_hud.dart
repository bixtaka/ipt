import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class SessionHud extends StatelessWidget {
  const SessionHud({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.currentSession;
    final work = s.totalWork.inSeconds;
    final pause = s.totalPause.inSeconds;
    final total = s.totalElapsed?.inSeconds ?? 0;
    return Container(
      alignment: Alignment.centerLeft,
      width: double.infinity,
      color: const Color(0x22FF0000),
      padding: const EdgeInsets.all(8),
      child: Text(
        '⏱ work:${work}s  pause:${pause}s  total:${total}s  running:${s.isRunning} paused:${s.isPaused}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
