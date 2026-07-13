/// Small display formatters shared across screens. Kept pure (no BuildContext)
/// so they're trivial to unit-test.
class Formatters {
  Formatters._();

  /// Human-friendly lecture length from a duration in seconds:
  ///   45      -> "1 min"   (rounds up sub-minute so nothing shows "0 min")
  ///   3480    -> "58 min"
  ///   3720    -> "1h 2m"
  static String duration(int seconds) {
    if (seconds <= 0) return '—';
    final totalMinutes = (seconds / 60).ceil();
    if (totalMinutes < 60) return '$totalMinutes min';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }

  /// Precise clock format for the player scrubber: "3:05", "1:02:07".
  static String clock(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) {
      final mm = m.toString().padLeft(2, '0');
      return '$h:$mm:$ss';
    }
    return '$m:$ss';
  }

  /// File size from megabytes: "28.6 MB", "1.2 GB".
  static String fileSize(double megabytes) {
    if (megabytes >= 1024) return '${(megabytes / 1024).toStringAsFixed(1)} GB';
    return '${megabytes.toStringAsFixed(1)} MB';
  }

  /// Capitalizes a lowercase tag/language for display: "yoruba" -> "Yoruba".
  static String titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
