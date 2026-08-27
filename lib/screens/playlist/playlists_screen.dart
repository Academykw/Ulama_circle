import 'package:flutter/material.dart';

import '../../widgets/mini_player.dart';
import 'playlists_view.dart';

/// Standalone Playlists screen — opened from the Home "Playlists" browse card.
/// Reuses [PlaylistsView], the same list shown in the Library "Playlists" tab.
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      appBar: AppBar(title: const Text('Playlists')),
      body: const PlaylistsView(),
    );
  }
}
