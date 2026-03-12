import 'dart:convert';

class Note {
  String id;
  String title;
  String content;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  factory Note.createNew() {
    final now = DateTime.now();
    return Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: '',
      content: '',
      updatedAt: now,
    );
  }

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        title: j['title'] as String,
        content: j['content'] as String,
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static List<Note> listFromJson(String jsonStr) {
    final list = json.decode(jsonStr) as List<dynamic>;
    return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<Note> notes) {
    final list = notes.map((e) => e.toJson()).toList();
    return json.encode(list);
  }
}
