// lib/core/extensions/duration_extensions.dart

/// Formatting extensions for countdown display.
extension DurationFormatting on Duration {
  /// Formats to MM:SS.t (minutes, seconds, tenths).
  /// Used by the world boss countdown for the 100ms tick display.
  String toCountdownString() {
    final int totalSeconds = inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final int tenths = (inMilliseconds % 1000);

    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');

    return '$mm:$ss.${tenths.toString().padLeft(3, '0')}';
  }

  /// Fraction complete [0.0 – 1.0] relative to a total duration.
  double progressFraction(Duration total) {
    if (total.inMilliseconds <= 0) return 0.0;
    final double elapsed =
        (total.inMilliseconds - inMilliseconds).toDouble();
    return (elapsed / total.inMilliseconds).clamp(0.0, 1.0);
  }
}
