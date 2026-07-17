import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/play_lecture.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/add_to_playlist_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/lecture_list_tile.dart';
import '../../widgets/mini_player.dart';

/// A single playlist: its lectures, with play-all, remove, rename, and delete.
class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistByIdProvider(playlistId));
    final controller = ref.read(playlistControllerProvider);

    // Playlist was deleted (or not found) — pop back.
    if (playlist == null) {
      return Scaffold(
        backgroundColor: AppColors.charcoal,
        appBar: AppBar(),
        body: const EmptyState(
            icon: Icons.queue_music, title: 'Playlist not found'),
      );
    }

    final lectures = ref.watch(playlistLecturesProvider(playlist.idsKey));

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          PopupMenuButton<String>(
            color: AppColors.surfaceDark,
            icon: Icon(Icons.more_vert, color: AppColors.cream),
            onSelected: (value) async {
              if (value == 'rename') {
                final name =
                    await promptPlaylistName(context, initial: playlist.name);
                if (name != null && name.trim().isNotEmpty) {
                  await controller.rename(playlist.id, name.trim());
                }
              } else if (value == 'delete') {
                final ok = await _confirmDelete(context, playlist.name);
                if (ok == true) {
                  await controller.delete(playlist.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'rename',
                  child: Text('Rename',
                      style: TextStyle(color: AppColors.cream))),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete playlist',
                      style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ],
      ),
      body: lectures.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (_, __) => const EmptyState(
            icon: Icons.error_outline, title: 'Couldn’t load playlist'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.queue_music,
              title: 'This playlist is empty',
              subtitle: 'Add lectures from the player or a lecture’s menu',
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    Text(
                      '${list.length} lecture${list.length == 1 ? '' : 's'}',
                      style: TextStyle(
                          color: AppColors.mutedText, fontSize: 13),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.charcoal,
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text('Play all',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () =>
                          openLecture(context, ref, list.first, queue: list, index: 0),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final lecture = list[i];
                    return LectureListTile(
                      lecture: lecture,
                      onTap: () => openLecture(context, ref, lecture,
                          queue: list, index: i),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle_outline,
                            color: AppColors.mutedText),
                        tooltip: 'Remove from playlist',
                        onPressed: () =>
                            controller.removeLecture(playlist.id, lecture.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Delete playlist?',
            style: TextStyle(color: AppColors.cream)),
        content: Text('Delete "$name"? The lectures themselves aren’t removed.',
            style: TextStyle(color: AppColors.mutedText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.mutedText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
