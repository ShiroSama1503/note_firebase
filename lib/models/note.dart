import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class SketchPoint {
  final double x;
  final double y;

  const SketchPoint({required this.x, required this.y});

  factory SketchPoint.fromJson(Map<String, dynamic> json) => SketchPoint(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
      };
}

class SketchStroke {
  final List<SketchPoint> points;

  const SketchStroke({required this.points});

  factory SketchStroke.fromJson(Map<String, dynamic> json) => SketchStroke(
        points: (json['points'] as List<dynamic>)
            .map((point) => SketchPoint.fromJson(point as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'points': points.map((point) => point.toJson()).toList(),
      };
}

class Note {
  String id;
  String title;
  String content;
  DateTime updatedAt;
  String? imageUrl;
  String? imagePath;
  List<SketchStroke> drawingStrokes;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.imageUrl,
    this.imagePath,
    List<SketchStroke>? drawingStrokes,
  }) : drawingStrokes = drawingStrokes ?? [];

  Note._internal({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.imageUrl,
    this.imagePath,
    required this.drawingStrokes,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get hasDrawing => drawingStrokes.isNotEmpty;

  bool get hasMedia => hasImage || hasDrawing;

  factory Note.createNew() {
    final now = DateTime.now();
    return Note._internal(
      id: now.millisecondsSinceEpoch.toString(),
      title: '',
      content: '',
      updatedAt: now,
      drawingStrokes: const [],
    );
  }

  factory Note.fromJson(Map<String, dynamic> j) => Note._internal(
        id: j['id'] as String,
        title: j['title'] as String,
        content: j['content'] as String,
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        imageUrl: j['imageUrl'] as String?,
        imagePath: j['imagePath'] as String?,
        drawingStrokes: (j['drawingStrokes'] as List<dynamic>? ?? const [])
            .map((stroke) => SketchStroke.fromJson(stroke as Map<String, dynamic>))
            .toList(),
      );

  factory Note.fromFirestore(Map<String, dynamic> j, String fallbackId) =>
      Note._internal(
        id: (j['id'] as String?) ?? fallbackId,
        title: (j['title'] as String?) ?? '',
        content: (j['content'] as String?) ?? '',
        updatedAt: _readDateTime(j['updatedAt']),
        imageUrl: j['imageUrl'] as String?,
        imagePath: j['imagePath'] as String?,
        drawingStrokes: (j['drawingStrokes'] as List<dynamic>? ?? const [])
            .map((stroke) => SketchStroke.fromJson(stroke as Map<String, dynamic>))
            .toList(),
      );

  static DateTime _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'updatedAt': updatedAt.toIso8601String(),
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'drawingStrokes': drawingStrokes.map((stroke) => stroke.toJson()).toList(),
      };

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'title': title,
        'content': content,
        'updatedAt': Timestamp.fromDate(updatedAt),
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'drawingStrokes': drawingStrokes.map((stroke) => stroke.toJson()).toList(),
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
