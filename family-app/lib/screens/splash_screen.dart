import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _checkOnboarding(context, ref);
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _checkOnboarding(BuildContext context, WidgetRef ref) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!context.mounted) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go('/auth/login');
      return;
    }

    final profile = await ref.read(profileProvider.future);
    if (!context.mounted) return;
    if (profile == null) {
      context.go('/auth/profile-setup');
      return;
    }

    final family = await ref.read(familyProvider.future);
    if (!context.mounted) return;
    if (family == null) {
      context.go('/auth/family-setup');
      return;
    }

    context.go('/calendar');
  }
}
