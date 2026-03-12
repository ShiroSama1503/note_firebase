import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';
import 'drawing_canvas.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;

  const NoteCard({super.key, required this.note, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

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
              if (note.hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    note.imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        alignment: Alignment.center,
                        color: const Color(0xFFF1F3F5),
                        child: const Text('Ảnh không khả dụng'),
                      );
                    },
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
