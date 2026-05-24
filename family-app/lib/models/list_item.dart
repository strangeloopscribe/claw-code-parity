class ListItem {
  const ListItem({
    required this.id,
    required this.listId,
    required this.addedBy,
    required this.text,
    this.completed = false,
    this.completedBy,
    this.completedAt,
    this.position = 0,
    required this.createdAt,
  });

  final String id;
  final String listId;
  final String addedBy;
  final String text;
  final bool completed;
  final String? completedBy;
  final DateTime? completedAt;
  final int position;
  final DateTime createdAt;

  factory ListItem.fromJson(Map<String, dynamic> json) => ListItem(
        id: json['id'] as String,
        listId: json['list_id'] as String,
        addedBy: json['added_by'] as String,
        text: json['text'] as String,
        completed: (json['completed'] as bool?) ?? false,
        completedBy: json['completed_by'] as String?,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        position: (json['position'] as int?) ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'list_id': listId,
        'added_by': addedBy,
        'text': text,
        'completed': completed,
        'completed_by': completedBy,
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'position': position,
      };

  ListItem copyWith({bool? completed, String? completedBy, DateTime? completedAt}) {
    return ListItem(
      id: id,
      listId: listId,
      addedBy: addedBy,
      text: text,
      completed: completed ?? this.completed,
      completedBy: completedBy ?? this.completedBy,
      completedAt: completedAt ?? this.completedAt,
      position: position,
      createdAt: createdAt,
    );
  }
}
