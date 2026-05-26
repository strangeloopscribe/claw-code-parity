class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.familyId,
    required this.createdBy,
    this.title,
    this.body,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrls = const [],
  });

  final String id;
  final String familyId;
  final String createdBy;
  final String? title;
  final String? body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> photoUrls; // public URLs from Supabase Storage

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        createdBy: json['created_by'] as String,
        title: json['title'] as String?,
        body: json['body'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
        photoUrls: (json['journal_photos'] as List<dynamic>?)
                ?.map((p) => p['storage_path'] as String)
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'family_id': familyId,
        'created_by': createdBy,
        'title': title,
        'body': body,
      };

  bool get hasPhotos => photoUrls.isNotEmpty;
  String get displayTitle => title?.isNotEmpty == true ? title! : 'Memory';
}
