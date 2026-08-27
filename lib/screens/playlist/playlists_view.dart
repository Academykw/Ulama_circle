import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/add_to_playlist_sheet.dart';
import '../../widgets/empty_state.dart';
import 'playlist_detail_screen.dart';

/// The user's playlists: a "New playlist" action + the list of playlists.
/// Shared by the Library "Playlists" tab and the standalone [PlaylistsScreen]
/// opened from the Home "Playlists" browse card — one source of truth.
class PlaylistsView extends ConsumerWidget {
  const PlaylistsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);

    Future<void> createPlaylist() async {
      final name = await promptPlaylistName(context);
      if (name != null && name.trim().isNotEmpty) {
        await ref.read(playlistControllerProvider).create(name.trim());
      }
    }

    return playlists.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (_, __) => const EmptyState(
          icon: Icons.error_outline, title: 'Couldn’t load playlists'),
      data: (list) {
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.gold),
              title: const Text('New playlist',
                  style: TextStyle(
                      color: AppColors.gold, fontWeight: FontWeight.w600)),
              onTap: createPlaylist,
            ),
            Divider(color: AppColors.surfaceDark, height: 1),
            Expanded(
              child: list.isEmpty
                  ? const EmptyState(
                      icon: Icons.queue_music,
                      title: 'No playlists yet',
                      subtitle: 'Create one above, or use the ⋮ on any lecture',
                    )
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final p = list[i];
                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [AppColors.gold, AppColors.olive],
                              ),
                            ),
                            child: Icon(Icons.queue_music,
                                color: AppColors.charcoal),
                          ),
                          title: Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: AppColors.cream,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${p.count} lecture${p.count == 1 ? '' : 's'}',
                              style: TextStyle(
                                  color: AppColors.mutedText, fontSize: 12)),
                          trailing: Icon(Icons.chevron_right,
                              color: AppColors.mutedText),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlaylistDetailScreen(playlistId: p.id),
                            ),
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
