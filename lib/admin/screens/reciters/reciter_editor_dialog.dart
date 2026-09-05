import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/reciter_model.dart';
import '../../admin_theme.dart';
import '../../providers/admin_providers.dart';
import '../../services/web_file_picker.dart';

/// Create/edit form for a Quran reciter, with optional cover image upload.
class ReciterEditorDialog extends ConsumerStatefulWidget {
  const ReciterEditorDialog({super.key, this.existing});
  final ReciterModel? existing;

  @override
  ConsumerState<ReciterEditorDialog> createState() =>
      _ReciterEditorDialogState();
}

class _ReciterEditorDialogState extends ConsumerState<ReciterEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _language;
  late final TextEditingController _description;
  late final TextEditingController _order;
  late String _coverUrl;
  bool _uploadingCover = false;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _name = TextEditingController(text: r?.name ?? '');
    _language = TextEditingController(text: r?.language ?? 'arabic');
    _description = TextEditingController(text: r?.description ?? '');
    _order = TextEditingController(text: (r?.order ?? 0).toString());
    _coverUrl = r?.coverUrl ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _language.dispose();
    _description.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final f = await pickFile('image/*');
    if (f == null) return;
    setState(() => _uploadingCover = true);
    try {
      final url = await ref.read(adminServiceProvider).uploadBytes(
            f.bytes,
            'reciters/covers/${DateTime.now().millisecondsSinceEpoch}_${f.name}',
            contentType: _imageType(f.name),
          );
      setState(() => _coverUrl = url);
    } catch (e) {
      setState(() => _error = 'Image upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  String _imageType(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
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
      final model = ReciterModel(
        id: widget.existing?.id ?? '',
        name: _name.text.trim(),
        coverUrl: _coverUrl,
        language: _language.text.trim().isEmpty
            ? 'arabic'
            : _language.text.trim(),
        description: _description.text.trim(),
        order: int.tryParse(_order.text.trim()) ?? 0,
      );
      await ref
          .read(adminServiceProvider)
          .saveReciter(model, id: widget.existing?.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isEdit ? 'Edit reciter' : 'New reciter',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.ink)),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _CoverPreview(url: _coverUrl, uploading: _uploadingCover),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploadingCover ? null : _pickCover,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: Text(_coverUrl.isEmpty
                          ? 'Upload cover image'
                          : 'Replace cover'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AdminTheme.ink,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AdminTheme.border)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _label('Name'),
              TextField(controller: _name),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Language'),
                        TextField(controller: _language),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Sort order'),
                        TextField(
                          controller: _order,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _label('Description'),
              TextField(controller: _description, maxLines: 3),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AdminTheme.sidebar))
                        : Text(_isEdit ? 'Save changes' : 'Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: AdminTheme.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.url, required this.uploading});
  final String url;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AdminTheme.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
        image: url.isEmpty
            ? null
            : DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
                onError: (_, __) {},
              ),
      ),
      child: uploading
          ? const Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2)))
          : (url.isEmpty
              ? const Icon(Icons.menu_book, color: AdminTheme.olive)
              : null),
    );
  }
}
