import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/reciter_model.dart';
import '../../../models/recitation_model.dart';
import '../../../providers/reciter_providers.dart';
import '../../admin_theme.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_page.dart';
import 'recitation_editor_dialog.dart';

/// Recitations CRUD — pick a reciter, then manage their surahs (with audio
/// upload). Adding/removing keeps the reciter's surahCount in sync.
class RecitationsAdminScreen extends ConsumerStatefulWidget {
  const RecitationsAdminScreen({super.key});

  @override
  ConsumerState<RecitationsAdminScreen> createState() =>
      _RecitationsAdminScreenState();
}

class _RecitationsAdminScreenState
    extends ConsumerState<RecitationsAdminScreen> {
  String? _reciterId;

  Future<void> _edit(ReciterModel reciter, {RecitationModel? existing}) {
    return showDialog(
      context: context,
      builder: (_) =>
          RecitationEditorDialog(reciter: reciter, existing: existing),
    );
  }

  Future<void> _delete(RecitationModel r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete recitation?'),
        content: Text('Delete "${r.title}"?'),
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
      await ref.read(adminServiceProvider).deleteRecitation(r.id, r.reciterId);
      ref.invalidate(recitationsByReciterProvider(r.reciterId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reciters = ref.watch(recitersProvider).asData?.value ?? const [];
    final selected =
        reciters.where((r) => r.id == _reciterId).firstOrNull;

    return AdminPage(
      title: 'Recitations',
      subtitle: 'Upload surah recitations, grouped by reciter.',
      action: selected == null
          ? null
          : FilledButton.icon(
              onPressed: () => _edit(selected),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('New recitation'),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 360,
            child: DropdownButtonFormField<String>(
              initialValue: _reciterId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Reciter'),
              hint: const Text('Choose a reciter'),
              items: [
                for (final r in reciters)
                  DropdownMenuItem(
                      value: r.id,
                      child:
                          Text(r.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _reciterId = v),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: selected == null
                ? const Center(
                    child: Text('Pick a reciter to manage their surahs.',
                        style: TextStyle(color: AdminTheme.subtle)))
                : _RecitationList(
                    reciter: selected,
                    onEdit: (rec) => _edit(selected, existing: rec),
                    onDelete: _delete,
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecitationList extends ConsumerWidget {
  const _RecitationList({
    required this.reciter,
    required this.onEdit,
    required this.onDelete,
  });
  final ReciterModel reciter;
  final ValueChanged<RecitationModel> onEdit;
  final ValueChanged<RecitationModel> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recs = ref.watch(recitationsByReciterProvider(reciter.id));
    return recs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Couldn’t load recitations: $e')),
      data: (list) {
        if (list.isEmpty) {
          return const Center(
              child: Text('No recitations yet — add the first surah.',
                  style: TextStyle(color: AdminTheme.subtle)));
        }
        return Container(
          decoration: AdminTheme.card,
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AdminTheme.border),
            itemBuilder: (_, i) {
              final r = list[i];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text('${r.order}',
                          style: const TextStyle(color: AdminTheme.subtle)),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(r.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AdminTheme.ink,
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (r.kind != 'surah') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AdminTheme.olive
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(r.kindLabel,
                                  style: const TextStyle(
                                      color: Color(0xFF5C6B36),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                          Formatters.clock(
                              Duration(seconds: r.durationSeconds)),
                          style: const TextStyle(color: AdminTheme.subtle)),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: AdminTheme.ink,
                      onPressed: () => onEdit(r),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.redAccent,
                      onPressed: () => onDelete(r),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
