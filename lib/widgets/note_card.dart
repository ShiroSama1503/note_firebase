import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';

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
              Text(
                note.title.isEmpty ? '(Không có tiêu đề)' : note.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                note.content,
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  fmt.format(note.updatedAt),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
