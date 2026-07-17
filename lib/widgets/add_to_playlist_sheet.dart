import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/playlist_provider.dart';

/// Bottom sheet to add/remove a lecture to/from playlists, or create a new one.
void showAddToPlaylistSheet(BuildContext context, String lectureId) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AddToPlaylistSheet(lectureId: lectureId),
  );
}

class _AddToPlaylistSheet extends ConsumerWidget {
  const _AddToPlaylistSheet({required this.lectureId});
  final String lectureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider).asData?.value ?? const [];
    final controller = ref.read(playlistControllerProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.playlist_add, color: AppColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Text('Add to playlist',
                      style: TextStyle(
                          color: AppColors.cream,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.gold),
              title: const Text('New playlist',
                  style: TextStyle(
                      color: AppColors.gold, fontWeight: FontWeight.w600)),
              onTap: () => _createPlaylist(context, controller),
            ),
            Divider(color: AppColors.charcoal, height: 1),
            Flexible(
              child: playlists.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No playlists yet — create one above.',
                          style: TextStyle(color: AppColors.mutedText)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, i) {
                        final p = playlists[i];
                        final inPlaylist = p.lectureIds.contains(lectureId);
                        return ListTile(
                          leading: Icon(Icons.queue_music,
                              color: AppColors.mutedText),
                          title: Text(p.name,
                              style: TextStyle(color: AppColors.cream)),
                          subtitle: Text(
                              '${p.count} lecture${p.count == 1 ? '' : 's'}',
                              style: TextStyle(
                                  color: AppColors.mutedText, fontSize: 12)),
                          trailing: Icon(
                            inPlaylist
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            color: inPlaylist
                                ? AppColors.olive
                                : AppColors.mutedText,
                          ),
                          onTap: () {
                            if (inPlaylist) {
                              controller.removeLecture(p.id, lectureId);
                            } else {
                              controller.addLecture(p.id, lectureId);
                            }
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _createPlaylist(
      BuildContext context, PlaylistController controller) async {
    final name = await _promptName(context);
    if (name != null && name.trim().isNotEmpty) {
      await controller.create(name.trim(), firstLectureId: lectureId);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

/// Small name-entry dialog, reused for create + rename.
Future<String?> _promptName(BuildContext context, {String initial = ''}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: Text(initial.isEmpty ? 'New playlist' : 'Rename playlist',
          style: TextStyle(color: AppColors.cream)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: TextStyle(color: AppColors.cream),
        decoration: InputDecoration(
          hintText: 'Playlist name',
          hintStyle: TextStyle(color: AppColors.mutedText),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.gold)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: TextStyle(color: AppColors.mutedText)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ctrl.text),
          child: const Text('Save', style: TextStyle(color: AppColors.gold)),
        ),
      ],
    ),
  );
}

/// Exposed for the playlist detail screen's rename action.
Future<String?> promptPlaylistName(BuildContext context, {String initial = ''}) =>
    _promptName(context, initial: initial);
