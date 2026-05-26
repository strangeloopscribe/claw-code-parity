import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(journalProvider);
    final notifier = ref.read(journalProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(journalProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/journal/new'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New Memory'),
      ),
      body: journalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_album_outlined,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12),
                  Text('No memories yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Capture your family moments',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 80),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: entries.length,
            itemBuilder: (context, i) => _EntryCard(
              entry: entries[i],
              notifier: notifier,
            ),
          );
        },
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.notifier});

  final JournalEntry entry;
  final JournalNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasPhoto = entry.hasPhotos;
    final photoUrl = hasPhoto
        ? notifier.photoUrl(entry.photoUrls.first)
        : null;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/journal/${entry.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: hasPhoto
                    ? CachedNetworkImage(
                        imageUrl: photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: cs.surfaceVariant,
                          child: const Center(
                              child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) =>
                            _placeholder(cs),
                      )
                    : _placeholder(cs),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat.MMMd().format(entry.createdAt),
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      color: cs.surfaceVariant,
      child: Center(
        child: Icon(Icons.photo_outlined,
            size: 40, color: cs.onSurfaceVariant),
      ),
    );
  }
}
