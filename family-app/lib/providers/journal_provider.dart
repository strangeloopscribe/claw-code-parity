import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';
import 'auth_provider.dart';

final _client = Supabase.instance.client;
const _uuid = Uuid();

class JournalNotifier extends StateNotifier<AsyncValue<List<JournalEntry>>> {
  JournalNotifier(this.ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref ref;

  Future<void> _load() async {
    try {
      final family = await ref.read(familyProvider.future);
      if (family == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final data = await _client
          .from('journal_entries')
          .select('*, journal_photos(storage_path)')
          .eq('family_id', family.id)
          .order('created_at', ascending: false);

      state = AsyncValue.data(
        (data as List<dynamic>).map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<JournalEntry> createEntry({
    required String? title,
    required String? body,
    required List<File> photos,
  }) async {
    final family = await ref.read(familyProvider.future);
    final user = _client.auth.currentUser!;

    final result = await _client
        .from('journal_entries')
        .insert({
          'family_id': family!.id,
          'created_by': user.id,
          'title': title,
          'body': body,
        })
        .select()
        .single();

    final entry = JournalEntry.fromJson({...result, 'journal_photos': []});

    // Upload photos
    for (final photo in photos) {
      await _uploadPhoto(entry.id, photo);
    }

    await _load();
    return entry;
  }

  Future<void> updateEntry({
    required String id,
    required String? title,
    required String? body,
    required List<File> newPhotos,
  }) async {
    await _client.from('journal_entries').update({
      'title': title,
      'body': body,
    }).eq('id', id);

    for (final photo in newPhotos) {
      await _uploadPhoto(id, photo);
    }

    await _load();
  }

  Future<void> deleteEntry(String id) async {
    await _client.from('journal_entries').delete().eq('id', id);
    await _load();
  }

  Future<void> deletePhoto(String entryId, String storagePath) async {
    await _client.storage.from('journal-photos').remove([storagePath]);
    await _client
        .from('journal_photos')
        .delete()
        .eq('entry_id', entryId)
        .eq('storage_path', storagePath);
    await _load();
  }

  Future<void> _uploadPhoto(String entryId, File photo) async {
    final ext = photo.path.split('.').last;
    final path = '${entryId}/${_uuid.v4()}.$ext';

    await _client.storage.from('journal-photos').upload(path, photo);

    await _client.from('journal_photos').insert({
      'entry_id': entryId,
      'storage_path': path,
    });
  }

  String photoUrl(String storagePath) {
    return _client.storage
        .from('journal-photos')
        .getPublicUrl(storagePath);
  }

  Future<void> refresh() => _load();
}

final journalProvider =
    StateNotifierProvider<JournalNotifier, AsyncValue<List<JournalEntry>>>(
  (ref) => JournalNotifier(ref),
);
