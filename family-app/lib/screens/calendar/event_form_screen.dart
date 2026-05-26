import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/calendar_provider.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.eventId, this.initialDate});

  final String? eventId;
  final DateTime? initialDate;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  late DateTime _startDate;
  late TimeOfDay _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _allDay = false;
  String _color = '#FF7043';
  bool _loading = false;
  Event? _existing;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate ?? DateTime.now();
    _startTime = TimeOfDay.fromDateTime(_startDate);
    _endDate = _startDate;
    _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute);
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (widget.eventId == null) return;
    final events = ref.read(calendarProvider).value ?? [];
    final match =
        events.where((e) => e.id == widget.eventId).firstOrNull;
    if (match == null) return;
    setState(() {
      _existing = match;
      _titleCtrl.text = match.title;
      _descCtrl.text = match.description ?? '';
      _locationCtrl.text = match.location ?? '';
      _startDate = match.startTime;
      _startTime = TimeOfDay.fromDateTime(match.startTime);
      _allDay = match.allDay;
      if (match.endTime != null) {
        _endDate = match.endTime;
        _endTime = TimeOfDay.fromDateTime(match.endTime!);
      }
      _color = match.color ?? '#FF7043';
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : (_endTime ?? _startTime),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final family = await ref.read(familyProvider.future);
      final user = Supabase.instance.client.auth.currentUser!;
      final start = _allDay ? _startDate : _combine(_startDate, _startTime);
      final end = _allDay
          ? null
          : (_endDate != null && _endTime != null
              ? _combine(_endDate!, _endTime!)
              : null);

      final data = {
        'family_id': family!.id,
        'created_by': user.id,
        'title': _titleCtrl.text.trim(),
        'description':
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        'start_time': start.toUtc().toIso8601String(),
        'end_time': end?.toUtc().toIso8601String(),
        'all_day': _allDay,
        'color': _color,
      };

      final notifier = ref.read(calendarProvider.notifier);
      if (_existing != null) {
        await notifier.updateEvent(_existing!.id, data);
      } else {
        await notifier.addEvent(data);
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete event?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(calendarProvider.notifier).deleteEvent(_existing!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existing != null;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Event' : 'New Event'),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    height: 16, width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Event title',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('All day'),
              value: _allDay,
              onChanged: (v) => setState(() => _allDay = v),
            ),
            const SizedBox(height: 8),
            // Start date/time
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(DateFormat.MMMd().format(_startDate)),
                  onPressed: () => _pickDate(true),
                ),
              ),
              if (!_allDay) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time_outlined),
                    label: Text(_startTime.format(context)),
                    onPressed: () => _pickTime(true),
                  ),
                ),
              ],
            ]),
            if (!_allDay) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                        _endDate != null ? DateFormat.MMMd().format(_endDate!) : 'End date'),
                    onPressed: () => _pickDate(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time_outlined),
                    label: Text(_endTime?.format(context) ?? 'End time'),
                    onPressed: () => _pickTime(false),
                  ),
                ),
              ]),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            Text('Color', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppTheme.memberColors.map((c) {
                final hex =
                    '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
                final selected = hex == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: cs.onSurface, width: 3)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
