class Family {
  const Family({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;

  factory Family.fromJson(Map<String, dynamic> json) => Family(
        id: json['id'] as String,
        name: json['name'] as String,
        inviteCode: json['invite_code'] as String,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
