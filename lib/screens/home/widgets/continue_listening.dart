import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/play_lecture.dart';
import '../../../providers/history_provider.dart';

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
        onTap: () => openLecture(context, ref, entry.toLecture()),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gold.withValues(alpha: 0.22),
                AppColors.surfaceDark,
              ],
            ),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                    color: AppColors.gold, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow,
                    color: AppColors.charcoal, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CONTINUE LISTENING',
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
                      style: const TextStyle(
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
                      style: const TextStyle(
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
