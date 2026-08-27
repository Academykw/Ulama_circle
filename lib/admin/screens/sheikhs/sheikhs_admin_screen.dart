import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/sheikh_model.dart';
import '../../../providers/content_providers.dart';
import '../../admin_theme.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_page.dart';
import 'sheikh_editor_dialog.dart';

/// Scholars (sheikhs) CRUD — the first admin module. Lists the live scholars and
/// opens the editor dialog for create/edit; delete is confirmed.
class SheikhsAdminScreen extends ConsumerWidget {
  const SheikhsAdminScreen({super.key});

  Future<void> _edit(BuildContext context, {SheikhModel? sheikh}) {
    return showDialog(
      context: context,
      builder: (_) => SheikhEditorDialog(existing: sheikh),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, SheikhModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete scholar?'),
        content: Text(
            'Delete "${s.name}"? Their lectures are not removed, but they’ll '
            'lose this profile.'),
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
      await ref.read(adminServiceProvider).deleteSheikh(s.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheikhs = ref.watch(sheikhsProvider);

    return AdminPage(
      title: 'Scholars',
      subtitle: 'Add, edit and remove the scholars whose lectures you publish.',
      action: FilledButton.icon(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('New scholar'),
      ),
      child: sheikhs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Couldn’t load scholars: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
                child: Text('No scholars yet — add your first one.'));
          }
          return _SheikhTable(
            list: list,
            onEdit: (s) => _edit(context, sheikh: s),
            onDelete: (s) => _delete(context, ref, s),
          );
        },
      ),
    );
  }
}

class _SheikhTable extends StatelessWidget {
  const _SheikhTable({
    required this.list,
    required this.onEdit,
    required this.onDelete,
  });
  final List<SheikhModel> list;
  final ValueChanged<SheikhModel> onEdit;
  final ValueChanged<SheikhModel> onDelete;

  @override
  Widget build(BuildContext context) {
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
                sheikh: list[i],
                onEdit: () => onEdit(list[i]),
                onDelete: () => onDelete(list[i]),
              ),
            ),
          ),
        ],
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
          Expanded(flex: 4, child: Text('SCHOLAR', style: style)),
          Expanded(flex: 2, child: Text('LANGUAGE', style: style)),
          Expanded(flex: 2, child: Text('LECTURES', style: style)),
          Expanded(flex: 2, child: Text('VIEWS', style: style)),
          SizedBox(width: 96, child: Text('ACTIONS', style: style)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.sheikh,
    required this.onEdit,
    required this.onDelete,
  });
  final SheikhModel sheikh;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AdminTheme.olive.withValues(alpha: 0.2),
                  backgroundImage: sheikh.photoUrl.isEmpty
                      ? null
                      : NetworkImage(sheikh.photoUrl),
                  child: sheikh.photoUrl.isEmpty
                      ? const Icon(Icons.person,
                          color: AdminTheme.olive, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(sheikh.name,
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
            child: Text(Formatters.titleCase(sheikh.language),
                style: const TextStyle(color: AdminTheme.subtle)),
          ),
          Expanded(
            flex: 2,
            child: Text('${sheikh.lectureCount}',
                style: const TextStyle(color: AdminTheme.subtle)),
          ),
          Expanded(
            flex: 2,
            child: Text(Formatters.compactCount(sheikh.totalViews),
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
