import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/family_list.dart';
import '../../providers/lists_provider.dart';
import '../../providers/auth_provider.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(listsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(listsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New List'),
      ),
      body: listsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lists) {
          if (lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt_rounded,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12),
                  Text('No lists yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Create a shopping or to-do list',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 80),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: lists.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ListCard(list: lists[i]),
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    ListType type = ListType.shopping;
    String color = '#26A69A';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New List', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'List name',
                  prefixIcon: Icon(Icons.list_rounded),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<ListType>(
                segments: const [
                  ButtonSegment(
                    value: ListType.shopping,
                    label: Text('Shopping'),
                    icon: Icon(Icons.shopping_cart_outlined),
                  ),
                  ButtonSegment(
                    value: ListType.todo,
                    label: Text('To-Do'),
                    icon: Icon(Icons.checklist_outlined),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (s) => setModal(() => type = s.first),
              ),
              const SizedBox(height: 16),
              Text('Color',
                  style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: AppTheme.memberColors.map((c) {
                  final hex =
                      '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
                  final selected = hex == color;
                  return GestureDetector(
                    onTap: () => setModal(() => color = hex),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(
                                color:
                                    Theme.of(ctx).colorScheme.onSurface,
                                width: 2)
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await ref.read(listsProvider.notifier).createList(
                        name: nameCtrl.text.trim(),
                        type: type,
                        color: color,
                      );
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );

    nameCtrl.dispose();
  }
}

class _ListCard extends ConsumerWidget {
  const _ListCard({required this.list});

  final FamilyList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final progress = list.itemCount > 0
        ? list.completedCount / list.itemCount
        : 0.0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/lists/${list.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: list.displayColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(list.icon, color: list.displayColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      list.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${list.completedCount}/${list.itemCount}',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant),
                ],
              ),
              if (list.itemCount > 0) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  color: list.displayColor,
                  backgroundColor: list.displayColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
