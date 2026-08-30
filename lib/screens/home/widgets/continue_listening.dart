import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/play_lecture.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/history_provider.dart';
import '../../../widgets/gold_play_button.dart';

/// "Continue listening" card on Home — the most recent in-progress lecture with
/// a resume button. Renders nothing when there's nothing to resume.
class ContinueListening extends ConsumerWidget {
  const ContinueListening({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(continueListeningProvider);
    if (entry == null) return const SizedBox.shrink();

    final remaining = entry.durationSeconds > 0
        ? entry.durationSeconds - entry.positionSeconds
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: GestureDetector(
        onTap: () {
          // Queue the rest of recent history (most-recent-first) starting at
          // this entry, so finishing it advances to the next one instead of
          // just stopping — a single-item queue has no "next" to move to.
          final history = ref.read(historyProvider);
          final index = history.indexWhere((h) => h.id == entry.id);
          openLecture(
            context,
            ref,
            entry.toLecture(),
            queue: history.map((h) => h.toLecture()).toList(),
            index: index == -1 ? 0 : index,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.goldMid.withValues(alpha: 0.08),
            border: Border.all(color: AppColors.goldMid.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              const GoldPlayButton(size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(L10n.of(context).continueListening,
                        style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.cream,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remaining > 0
                          ? '${entry.sheikhName}  ·  ${Formatters.duration(remaining)} left'
                          : entry.sheikhName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.mutedText, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: entry.progress,
                        minHeight: 4,
                        backgroundColor: AppColors.charcoal,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
