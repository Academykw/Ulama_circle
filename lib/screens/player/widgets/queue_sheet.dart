import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/player_provider.dart';

/// Opens the queue as a draggable bottom sheet.
void showQueueSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _QueueSheet(),
  );
}

/// The queue in play order, with the current item highlighted; tap any item to
/// jump to it. Reflects shuffle order (it walks the play order, not the raw
/// list).
class _QueueSheet extends ConsumerWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(playerQueueProvider);
    final controller = ref.read(playbackControllerProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mutedText.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.queue_music, color: AppColors.gold, size: 20),
                  SizedBox(width: 8),
                  Text('Up next',
                      style: TextStyle(
                          color: AppColors.cream,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: queue.order.length,
                itemBuilder: (context, pos) {
                  final lectureIndex = queue.order[pos];
                  final lecture = queue.queue[lectureIndex];
                  final isCurrent = pos == queue.orderPos;
                  return ListTile(
                    onTap: () {
                      controller.jumpTo(lectureIndex);
                      Navigator.of(context).pop();
                    },
                    leading: isCurrent
                        ? const Icon(Icons.graphic_eq, color: AppColors.gold)
                        : Text(
                            '${pos + 1}',
                            style: const TextStyle(
                                color: AppColors.mutedText, fontSize: 14),
                          ),
                    title: Text(
                      lecture.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent ? AppColors.gold : AppColors.cream,
                        fontSize: 14,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${lecture.sheikhName}  ·  ${Formatters.duration(lecture.durationSeconds)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.mutedText, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
