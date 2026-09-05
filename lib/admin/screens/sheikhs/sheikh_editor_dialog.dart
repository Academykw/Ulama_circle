import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/sheikh_model.dart';
import '../../admin_theme.dart';
import '../../providers/admin_providers.dart';
import '../../services/web_file_picker.dart';

/// Create/edit form for a scholar, shown as a modal dialog.
class SheikhEditorDialog extends ConsumerStatefulWidget {
  const SheikhEditorDialog({super.key, this.existing});
  final SheikhModel? existing;

  @override
  ConsumerState<SheikhEditorDialog> createState() => _SheikhEditorDialogState();
}

class _SheikhEditorDialogState extends ConsumerState<SheikhEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final TextEditingController _order;
  late String _language;
  late String _photoUrl;
  bool _uploadingPhoto = false;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _bio = TextEditingController(text: s?.bio ?? '');
    _order = TextEditingController(text: (s?.order ?? 0).toString());
    _language = s?.language ?? AppConstants.supportedLanguages.first;
    _photoUrl = s?.photoUrl ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final f = await pickFile('image/*');
    if (f == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref.read(adminServiceProvider).uploadBytes(
            f.bytes,
            'sheikhs/photos/${DateTime.now().millisecondsSinceEpoch}_${f.name}',
            contentType: _imageType(f.name),
          );
      setState(() => _photoUrl = url);
    } catch (e) {
      setState(() => _error = 'Image upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
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
      setState(() => _error = 'Name is required.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final model = SheikhModel(
        id: widget.existing?.id ?? '',
        name: _name.text.trim(),
        photoUrl: _photoUrl,
        language: _language,
        bio: _bio.text.trim(),
        order: int.tryParse(_order.text.trim()) ?? 0,
      );
      await ref
          .read(adminServiceProvider)
          .saveSheikh(model, id: widget.existing?.id);
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isEdit ? 'Edit scholar' : 'New scholar',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.ink)),
              const SizedBox(height: 20),
              Row(
                children: [
                  _PhotoPreview(url: _photoUrl, uploading: _uploadingPhoto),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploadingPhoto ? null : _pickPhoto,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: Text(_photoUrl.isEmpty
                          ? 'Upload photo'
                          : 'Replace photo'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AdminTheme.ink,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AdminTheme.border)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _Field(label: 'Name', controller: _name),
              const SizedBox(height: 14),
              _LanguageDropdown(
                value: _language,
                onChanged: (v) => setState(() => _language = v),
              ),
              const SizedBox(height: 14),
              _Field(label: 'Bio', controller: _bio, maxLines: 3),
              const SizedBox(height: 14),
              _Field(
                label: 'Sort order',
                controller: _order,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
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
                    onPressed:
                        _busy ? null : () => Navigator.of(context).pop(),
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
                                strokeWidth: 2, color: AdminTheme.sidebar),
                          )
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
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
  });
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AdminTheme.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.url, required this.uploading});
  final String url;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AdminTheme.bg,
        shape: BoxShape.circle,
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
              ? const Icon(Icons.person, color: AdminTheme.olive)
              : null),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Language',
            style: TextStyle(
                color: AdminTheme.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: [
            for (final l in AppConstants.supportedLanguages)
              DropdownMenuItem(value: l, child: Text(Formatters.titleCase(l))),
          ],
          onChanged: (v) => onChanged(v ?? value),
        ),
      ],
    );
  }
}
