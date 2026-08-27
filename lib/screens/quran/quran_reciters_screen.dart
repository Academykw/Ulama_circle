import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/px.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../models/reciter_model.dart';
import '../../providers/player_provider.dart';
import '../../providers/reciter_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gold_play_button.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/network_loading.dart';
import '../player/player_screen.dart';
import 'reciter_detail_screen.dart';
import 'widgets/reciter_cover.dart';

/// The full Quran Reciters directory — opened from the Home "Quran" browse card
/// and the "Quran Recitations" See All. Searchable list of reciters; tapping one
/// opens their surahs, tapping the play button plays the whole reciter.
class QuranRecitersScreen extends ConsumerStatefulWidget {
  const QuranRecitersScreen({super.key});

  @override
  ConsumerState<QuranRecitersScreen> createState() =>
      _QuranRecitersScreenState();
}

class _QuranRecitersScreenState extends ConsumerState<QuranRecitersScreen> {
  String _query = '';

  Future<void> _playReciter(ReciterModel reciter) async {
    final recitations =
        await ref.read(recitationsByReciterProvider(reciter.id).future);
    if (!mounted) return;
    if (recitations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recitations yet')),
      );
      return;
    }
    final lectures =
        recitations.map((r) => r.toLecture(artwork: reciter.coverUrl)).toList();
    ref
        .read(playbackControllerProvider)
        .playQueue(lectures, 0, isRecitation: true);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
  }

  void _openReciter(ReciterModel reciter) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReciterDetailScreen(reciter: reciter)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reciters = ref.watch(recitersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      appBar: AppBar(
        leading: IconButton(
          icon: const PxIcon(Px.caretLeft, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(L10n.of(context).quranReciters),
      ),
      body: reciters.when(
        loading: () =>
            NetworkLoading(onRetry: () => ref.invalidate(recitersProvider)),
        error: (_, __) => NetworkLoading(
            isError: true, onRetry: () => ref.invalidate(recitersProvider)),
        data: (all) {
          final q = _query.trim().toLowerCase();
          final list = q.isEmpty
              ? all
              : all.where((r) => r.name.toLowerCase().contains(q)).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  L10n.of(context).recitersIntro,
                  style: TextStyle(color: AppColors.mutedText, fontSize: 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${all.length} reciter${all.length == 1 ? '' : 's'}',
                      style: TextStyle(
                          color: AppColors.cream,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(color: AppColors.cream),
                  decoration: InputDecoration(
                    hintText: L10n.of(context).searchQuranReciters,
                    hintStyle: TextStyle(color: AppColors.faintText),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: PxIcon(Px.magnifyingGlass,
                          color: AppColors.mutedText, size: 18),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const EmptyState(
                        icon: Icons.person_search, title: 'No reciters found')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _ReciterCard(
                          reciter: list[i],
                          onTap: () => _openReciter(list[i]),
                          onPlay: () => _playReciter(list[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReciterCard extends StatelessWidget {
  const _ReciterCard({
    required this.reciter,
    required this.onTap,
    required this.onPlay,
  });

  final ReciterModel reciter;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cream.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            ReciterCover(coverUrl: reciter.coverUrl, size: 56, radius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reciter.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.cream.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          Formatters.titleCase(reciter.language),
                          style: TextStyle(
                              color: AppColors.cream, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${reciter.surahCount} Surahs  ·  ${Formatters.compactCount(reciter.listenCount)}',
                        style: TextStyle(
                            color: AppColors.faintText, fontSize: 11.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GoldPlayButton(size: 38, onTap: onPlay),
          ],
        ),
      ),
    );
  }
}
