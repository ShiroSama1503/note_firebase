import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/note.dart';
import '../widgets/drawing_canvas.dart';
import '../services/storage.dart';
import 'drawing_board_screen.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  String? _imageBase64;
  late List<SketchStroke> _drawingStrokes;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note.title);
    _contentCtrl = TextEditingController(text: widget.note.content);
    _imageBase64 = widget.note.imageBase64;
    _drawingStrokes = List<SketchStroke>.from(widget.note.drawingStrokes);
  }

  Uint8List? get _imageBytes {
    final raw = _imageBase64;
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 75,
      );
      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _imageBase64 = base64Encode(bytes);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể chọn ảnh. Vui lòng thử lại.')),
      );
    }
  }

  Future<void> _openDrawingBoard() async {
    final result = await Navigator.push<List<SketchStroke>>(
      context,
      MaterialPageRoute(
        builder: (_) => DrawingBoardScreen(initialStrokes: _drawingStrokes),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _drawingStrokes = result;
    });
  }

  Future<void> _saveIfNeeded() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final hasMedia = (_imageBase64?.isNotEmpty ?? false) || _drawingStrokes.isNotEmpty;

    // Do not save if there is no text and no media.
    if (title.isEmpty && content.isEmpty && !hasMedia) {
      return;
    }

    widget.note.title = title;
    widget.note.content = content;
    widget.note.imageBase64 = _imageBase64;
    widget.note.drawingStrokes = List<SketchStroke>.from(_drawingStrokes);
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
    final imageBytes = _imageBytes;

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          return;
        }
        await _saveIfNeeded();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Soạn ghi chú'),
          actions: [
            IconButton(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              tooltip: 'Gắn ảnh',
            ),
            IconButton(
              onPressed: _openDrawingBoard,
              icon: const Icon(Icons.draw_outlined),
              tooltip: 'Bảng vẽ',
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Tiêu đề'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(imageBytes == null ? 'Thêm ảnh' : 'Đổi ảnh'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _openDrawingBoard,
                      icon: const Icon(Icons.brush_outlined),
                      label: Text(
                        _drawingStrokes.isEmpty ? 'Vẽ ghi chú' : 'Sửa bản vẽ',
                      ),
                    ),
                    if (imageBytes != null)
                      TextButton.icon(
                        onPressed: () => setState(() => _imageBase64 = null),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Xóa ảnh'),
                      ),
                    if (_drawingStrokes.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => setState(() => _drawingStrokes = []),
                        icon: const Icon(Icons.layers_clear_outlined),
                        label: const Text('Xóa bản vẽ'),
                      ),
                  ],
                ),
                if (imageBytes != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      imageBytes,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                if (_drawingStrokes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD3DAE3)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: DrawingCanvas(strokes: _drawingStrokes),
                      ),
                    ),
                  ),
                ],
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
