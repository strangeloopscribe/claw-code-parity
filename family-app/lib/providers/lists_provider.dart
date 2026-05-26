import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_list.dart';
import '../models/list_item.dart';
import 'auth_provider.dart';

final _client = Supabase.instance.client;

class ListsNotifier extends StateNotifier<AsyncValue<List<FamilyList>>> {
  ListsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref ref;

  Future<void> _load() async {
    try {
      final family = await ref.read(familyProvider.future);
      if (family == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final data = await _client
          .from('lists')
          .select()
          .eq('family_id', family.id)
          .order('created_at', ascending: false);

      final lists = (data as List<dynamic>)
          .map((e) => FamilyList.fromJson(e))
          .toList();

      // Fetch item counts
      final withCounts = await Future.wait(lists.map((l) async {
        final counts = await _client
            .from('list_items')
            .select('completed')
            .eq('list_id', l.id);
        final items = counts as List<dynamic>;
        final total = items.length;
        final done = items.where((i) => i['completed'] == true).length;
        return l.copyWith(itemCount: total, completedCount: done);
      }));

      state = AsyncValue.data(withCounts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createList({
    required String name,
    required ListType type,
    required String color,
  }) async {
    final family = await ref.read(familyProvider.future);
    final user = _client.auth.currentUser!;
    await _client.from('lists').insert({
      'family_id': family!.id,
      'created_by': user.id,
      'name': name,
      'list_type': type == ListType.todo ? 'todo' : 'shopping',
      'color': color,
    });
    await _load();
  }

  Future<void> deleteList(String id) async {
    await _client.from('lists').delete().eq('id', id);
    await _load();
  }

  Future<void> refresh() => _load();
}

final listsProvider =
    StateNotifierProvider<ListsNotifier, AsyncValue<List<FamilyList>>>(
  (ref) => ListsNotifier(ref),
);

// Real-time stream of items for a specific list
final listItemsProvider = StreamProvider.family<List<ListItem>, String>(
  (ref, listId) {
    return _client
        .from('list_items')
        .stream(primaryKey: ['id'])
        .eq('list_id', listId)
        .order('position')
        .map((rows) => rows.map(ListItem.fromJson).toList());
  },
);

class ListItemsNotifier {
  static Future<void> addItem({
    required String listId,
    required String text,
    required int position,
  }) async {
    final user = _client.auth.currentUser!;
    await _client.from('list_items').insert({
      'list_id': listId,
      'added_by': user.id,
      'text': text,
      'position': position,
    });
  }

  static Future<void> toggleItem({
    required String id,
    required bool completed,
  }) async {
    final user = _client.auth.currentUser!;
    await _client.from('list_items').update({
      'completed': completed,
      'completed_by': completed ? user.id : null,
      'completed_at':
          completed ? DateTime.now().toUtc().toIso8601String() : null,
    }).eq('id', id);
  }

  static Future<void> deleteItem(String id) async {
    await _client.from('list_items').delete().eq('id', id);
  }

  static Future<void> clearCompleted(String listId) async {
    await _client
        .from('list_items')
        .delete()
        .eq('list_id', listId)
        .eq('completed', true);
  }
}
