// test/core/duration_extensions_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:aether_project/core/extensions/duration_extensions.dart';

void main() {
  group('DurationFormatting', () {
    test('toCountdownString formats 0 correctly', () {
      expect(Duration.zero.toCountdownString(), '00:00.000');
    });

    test('toCountdownString formats 1 minute 30 seconds', () {
      const Duration d = Duration(minutes: 1, seconds: 30);
      expect(d.toCountdownString(), '01:30.000');
    });

    test('toCountdownString shows tenths of seconds', () {
      const Duration d = Duration(minutes: 0, seconds: 5, milliseconds: 600);
      expect(d.toCountdownString(), '00:05.600');
    });

    test('toCountdownString formats 30 minutes', () {
      const Duration d = Duration(minutes: 30);
      expect(d.toCountdownString(), '30:00.000');
    });

    test('progressFraction returns 0 at start', () {
      const Duration total = Duration(minutes: 30);
      expect(total.progressFraction(total), 0.0);
    });

    test('progressFraction returns 1.0 when remaining is zero', () {
      expect(Duration.zero.progressFraction(const Duration(minutes: 30)), 1.0);
    });

    test('progressFraction clamps to 0.0 on zero total', () {
      expect(const Duration(minutes: 5).progressFraction(Duration.zero), 0.0);
    });

    test('progressFraction returns 0.5 at midpoint', () {
      const Duration total = Duration(minutes: 30);
      const Duration half = Duration(minutes: 15);
      expect(half.progressFraction(total), closeTo(0.5, 0.001));
    });
  });
}
