import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/lecture_model.dart';
import '../../../providers/content_providers.dart';
import '../../admin_theme.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_page.dart';
import 'lecture_editor_dialog.dart';

/// Lectures CRUD with audio upload. Lists the newest lectures (paginated via
/// latestLecturesProvider) and opens the editor for create/edit.
class LecturesAdminScreen extends ConsumerWidget {
  const LecturesAdminScreen({super.key});

  Future<void> _edit(BuildContext context, {LectureModel? lecture}) {
    return showDialog(
      context: context,
      builder: (_) => LectureEditorDialog(existing: lecture),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, LectureModel l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete lecture?'),
        content: Text('Delete "${l.title}"? This can’t be undone.'),
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
      await ref.read(adminServiceProvider).deleteLecture(l.id);
      ref.invalidate(latestLecturesProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectures = ref.watch(latestLecturesProvider);
    final controller = ref.read(latestLecturesProvider.notifier);

    return AdminPage(
      title: 'Lectures',
      subtitle: 'Upload and manage lecture audio, newest first.',
      action: FilledButton.icon(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('New lecture'),
      ),
      child: lectures.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Couldn’t load lectures: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
                child: Text('No lectures yet — add your first one.'));
          }
          return Container(
            decoration: AdminTheme.card,
            child: Column(
              children: [
                const _HeaderRow(),
                const Divider(height: 1, color: AdminTheme.border),
                Expanded(
                  child: ListView.separated(
                    itemCount: list.length + (controller.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AdminTheme.border),
                    itemBuilder: (_, i) {
                      if (i >= list.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: OutlinedButton(
                              onPressed: controller.loadMore,
                              child: const Text('Load more'),
                            ),
                          ),
                        );
                      }
                      return _Row(
                        lecture: list[i],
                        onEdit: () => _edit(context, lecture: list[i]),
                        onDelete: () => _delete(context, ref, list[i]),
                      );
                    },
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
          Expanded(flex: 5, child: Text('TITLE', style: style)),
          Expanded(flex: 3, child: Text('SCHOLAR', style: style)),
          Expanded(flex: 2, child: Text('CATEGORY', style: style)),
          Expanded(flex: 2, child: Text('LENGTH', style: style)),
          SizedBox(width: 96, child: Text('ACTIONS', style: style)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.lecture,
    required this.onEdit,
    required this.onDelete,
  });
  final LectureModel lecture;
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
                Expanded(
                  child: Text(lecture.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AdminTheme.ink,
                          fontWeight: FontWeight.w600)),
                ),
                if (lecture.isFeatured)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AdminTheme.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('Featured',
                        style: TextStyle(
                            color: Color(0xFF8A6A1E),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(lecture.sheikhName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AdminTheme.subtle)),
          ),
          Expanded(
            flex: 2,
            child: Text(Formatters.titleCase(lecture.category),
                style: const TextStyle(color: AdminTheme.subtle)),
          ),
          Expanded(
            flex: 2,
            child: Text(Formatters.duration(lecture.durationSeconds),
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
