import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/pass_record.dart';

void main() {
  group('Time accumulation with segments', () {
    test('start -> +10s -> pause -> +5s -> resume -> +15s', () {
      final p = PassRecord(index: 1);
      final t0 = DateTime(2025, 1, 1, 12, 0, 0);
      var pr = p.startSegment(SegmentType.welding, t0);
      // +10s
      final t1 = t0.add(const Duration(seconds: 10));
      pr = pr.endOpenSegment(t1).startSegment(SegmentType.stop, t1);
      // +5s
      final t2 = t1.add(const Duration(seconds: 5));
      pr = pr.endOpenSegment(t2).startSegment(SegmentType.welding, t2);
      // +15s (no final close; use now=t3)
      final t3 = t2.add(const Duration(seconds: 15));
      expect(pr.sum(type: SegmentType.welding, now: t3),
          const Duration(seconds: 25)); // 10 + 15 = 25
      expect(
          pr.sum(type: SegmentType.stop, now: t3), const Duration(seconds: 5));
    });
  });
}
