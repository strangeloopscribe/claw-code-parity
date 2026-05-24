import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define when building:
  //   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  //               --dart-define=SUPABASE_ANON_KEY=eyJ...
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(const ProviderScope(child: FamilyHubApp()));
}
