import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/profile.dart';

class FamilyAvatar extends StatelessWidget {
  const FamilyAvatar({
    super.key,
    required this.profile,
    this.radius = 20,
  });

  final Profile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (profile.avatarUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(profile.avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: profile.flutterColor,
      child: Text(
        profile.initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
