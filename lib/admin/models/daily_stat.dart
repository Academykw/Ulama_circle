/// One day's play/listen rollup (from the stats_daily collection).
class DailyStat {
  const DailyStat({
    required this.date,
    required this.plays,
    required this.listens,
  });

  final String date; // YYYY-MM-DD
  final int plays;
  final int listens;

  int get total => plays + listens;

  /// Short label for the chart axis, e.g. "07-16" → "16 Jul".
  String get shortLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final parts = date.split('-');
    if (parts.length != 3) return date;
    final m = int.tryParse(parts[1]) ?? 1;
    return '${parts[2]} ${months[(m - 1).clamp(0, 11)]}';
  }
}
