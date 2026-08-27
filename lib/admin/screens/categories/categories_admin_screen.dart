import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category_model.dart';
import '../../../providers/content_providers.dart';
import '../../admin_theme.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_page.dart';

/// Categories CRUD — small, so the editor is a lightweight dialog.
class CategoriesAdminScreen extends ConsumerWidget {
  const CategoriesAdminScreen({super.key});

  Future<void> _edit(BuildContext context, {CategoryModel? category}) {
    return showDialog(
      context: context,
      builder: (_) => _CategoryEditorDialog(existing: category),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, CategoryModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
            'Delete "${c.name}"? Lectures keep their category tag but it won’t '
            'show in browse.'),
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
      await ref.read(adminServiceProvider).deleteCategory(c.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return AdminPage(
      title: 'Categories',
      subtitle: 'The topics lectures are grouped under in the app.',
      action: FilledButton.icon(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('New category'),
      ),
      child: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Couldn’t load categories: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No categories yet.'));
          }
          return Container(
            decoration: AdminTheme.card,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AdminTheme.border),
              itemBuilder: (_, i) {
                final c = list[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: AdminTheme.gold.withValues(alpha: 0.18),
                    child: Text('${c.order}',
                        style: const TextStyle(
                            color: Color(0xFF8A6A1E),
                            fontWeight: FontWeight.w700)),
                  ),
                  title: Text(c.name,
                      style: const TextStyle(
                          color: AdminTheme.ink,
                          fontWeight: FontWeight.w600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: AdminTheme.ink,
                        onPressed: () => _edit(context, category: c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.redAccent,
                        onPressed: () => _delete(context, ref, c),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CategoryEditorDialog extends ConsumerStatefulWidget {
  const _CategoryEditorDialog({this.existing});
  final CategoryModel? existing;

  @override
  ConsumerState<_CategoryEditorDialog> createState() =>
      _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends ConsumerState<_CategoryEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _order;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _order =
        TextEditingController(text: (widget.existing?.order ?? 0).toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      return setState(() => _error = 'Name is required.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final model = CategoryModel(
        id: widget.existing?.id ?? '',
        name: _name.text.trim(),
        order: int.tryParse(_order.text.trim()) ?? 0,
      );
      await ref
          .read(adminServiceProvider)
          .saveCategory(model, id: widget.existing?.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AdminTheme.surface,
      title: Text(widget.existing == null ? 'New category' : 'Edit category',
          style: const TextStyle(fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(
              controller: _order,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Sort order'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AdminTheme.sidebar))
              : const Text('Save'),
        ),
      ],
    );
  }
}
