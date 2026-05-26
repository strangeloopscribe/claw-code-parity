import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../widgets/family_avatar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarProvider);
    final eventsByDate = ref.watch(eventsByDateProvider);
    final selectedEvents = ref.watch(
        eventsForDayProvider(_selectedDay));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            onPressed: () => setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = DateTime.now();
            }),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(calendarProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final dateStr =
              '${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}';
          context.push('/calendar/event/new?date=$dateStr');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) => Column(
          children: [
            TableCalendar<Event>(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 730)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _format,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
                CalendarFormat.twoWeeks: '2 Weeks',
                CalendarFormat.week: 'Week',
              },
              eventLoader: (day) {
                final key =
                    DateTime(day.year, day.month, day.day);
                return eventsByDate[key] ?? [];
              },
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onFormatChanged: (f) => setState(() => _format = f),
              onPageChanged: (focused) =>
                  setState(() => _focusedDay = focused),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                todayTextStyle:
                    TextStyle(color: cs.onPrimaryContainer),
                markerDecoration: BoxDecoration(
                  color: cs.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonShowsNext: false,
                titleCentered: true,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _EventList(
                events: selectedEvents,
                selectedDay: _selectedDay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventList extends ConsumerWidget {
  const _EventList({required this.events, required this.selectedDay});

  final List<Event> events;
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyMembersProvider).value ?? [];
    final cs = Theme.of(context).colorScheme;

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_rounded,
                size: 48, color: cs.outlineVariant),
            const SizedBox(height: 8),
            Text('No events on ${DateFormat.MMMd().format(selectedDay)}',
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    return ListView.separated(
      padding:
          const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final event = events[i];
        final creator =
            members.where((m) => m.id == event.createdBy).firstOrNull;
        return _EventCard(event: event, creator: creator, ref: ref);
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard(
      {required this.event, required this.creator, required this.ref});

  final Event event;
  final dynamic creator;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeStr = event.allDay
        ? 'All day'
        : DateFormat.jm().format(event.startTime) +
            (event.endTime != null
                ? ' – ${DateFormat.jm().format(event.endTime!)}'
                : '');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/calendar/event/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: event.displayColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(timeStr,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                    if (event.location != null) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.place_outlined,
                            size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(event.location!,
                            style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12)),
                      ]),
                    ],
                  ],
                ),
              ),
              if (creator != null) FamilyAvatar(profile: creator, radius: 16),
            ],
          ),
        ),
      ),
    );
  }
}
