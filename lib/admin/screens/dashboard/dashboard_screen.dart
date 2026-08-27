import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../admin_theme.dart';
import '../../models/daily_stat.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/admin_page.dart';

/// Responsive grid: fits as many columns as [minWidth] allows, wrapping to new
/// rows on smaller screens (desktop → tablet → phone). Replaces fixed columns
/// so the whole dashboard reflows cleanly on any width.
class _Grid extends StatelessWidget {
  const _Grid({required this.children, this.minWidth = 200, this.gap = 20});
  final List<Widget> children;
  final double minWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth;
        var cols = ((maxW + gap) / (minWidth + gap)).floor();
        cols = cols.clamp(1, children.length);
        final itemW = (maxW - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: itemW, child: child),
          ],
        );
      },
    );
  }
}

/// Analytics overview: audience + engagement headline metrics, catalogue counts,
/// top content, and a language breakdown.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardDataProvider);

    return AdminPage(
      title: 'Dashboard',
      subtitle: 'Audience, engagement and catalogue at a glance.',
      action: IconButton(
        tooltip: 'Refresh',
        icon: const Icon(Icons.refresh),
        onPressed: () => ref.invalidate(dashboardDataProvider),
      ),
      child: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Couldn’t load stats: $e')),
        data: (d) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Audience & engagement'),
              _Grid(minWidth: 200, gap: 16, children: [
                _HeroCard(
                    label: 'Total users',
                    value: Formatters.compactCount(d.totalUsers),
                    icon: Icons.people_alt_outlined,
                    color: AdminTheme.gold),
                _HeroCard(
                    label: 'Active today',
                    value: Formatters.compactCount(d.dailyActiveUsers),
                    icon: Icons.bolt_outlined,
                    color: AdminTheme.olive),
                _HeroCard(
                    label: 'New this week',
                    value: Formatters.compactCount(d.newUsersThisWeek),
                    icon: Icons.person_add_alt_1_outlined,
                    color: AdminTheme.gold),
                _HeroCard(
                    label: 'Lecture plays',
                    value: Formatters.compactCount(d.totalPlays),
                    icon: Icons.play_circle_outline,
                    color: AdminTheme.gold),
                _HeroCard(
                    label: 'Recitation listens',
                    value: Formatters.compactCount(d.totalListens),
                    icon: Icons.headphones_outlined,
                    color: AdminTheme.olive),
              ]),
              const SizedBox(height: 32),
              const _SectionTitle('Growth & activity'),
              _Grid(minWidth: 440, gap: 20, children: [
                _GrowthChart(series: d.newUsersByDay),
                _ActivityChart(stats: d.dailyStats),
              ]),
              const SizedBox(height: 32),
              const _SectionTitle('What people are listening to'),
              _Grid(minWidth: 320, gap: 20, children: [
                _Panel(
                  title: 'Top lectures this week',
                  child: Column(
                    children: [
                      for (var i = 0; i < d.topLecturesThisWeek.length; i++)
                        _RankRow(
                          rank: i + 1,
                          title: d.topLecturesThisWeek[i].title,
                          subtitle: d.topLecturesThisWeek[i].sheikhName,
                          metric:
                              '${Formatters.compactCount(d.topLecturesThisWeek[i].plays)} plays',
                        ),
                      if (d.topLecturesThisWeek.isEmpty)
                        const _Empty(text: 'No plays logged this week yet'),
                    ],
                  ),
                ),
                _Panel(
                  title: 'Most listened (all time)',
                  child: Column(
                    children: [
                      for (var i = 0; i < d.topLectures.length; i++)
                        _RankRow(
                          rank: i + 1,
                          title: d.topLectures[i].title,
                          subtitle: d.topLectures[i].sheikhName,
                          metric:
                              '${Formatters.compactCount(d.topLectures[i].playCount)} plays',
                        ),
                      if (d.topLectures.isEmpty) const _Empty(),
                    ],
                  ),
                ),
                _Panel(
                  title: 'Most viewed recitations',
                  child: Column(
                    children: [
                      for (var i = 0; i < d.topRecitations.length; i++)
                        _RankRow(
                          rank: i + 1,
                          title: d.topRecitations[i].title,
                          subtitle: d.topRecitations[i].reciterName,
                          metric:
                              '${Formatters.compactCount(d.topRecitations[i].listenCount)} listens',
                        ),
                      if (d.topRecitations.isEmpty) const _Empty(),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 32),
              const _SectionTitle('Catalogue'),
              _Grid(minWidth: 150, gap: 16, children: [
                _MiniStat(label: 'Scholars', value: d.scholars),
                _MiniStat(label: 'Lectures', value: d.lectures),
                _MiniStat(label: 'Reciters', value: d.reciters),
                _MiniStat(label: 'Recitations', value: d.recitations),
                _MiniStat(label: 'Categories', value: d.categories),
                _MiniStat(label: 'Featured', value: d.featured),
              ]),
              const SizedBox(height: 24),
              _Panel(
                title: 'Lectures by language',
                child: Column(
                  children: [
                    for (final e in d.languageCounts.entries)
                      _LanguageBar(
                        label: Formatters.titleCase(e.key),
                        value: e.value,
                        max: d.languageCounts.values.isEmpty
                            ? 1
                            : d.languageCounts.values
                                .reduce((a, b) => a > b ? a : b),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AdminTheme.ink)),
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AdminTheme.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(value,
              style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AdminTheme.ink)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AdminTheme.subtle, fontSize: 14)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AdminTheme.ink)),
          Text(label,
              style: const TextStyle(color: AdminTheme.subtle, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AdminTheme.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.ink)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.metric,
  });
  final int rank;
  final String title;
  final String subtitle;
  final String metric;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AdminTheme.gold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8)),
            child: Text('$rank',
                style: const TextStyle(
                    color: Color(0xFF8A6A1E),
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AdminTheme.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AdminTheme.subtle, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(metric,
              style: const TextStyle(
                  color: AdminTheme.olive,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _LanguageBar extends StatelessWidget {
  const _LanguageBar({
    required this.label,
    required this.value,
    required this.max,
  });
  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AdminTheme.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text('$value',
                  style:
                      const TextStyle(color: AdminTheme.subtle, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: max == 0 ? 0 : value / max,
              minHeight: 8,
              backgroundColor: AdminTheme.bg,
              color: AdminTheme.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.stats});
  final List<DailyStat> stats;

  @override
  Widget build(BuildContext context) {
    final maxVal = stats.isEmpty
        ? 1
        : stats.map((s) => s.total).fold<int>(1, (a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AdminTheme.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('Plays & listens',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.ink)),
              Spacer(),
              _Legend(color: AdminTheme.gold, label: 'Plays'),
              SizedBox(width: 16),
              _Legend(color: AdminTheme.olive, label: 'Listens'),
            ],
          ),
          const SizedBox(height: 20),
          if (stats.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'No activity logged yet.\nDeploy Cloud Functions (Blaze) — plays/listens then appear here daily.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AdminTheme.subtle, fontSize: 13),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final s in stats)
                    Expanded(
                      child: _DayColumn(stat: s, maxVal: maxVal),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.stat, required this.maxVal});
  final DailyStat stat;
  final int maxVal;

  @override
  Widget build(BuildContext context) {
    const barMax = 130.0;
    final playsH = maxVal == 0 ? 0.0 : (stat.plays / maxVal) * barMax;
    final listensH = maxVal == 0 ? 0.0 : (stat.listens / maxVal) * barMax;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('${stat.total}',
            style: const TextStyle(
                color: AdminTheme.subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 22, height: listensH, color: AdminTheme.olive),
              Container(width: 22, height: playsH, color: AdminTheme.gold),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(stat.shortLabel,
            style: const TextStyle(color: AdminTheme.subtle, fontSize: 10)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(color: AdminTheme.subtle, fontSize: 12)),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({this.text = 'No data yet'});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text,
            style: const TextStyle(color: AdminTheme.subtle, fontSize: 13)),
      );
}

/// New sign-ups per day — gold bars, one per day.
class _GrowthChart extends StatelessWidget {
  const _GrowthChart({required this.series});
  final List<({String date, int count})> series;

  @override
  Widget build(BuildContext context) {
    final total = series.fold<int>(0, (a, s) => a + s.count);
    final maxVal =
        series.map((s) => s.count).fold<int>(1, (a, b) => a > b ? a : b);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AdminTheme.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('New users / day',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.ink)),
              const Spacer(),
              Text('$total in ${series.length} days',
                  style: const TextStyle(
                      color: AdminTheme.subtle,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          if (series.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(
                  child: Text('No sign-ups yet.',
                      style:
                          TextStyle(color: AdminTheme.subtle, fontSize: 13))),
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final s in series)
                    Expanded(
                      child: _GrowthBar(
                        count: s.count,
                        day: s.date.length >= 10 ? s.date.substring(8) : s.date,
                        maxVal: maxVal,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GrowthBar extends StatelessWidget {
  const _GrowthBar(
      {required this.count, required this.day, required this.maxVal});
  final int count;
  final String day;
  final int maxVal;

  @override
  Widget build(BuildContext context) {
    const barMax = 130.0;
    final h = maxVal == 0 ? 0.0 : (count / maxVal) * barMax;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$count',
            style: const TextStyle(
                color: AdminTheme.subtle,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          width: 16,
          height: count == 0 ? 3 : h,
          decoration: BoxDecoration(
            color: count == 0 ? AdminTheme.border : AdminTheme.gold,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 6),
        Text(day,
            style: const TextStyle(color: AdminTheme.subtle, fontSize: 9)),
      ],
    );
  }
}
