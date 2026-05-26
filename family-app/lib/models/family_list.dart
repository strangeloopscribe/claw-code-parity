import 'package:flutter/material.dart';

enum ListType { shopping, todo }

class FamilyList {
  const FamilyList({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.name,
    required this.listType,
    required this.color,
    required this.createdAt,
    this.itemCount = 0,
    this.completedCount = 0,
  });

  final String id;
  final String familyId;
  final String createdBy;
  final String name;
  final ListType listType;
  final String color;
  final DateTime createdAt;
  final int itemCount;
  final int completedCount;

  factory FamilyList.fromJson(Map<String, dynamic> json) => FamilyList(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        createdBy: json['created_by'] as String,
        name: json['name'] as String,
        listType: (json['list_type'] as String?) == 'todo'
            ? ListType.todo
            : ListType.shopping,
        color: (json['color'] as String?) ?? '#26A69A',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'family_id': familyId,
        'created_by': createdBy,
        'name': name,
        'list_type': listType == ListType.todo ? 'todo' : 'shopping',
        'color': color,
      };

  Color get displayColor {
    final hex = color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  IconData get icon =>
      listType == ListType.shopping ? Icons.shopping_cart_rounded : Icons.checklist_rounded;

  FamilyList copyWith({int? itemCount, int? completedCount}) => FamilyList(
        id: id,
        familyId: familyId,
        createdBy: createdBy,
        name: name,
        listType: listType,
        color: color,
        createdAt: createdAt,
        itemCount: itemCount ?? this.itemCount,
        completedCount: completedCount ?? this.completedCount,
      );
}
