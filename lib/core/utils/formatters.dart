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

  /// Compact count for play/listen tallies: 940 -> "940", 1240 -> "1.2K",
  /// 2_100_000 -> "2.1M".
  static String compactCount(int n) {
    if (n < 1000) return '$n';
    if (n < 1000000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
    }
    final m = n / 1000000;
    return '${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
  }

  /// Short "time ago" for notifications: "now", "5m", "3h", "2d", else a date.
  static String timeAgo(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${when.day}/${when.month}/${when.year}';
  }

  /// Capitalizes a lowercase tag/language for display: "yoruba" -> "Yoruba".
  static String titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
