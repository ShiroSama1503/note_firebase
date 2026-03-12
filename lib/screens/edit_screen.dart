import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/note_image_storage_service.dart';
import '../services/storage.dart';
import '../widgets/drawing_canvas.dart';
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
  Uint8List? _pendingImageBytes;
  String? _imageUrl;
  String? _imagePath;
  late List<SketchStroke> _drawingStrokes;
  bool _removeCurrentImage = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note.title);
    _contentCtrl = TextEditingController(text: widget.note.content);
    _imageUrl = widget.note.imageUrl;
    _imagePath = widget.note.imagePath;
    _drawingStrokes = List<SketchStroke>.from(widget.note.drawingStrokes);
  }

  bool get _hasExistingImage =>
      !_removeCurrentImage && _imageUrl != null && _imageUrl!.isNotEmpty;

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
        _pendingImageBytes = bytes;
        _removeCurrentImage = false;
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
    if (_isSaving) {
      return;
    }

    _isSaving = true;
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final hasMedia = _pendingImageBytes != null || _hasExistingImage || _drawingStrokes.isNotEmpty;

    // Do not save if there is no text and no media.
    if (title.isEmpty && content.isEmpty && !hasMedia) {
      _isSaving = false;
      return;
    }

    try {
      final userId = AuthService.currentUser?.uid;
      if (userId == null) {
        throw Exception('Bạn cần đăng nhập lại để lưu ghi chú.');
      }

      String? nextImageUrl = _imageUrl;
      String? nextImagePath = _imagePath;

      if (_pendingImageBytes != null) {
        final uploaded = await NoteImageStorageService.uploadImage(
          bytes: _pendingImageBytes!,
          userId: userId,
          noteId: widget.note.id,
        );
        if (_imagePath != null && _imagePath != uploaded.path) {
          await NoteImageStorageService.deleteImage(_imagePath!);
        }
        nextImageUrl = uploaded.publicUrl;
        nextImagePath = uploaded.path;
      } else if (_removeCurrentImage && _imagePath != null) {
        await NoteImageStorageService.deleteImage(_imagePath!);
        nextImageUrl = null;
        nextImagePath = null;
      }

      widget.note.title = title;
      widget.note.content = content;
      widget.note.imageUrl = nextImageUrl;
      widget.note.imagePath = nextImagePath;
      widget.note.drawingStrokes = List<SketchStroke>.from(_drawingStrokes);
      await Storage.addOrUpdate(widget.note);

      _imageUrl = nextImageUrl;
      _imagePath = nextImagePath;
      _pendingImageBytes = null;
      _removeCurrentImage = false;
    } finally {
      _isSaving = false;
    }
  }

  Future<void> _handleClose() async {
    if (_isSaving) {
      return;
    }

    try {
      await _saveIfNeeded();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Storage.messageFromException(error))),
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = _pendingImageBytes;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleClose();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Soạn ghi chú'),
          leading: IconButton(
            onPressed: _handleClose,
            icon: const Icon(Icons.arrow_back),
          ),
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
                      label: Text((imageBytes == null && !_hasExistingImage) ? 'Thêm ảnh' : 'Đổi ảnh'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _openDrawingBoard,
                      icon: const Icon(Icons.brush_outlined),
                      label: Text(
                        _drawingStrokes.isEmpty ? 'Vẽ ghi chú' : 'Sửa bản vẽ',
                      ),
                    ),
                    if (imageBytes != null || _hasExistingImage)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _pendingImageBytes = null;
                          _removeCurrentImage = true;
                        }),
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
                ] else if (_hasExistingImage) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _imageUrl!,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          alignment: Alignment.center,
                          color: const Color(0xFFF1F3F5),
                          child: const Text('Không tải được ảnh từ storage'),
                        );
                      },
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
