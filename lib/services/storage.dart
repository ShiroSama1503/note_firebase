import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class Storage {
  static const _key = 'notes_v1';
  static late SharedPreferences _prefs;
  static final ValueNotifier<List<Note>> notesNotifier = ValueNotifier([]);

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
  }

  static void _load() {
    final raw = _prefs.getString(_key);
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
    final raw = Note.listToJson(notesNotifier.value);
    await _prefs.setString(_key, raw);
    notesNotifier.notifyListeners();
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
