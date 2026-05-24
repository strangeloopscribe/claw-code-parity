import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';

class JournalEntryScreen extends ConsumerStatefulWidget {
  const JournalEntryScreen({super.key, this.entryId});

  final String? entryId;

  @override
  ConsumerState<JournalEntryScreen> createState() =>
      _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _newPhotos = [];
  bool _loading = false;
  bool _editing = false;
  JournalEntry? _existing;

  bool get isNew => widget.entryId == null;

  @override
  void initState() {
    super.initState();
    if (!isNew) {
      _loadExisting();
    } else {
      _editing = true;
    }
  }

  void _loadExisting() {
    final entries = ref.read(journalProvider).value ?? [];
    final match = entries.where((e) => e.id == widget.entryId).firstOrNull;
    if (match != null) {
      setState(() {
        _existing = match;
        _titleCtrl.text = match.title ?? '';
        _bodyCtrl.text = match.body ?? '';
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await _picker.pickMultiImage(imageQuality: 80);
    if (result.isEmpty) return;
    setState(() => _newPhotos.addAll(result.map((x) => File(x.path))));
  }

  Future<void> _pickCamera() async {
    final result = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 80);
    if (result == null) return;
    setState(() => _newPhotos.add(File(result.path)));
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final notifier = ref.read(journalProvider.notifier);
    try {
      if (isNew || _existing == null) {
        await notifier.createEntry(
          title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim().isEmpty ? null : _bodyCtrl.text.trim(),
          photos: _newPhotos,
        );
      } else {
        await notifier.updateEntry(
          id: _existing!.id,
          title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim().isEmpty ? null : _bodyCtrl.text.trim(),
          newPhotos: _newPhotos,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this memory?'),
        content: const Text('All photos and text will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(journalProvider.notifier).deleteEntry(_existing!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(journalProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew
            ? 'New Memory'
            : (_editing ? 'Edit Memory' : _existing?.displayTitle ?? '')),
        actions: [
          if (!isNew && _existing != null && !_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            ),
          if (!isNew && _existing != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              onPressed: _delete,
            ),
          if (_editing)
            TextButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date display
            if (_existing != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  DateFormat.yMMMMd().format(_existing!.createdAt),
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ),
            // Title
            if (_editing)
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'Title (optional)',
                  border: InputBorder.none,
                ),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              )
            else if (_existing?.title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _existing!.title!,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 8),
            // Body
            if (_editing)
              TextField(
                controller: _bodyCtrl,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Write about this moment…',
                  border: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              )
            else if (_existing?.body != null)
              Text(
                _existing!.body!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            const SizedBox(height: 20),
            // Existing photos
            if (_existing != null && _existing!.hasPhotos) ...[
              _PhotoGrid(
                storagePaths: _existing!.photoUrls,
                notifier: notifier,
                entryId: _existing!.id,
                editable: _editing,
                onDelete: (path) async {
                  await notifier.deletePhoto(_existing!.id, path);
                  _loadExisting();
                },
              ),
              const SizedBox(height: 12),
            ],
            // New photos preview
            if (_newPhotos.isNotEmpty) ...[
              Text('Adding ${_newPhotos.length} new photo(s)',
                  style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newPhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_newPhotos[i],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _newPhotos.removeAt(i)),
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: cs.error,
                            child: Icon(Icons.close,
                                size: 12, color: cs.onError),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Add photos buttons
            if (_editing) ...[
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _pickCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.storagePaths,
    required this.notifier,
    required this.entryId,
    required this.editable,
    required this.onDelete,
  });

  final List<String> storagePaths;
  final JournalNotifier notifier;
  final String entryId;
  final bool editable;
  final Future<void> Function(String path) onDelete;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: storagePaths.length,
      itemBuilder: (context, i) {
        final url = notifier.photoUrl(storagePaths[i]);
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => _showFullscreen(context, url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (editable)
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => onDelete(storagePaths[i]),
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor:
                        Theme.of(context).colorScheme.error,
                    child: Icon(Icons.close,
                        size: 12,
                        color: Theme.of(context).colorScheme.onError),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showFullscreen(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(imageUrl: url),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton.filled(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
