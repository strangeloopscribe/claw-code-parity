import 'package:flutter/material.dart';

class Event {
  const Event({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.title,
    this.description,
    this.location,
    required this.startTime,
    this.endTime,
    this.allDay = false,
    this.color,
  });

  final String id;
  final String familyId;
  final String createdBy;
  final String title;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime? endTime;
  final bool allDay;
  final String? color;

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        createdBy: json['created_by'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        startTime: DateTime.parse(json['start_time'] as String).toLocal(),
        endTime: json['end_time'] != null
            ? DateTime.parse(json['end_time'] as String).toLocal()
            : null,
        allDay: (json['all_day'] as bool?) ?? false,
        color: json['color'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'family_id': familyId,
        'created_by': createdBy,
        'title': title,
        'description': description,
        'location': location,
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime?.toUtc().toIso8601String(),
        'all_day': allDay,
        'color': color,
      };

  Color get displayColor {
    if (color == null) return const Color(0xFFFF7043);
    final hex = color!.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  bool get isSameDay {
    if (endTime == null) return true;
    final s = startTime;
    final e = endTime!;
    return s.year == e.year && s.month == e.month && s.day == e.day;
  }
}
