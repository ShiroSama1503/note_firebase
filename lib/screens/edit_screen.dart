import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/storage.dart';

class EditScreen extends StatefulWidget {
  final Note note;
  final bool isNew;
  const EditScreen({super.key, required this.note, this.isNew = false});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note.title);
    _contentCtrl = TextEditingController(text: widget.note.content);
  }

  Future<void> _saveIfNeeded() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    // Do not save if both title and content are empty
    if (title.isEmpty && content.isEmpty) {
      return;
    }

    widget.note.title = title;
    widget.note.content = content;
    await Storage.addOrUpdate(widget.note);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveIfNeeded();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Soạn ghi chú'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Tiêu đề'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    controller: _contentCtrl,
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Viết nội dung...'),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    expands: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
