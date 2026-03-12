import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class UploadedNoteImage {
  final String path;
  final String publicUrl;

  const UploadedNoteImage({
    required this.path,
    required this.publicUrl,
  });
}

class NoteImageStorageService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<UploadedNoteImage> uploadImage({
    required Uint8List bytes,
    required String userId,
    required String noteId,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'notes/$userId/$noteId/$fileName';

    await _client.storage.from(SupabaseConfig.bucketName).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'image/jpeg',
      ),
    );

    final publicUrl = _client.storage.from(SupabaseConfig.bucketName).getPublicUrl(path);
    return UploadedNoteImage(path: path, publicUrl: publicUrl);
  }

  static Future<void> deleteImage(String path) async {
    if (path.isEmpty) {
      return;
    }

    await _client.storage.from(SupabaseConfig.bucketName).remove([path]);
  }
}