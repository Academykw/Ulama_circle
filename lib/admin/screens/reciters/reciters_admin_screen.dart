import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/reciter_model.dart';
import '../../../providers/reciter_providers.dart';
import '../../admin_theme.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_page.dart';
import 'reciter_editor_dialog.dart';

/// Quran reciters CRUD. Deleting a reciter cascades to its recitations.
class RecitersAdminScreen extends ConsumerWidget {
  const RecitersAdminScreen({super.key});

  Future<void> _edit(BuildContext context, {ReciterModel? reciter}) {
    return showDialog(
      context: context,
      builder: (_) => ReciterEditorDialog(existing: reciter),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, ReciterModel r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete reciter?'),
        content: Text(
            'Delete "${r.name}" and all ${r.surahCount} of their recitations? '
            'This can’t be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(adminServiceProvider).deleteReciter(r.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reciters = ref.watch(recitersProvider);

    return AdminPage(
      title: 'Reciters',
      subtitle: 'Manage Quran reciters; add their surahs under Recitations.',
      action: FilledButton.icon(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('New reciter'),
      ),
      child: reciters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Couldn’t load reciters: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
                child: Text('No reciters yet — add your first one.'));
          }
          return Container(
            decoration: AdminTheme.card,
            child: Column(
              children: [
                const _HeaderRow(),
                const Divider(height: 1, color: AdminTheme.border),
                Expanded(
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AdminTheme.border),
                    itemBuilder: (_, i) => _Row(
                      reciter: list[i],
                      onEdit: () => _edit(context, reciter: list[i]),
                      onDelete: () => _delete(context, ref, list[i]),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
        color: AdminTheme.subtle,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5);
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('RECITER', style: style)),
          Expanded(flex: 2, child: Text('LANGUAGE', style: style)),
          Expanded(flex: 2, child: Text('SURAHS', style: style)),
          Expanded(flex: 2, child: Text('LISTENS', style: style)),
          SizedBox(width: 96, child: Text('ACTIONS', style: style)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.reciter,
    required this.onEdit,
    required this.onDelete,
  });
  final ReciterModel reciter;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AdminTheme.olive.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    image: reciter.coverUrl.isEmpty
                        ? null
                        : DecorationImage(
                            image: NetworkImage(reciter.coverUrl),
                            fit: BoxFit.cover,
                            onError: (_, __) {}),
                  ),
                  child: reciter.coverUrl.isEmpty
                      ? const Icon(Icons.menu_book,
                          color: AdminTheme.olive, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(reciter.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AdminTheme.ink,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(Formatters.titleCase(reciter.language),
                style: const TextStyle(color: AdminTheme.subtle)),
          ),
          Expanded(
            flex: 2,
            child: Text('${reciter.surahCount}',
                style: const TextStyle(color: AdminTheme.subtle)),
          ),
          Expanded(
            flex: 2,
            child: Text(Formatters.compactCount(reciter.listenCount),
                style: const TextStyle(color: AdminTheme.subtle)),
          ),
          SizedBox(
            width: 96,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AdminTheme.ink,
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.redAccent,
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
