import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';
import 'auth_provider.dart';

final _client = Supabase.instance.client;

// All events for the family, grouped by date string (yyyy-MM-dd)
class CalendarNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  CalendarNotifier(this.ref) : super(const AsyncValue.loading()) {
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

      // Load 6 months back and 12 months forward
      final from = DateTime.now().subtract(const Duration(days: 180));
      final to = DateTime.now().add(const Duration(days: 365));

      final data = await _client
          .from('events')
          .select()
          .eq('family_id', family.id)
          .gte('start_time', from.toUtc().toIso8601String())
          .lte('start_time', to.toUtc().toIso8601String())
          .order('start_time');

      state = AsyncValue.data(
        (data as List<dynamic>).map((e) => Event.fromJson(e)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEvent(Map<String, dynamic> json) async {
    await _client.from('events').insert(json);
    await _load();
  }

  Future<void> updateEvent(String id, Map<String, dynamic> json) async {
    await _client.from('events').update(json).eq('id', id);
    await _load();
  }

  Future<void> deleteEvent(String id) async {
    await _client.from('events').delete().eq('id', id);
    await _load();
  }

  Future<void> refresh() => _load();
}

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, AsyncValue<List<Event>>>(
  (ref) => CalendarNotifier(ref),
);

// Events for a specific day — derived from calendarProvider
final eventsForDayProvider = Provider.family<List<Event>, DateTime>((ref, day) {
  final events = ref.watch(calendarProvider).value ?? [];
  return events.where((e) {
    final d = e.startTime;
    return d.year == day.year && d.month == day.month && d.day == day.day;
  }).toList();
});

// Map of date → events, for the calendar dot markers
final eventsByDateProvider = Provider<Map<DateTime, List<Event>>>((ref) {
  final events = ref.watch(calendarProvider).value ?? [];
  final map = <DateTime, List<Event>>{};
  for (final e in events) {
    final key = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
    map.putIfAbsent(key, () => []).add(e);
  }
  return map;
});
