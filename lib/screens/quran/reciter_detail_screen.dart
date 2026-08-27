import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/px.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../models/reciter_model.dart';
import '../../models/recitation_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/reciter_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/network_loading.dart';
import '../player/player_screen.dart';
import 'widgets/reciter_cover.dart';

/// A single reciter: cover + Play All / Shuffle + the ordered list of surahs.
/// Recitations play through the normal player via [RecitationModel.toLecture].
class ReciterDetailScreen extends ConsumerWidget {
  const ReciterDetailScreen({super.key, required this.reciter});

  final ReciterModel reciter;

  void _playAll(BuildContext context, WidgetRef ref,
      List<RecitationModel> recitations, int index) {
    final lectures =
        recitations.map((r) => r.toLecture(artwork: reciter.coverUrl)).toList();
    ref
        .read(playbackControllerProvider)
        .playQueue(lectures, index, isRecitation: true);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
  }

  void _shuffle(BuildContext context, WidgetRef ref,
      List<RecitationModel> recitations) {
    final lectures =
        recitations.map((r) => r.toLecture(artwork: reciter.coverUrl)).toList();
    final controller = ref.read(playbackControllerProvider);
    controller.playQueue(lectures, 0, isRecitation: true);
    if (!ref.read(playerQueueProvider).shuffle) controller.toggleShuffle();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recitations = ref.watch(recitationsByReciterProvider(reciter.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      appBar: AppBar(
        leading: IconButton(
          icon: const PxIcon(Px.caretLeft, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(reciter.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: recitations.when(
        loading: () => NetworkLoading(
            onRetry: () =>
                ref.invalidate(recitationsByReciterProvider(reciter.id))),
        error: (_, __) => NetworkLoading(
            isError: true,
            onRetry: () =>
                ref.invalidate(recitationsByReciterProvider(reciter.id))),
        data: (list) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  reciter: reciter,
                  count: list.length,
                  onPlayAll:
                      list.isEmpty ? null : () => _playAll(context, ref, list, 0),
                  onShuffle:
                      list.isEmpty ? null : () => _shuffle(context, ref, list),
                ),
              ),
              if (list.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'No recitations yet'),
                )
              else
                SliverList.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) => _SurahRow(
                    index: i + 1,
                    recitation: list[i],
                    onTap: () => _playAll(context, ref, list, i),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.reciter,
    required this.count,
    this.onPlayAll,
    this.onShuffle,
  });

  final ReciterModel reciter;
  final int count;
  final VoidCallback? onPlayAll;
  final VoidCallback? onShuffle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          ReciterCover(coverUrl: reciter.coverUrl, size: 128, radius: 20),
          const SizedBox(height: 14),
          Text(
            reciter.name,
            textAlign: TextAlign.center,
            style: AppTheme.display(size: 22, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Quran Recitation  •  ${Formatters.titleCase(reciter.language)}',
            style: TextStyle(color: AppColors.mutedText, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '$count Surah${count == 1 ? '' : 's'}',
            style: TextStyle(color: AppColors.mutedText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPlayAll,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: const Color(0xFF0D2620),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const PxIcon(Px.playFill, size: 16),
                  label: Text(L10n.of(context).playAll,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShuffle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.6)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const PxIcon(Px.shuffle, size: 16),
                  label: Text(L10n.of(context).shuffle,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurahRow extends ConsumerWidget {
  const _SurahRow({
    required this.index,
    required this.recitation,
    required this.onTap,
  });

  final int index;
  final RecitationModel recitation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentLectureProvider);
    final isCurrent = current?.id == recitation.id;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: AppColors.cream.withValues(alpha: 0.06), width: 1),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$index',
                style: TextStyle(
                  color: isCurrent ? AppColors.gold : AppColors.mutedText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recitation.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? AppColors.gold : AppColors.cream,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.clock(
                        Duration(seconds: recitation.durationSeconds)),
                    style: TextStyle(
                        color: AppColors.mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PxIcon(
              Px.playCircleFill,
              color: isCurrent ? AppColors.gold : AppColors.mutedText,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
