import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/experience.dart';

/// All talking to Supabase happens here, so the screens stay simple.
class ExperienceService {
  ExperienceService._();
  static final ExperienceService instance = ExperienceService._();

  static const _bucket = 'experience-media';
  SupabaseClient get _db => Supabase.instance.client;

  final Map<String, (String, DateTime)> _urlCache = {};

  Future<List<Experience>> fetchAll() async {
    final rows = await _db
        .from('experiences')
        .select()
        .order('happened_on', ascending: false)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => Experience.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String title,
    required String body,
    required DateTime happenedOn,
    XFile? media,
    bool isVideo = false,
  }) async {
    final uid = _db.auth.currentUser!.id;
    String? path;
    String? type;

    if (media != null) {
      final name = media.name;
      final ext =
          name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
      path = '$uid/${const Uuid().v4()}.$ext';
      final bytes = await media.readAsBytes();
      await _db.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType:
                  media.mimeType ?? (isVideo ? 'video/mp4' : 'image/jpeg'),
            ),
          );
      type = isVideo ? 'video' : 'image';
    }

    await _db.from('experiences').insert({
      'user_id': uid,
      'title': title,
      'body': body,
      'happened_on': DateFormat('yyyy-MM-dd').format(happenedOn),
      'media_path': path,
      'media_type': type,
    });
  }

  Future<void> delete(Experience e) async {
    if (e.hasMedia) {
      await _db.storage.from(_bucket).remove([e.mediaPath!]);
    }
    await _db.from('experiences').delete().eq('id', e.id);
  }

  /// The bucket is private, so media is shown through short-lived signed links.
  Future<String> signedUrl(String path) async {
    final cached = _urlCache[path];
    if (cached != null &&
        DateTime.now().difference(cached.$2) < const Duration(minutes: 50)) {
      return cached.$1;
    }
    final url = await _db.storage.from(_bucket).createSignedUrl(path, 3600);
    _urlCache[path] = (url, DateTime.now());
    return url;
  }
}
