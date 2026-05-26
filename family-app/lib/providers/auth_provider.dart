import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family.dart';
import '../models/profile.dart';

final _client = Supabase.instance.client;

final authStateProvider = StreamProvider<AuthState>((ref) {
  return _client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return _client.auth.currentUser;
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final data = await _client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  return data != null ? Profile.fromJson(data) : null;
});

final familyProvider = FutureProvider<Family?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final data = await _client
      .from('family_members')
      .select('family_id, families(*)')
      .eq('profile_id', user.id)
      .maybeSingle();

  if (data == null) return null;
  return Family.fromJson(data['families'] as Map<String, dynamic>);
});

final familyMembersProvider = FutureProvider<List<Profile>>((ref) async {
  final family = await ref.watch(familyProvider.future);
  if (family == null) return [];

  final data = await _client
      .from('family_members')
      .select('profiles(*)')
      .eq('family_id', family.id);

  return (data as List<dynamic>)
      .map((m) => Profile.fromJson(m['profiles'] as Map<String, dynamic>))
      .toList();
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _client.auth.signUp(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (_) => AuthNotifier(),
);

Future<void> createProfile({
  required String userId,
  required String displayName,
  required String color,
}) async {
  await _client.from('profiles').upsert({
    'id': userId,
    'display_name': displayName,
    'color': color,
  });
}

Future<Family> createFamily(String name) async {
  final user = _client.auth.currentUser!;
  final result = await _client
      .from('families')
      .insert({'name': name, 'created_by': user.id})
      .select()
      .single();

  final family = Family.fromJson(result);

  await _client.from('family_members').insert({
    'family_id': family.id,
    'profile_id': user.id,
    'role': 'admin',
  });

  return family;
}

Future<Family> joinFamily(String inviteCode) async {
  final user = _client.auth.currentUser!;

  final data = await _client
      .from('families')
      .select()
      .eq('invite_code', inviteCode.toUpperCase())
      .maybeSingle();

  if (data == null) throw Exception('Invalid invite code');

  final family = Family.fromJson(data);

  await _client.from('family_members').upsert({
    'family_id': family.id,
    'profile_id': user.id,
    'role': 'member',
  });

  return family;
}
