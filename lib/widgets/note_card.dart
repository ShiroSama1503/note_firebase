import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';
import 'drawing_canvas.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;

  const NoteCard({super.key, required this.note, this.onTap});

  Uint8List? get _imageBytes {
    if (!note.hasImage) {
      return null;
    }

    try {
      return base64Decode(note.imageBase64!);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final imageBytes = _imageBytes;

    return Material(
      color: Theme.of(context).cardColor,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    imageBytes,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
              ] else if (note.hasDrawing) ...[
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DrawingCanvas(strokes: note.drawingStrokes),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                note.title.isEmpty ? '(Không có tiêu đề)' : note.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (note.hasImage || note.hasDrawing) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (note.hasImage)
                      const Chip(
                        label: Text('Ảnh'),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (note.hasDrawing)
                      const Chip(
                        label: Text('Bản vẽ'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                note.content.isEmpty ? 'Ghi chú có tệp đính kèm.' : note.content,
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  fmt.format(note.updatedAt),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
