import 'package:flutter/material.dart';

class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.color,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String color;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        color: (json['color'] as String?) ?? '#FF7043',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'color': color,
      };

  Color get flutterColor {
    final hex = color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return displayName.substring(0, displayName.length.clamp(0, 2)).toUpperCase();
  }

  Profile copyWith({String? displayName, String? avatarUrl, String? color}) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      color: color ?? this.color,
    );
  }
}
