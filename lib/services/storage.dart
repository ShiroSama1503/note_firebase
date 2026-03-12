import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/note.dart';
import 'note_image_storage_service.dart';

class Storage {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _activeUserId;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  static final ValueNotifier<List<Note>> notesNotifier = ValueNotifier([]);

  static Future<void> init() async {
    notesNotifier.value = [];
  }

  static Future<void> setCurrentUser(String? userId) async {
    if (_activeUserId == userId) {
      return;
    }

    await _subscription?.cancel();
    _subscription = null;
    _activeUserId = userId;
    if (_activeUserId == null) {
      notesNotifier.value = [];
      return;
    }

    _subscription = _userNotesCollection.orderBy('updatedAt', descending: true).snapshots().listen(
      (snapshot) {
        notesNotifier.value = snapshot.docs
            .map((doc) => Note.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      onError: (_) {
        notesNotifier.value = [];
      },
    );
  }

  static CollectionReference<Map<String, dynamic>> get _userNotesCollection {
    return _firestore.collection('users').doc(_activeUserId).collection('notes');
  }

  static Future<void> addOrUpdate(Note note) async {
    if (_activeUserId == null) {
      return;
    }

    note.updatedAt = DateTime.now();
    await _userNotesCollection.doc(note.id).set(note.toFirestore());
  }

  static Future<void> delete(Note note) async {
    if (_activeUserId == null) {
      notesNotifier.value = [];
      return;
    }

    if (note.imagePath != null && note.imagePath!.isNotEmpty) {
      await NoteImageStorageService.deleteImage(note.imagePath!);
    }
    await _userNotesCollection.doc(note.id).delete();
  }

  static String messageFromException(Object error) {
    if (error is FirebaseException) {
      final message = error.message ?? '';
      if (message.contains('firestore.googleapis.com') || message.contains('Cloud Firestore API has not been used')) {
        return 'Cloud Firestore API của project chưa được bật. Vào Firebase Console hoặc Google Cloud Console để bật Firestore trước khi lưu ghi chú.';
      }

      switch (error.code) {
        case 'permission-denied':
          return 'Firestore đang từ chối quyền ghi dữ liệu. Hãy kiểm tra Firestore Rules.';
        case 'unavailable':
          return 'Firestore hiện chưa sẵn sàng hoặc mất kết nối. Hãy thử lại sau.';
        case 'failed-precondition':
          return 'Firestore chưa được cấu hình hoàn chỉnh cho project này.';
      }

      if (message.isNotEmpty) {
        return message;
      }
    }

    return error.toString().replaceFirst('Exception: ', '');
  }
}
