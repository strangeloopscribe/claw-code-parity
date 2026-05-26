import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/family_list.dart';
import '../../models/list_item.dart';
import '../../providers/lists_provider.dart';

class ListDetailScreen extends ConsumerStatefulWidget {
  const ListDetailScreen({super.key, required this.listId});

  final String listId;

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  final _addCtrl = TextEditingController();
  bool _showCompleted = true;

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final text = _addCtrl.text.trim();
    if (text.isEmpty) return;
    _addCtrl.clear();
    final items = ref.read(listItemsProvider(widget.listId)).value ?? [];
    await ListItemsNotifier.addItem(
      listId: widget.listId,
      text: text,
      position: items.length,
    );
  }

  Future<void> _toggle(ListItem item) async {
    await ListItemsNotifier.toggleItem(
      id: item.id,
      completed: !item.completed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(listItemsProvider(widget.listId));
    final listsAsync = ref.watch(listsProvider);
    final FamilyList? list = listsAsync.value
        ?.where((l) => l.id == widget.listId)
        .firstOrNull;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(list?.name ?? 'List'),
        actions: [
          itemsAsync.maybeWhen(
            data: (items) {
              final hasCompleted = items.any((i) => i.completed);
              return Row(
                children: [
                  IconButton(
                    icon: Icon(_showCompleted
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    tooltip:
                        _showCompleted ? 'Hide completed' : 'Show completed',
                    onPressed: () =>
                        setState(() => _showCompleted = !_showCompleted),
                  ),
                  if (hasCompleted)
                    IconButton(
                      icon: Icon(Icons.cleaning_services_outlined,
                          color: cs.error),
                      tooltip: 'Clear completed',
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Clear completed items?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Clear')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await ListItemsNotifier.clearCompleted(widget.listId);
                        }
                      },
                    ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add item bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addCtrl,
                    decoration: InputDecoration(
                      hintText: list?.listType == ListType.todo
                          ? 'Add a task…'
                          : 'Add an item…',
                      prefixIcon: const Icon(Icons.add_rounded),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addItem(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addItem,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48)),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: itemsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                final pending =
                    items.where((i) => !i.completed).toList();
                final done =
                    items.where((i) => i.completed).toList();
                final visible = [
                  ...pending,
                  if (_showCompleted) ...done,
                ];

                if (visible.isEmpty && pending.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.done_all_rounded,
                            size: 56, color: cs.outlineVariant),
                        const SizedBox(height: 8),
                        Text('All done!',
                            style:
                                Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                }

                if (visible.isEmpty) {
                  return const Center(
                      child: Text('Add your first item above'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visible.length,
                  itemBuilder: (context, i) =>
                      _ItemTile(item: visible[i], onToggle: _toggle),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.onToggle});

  final ListItem item;
  final Future<void> Function(ListItem) onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Slidable(
      key: ValueKey(item.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => ListItemsNotifier.deleteItem(item.id),
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
          ),
        ],
      ),
      child: ListTile(
        leading: Checkbox(
          value: item.completed,
          onChanged: (_) => onToggle(item),
          shape: const CircleBorder(),
        ),
        title: Text(
          item.text,
          style: item.completed
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: cs.onSurfaceVariant,
                )
              : null,
        ),
        onTap: () => onToggle(item),
      ),
    );
  }
}
