import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class Storage {
  static const _keyPrefix = 'notes_v1';
  static late SharedPreferences _prefs;
  static String? _activeUserId;
  static final ValueNotifier<List<Note>> notesNotifier = ValueNotifier([]);

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    notesNotifier.value = [];
  }

  static Future<void> setCurrentUser(String? userId) async {
    if (_activeUserId == userId) {
      return;
    }
    _activeUserId = userId;
    _load();
  }

  static String get _storageKey => '$_keyPrefix:${_activeUserId ?? 'signed_out'}';

  static void _load() {
    if (_activeUserId == null) {
      notesNotifier.value = [];
      return;
    }

    final raw = _prefs.getString(_storageKey);
    if (raw == null) {
      notesNotifier.value = [];
      return;
    }
    try {
      notesNotifier.value = Note.listFromJson(raw);
    } catch (_) {
      notesNotifier.value = [];
    }
  }

  static Future<void> _save() async {
    if (_activeUserId == null) {
      return;
    }
    final raw = Note.listToJson(notesNotifier.value);
    await _prefs.setString(_storageKey, raw);
  }

  static Future<void> addOrUpdate(Note note) async {
    final list = List<Note>.from(notesNotifier.value);
    final idx = list.indexWhere((n) => n.id == note.id);
    note.updatedAt = DateTime.now();
    if (idx == -1) {
      list.insert(0, note);
    } else {
      list[idx] = note;
      // move to top
      final n = list.removeAt(idx);
      list.insert(0, n);
    }
    notesNotifier.value = list;
    await _save();
  }

  static Future<void> delete(String id) async {
    final list = List<Note>.from(notesNotifier.value);
    list.removeWhere((n) => n.id == id);
    notesNotifier.value = list;
    await _save();
  }
}
