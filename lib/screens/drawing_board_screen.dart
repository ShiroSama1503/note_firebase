import 'package:flutter/material.dart';

import '../models/note.dart';
import '../widgets/drawing_canvas.dart';

class DrawingBoardScreen extends StatefulWidget {
  final List<SketchStroke> initialStrokes;

  const DrawingBoardScreen({
    super.key,
    required this.initialStrokes,
  });

  @override
  State<DrawingBoardScreen> createState() => _DrawingBoardScreenState();
}

class _DrawingBoardScreenState extends State<DrawingBoardScreen> {
  late final List<SketchStroke> _strokes;
  List<SketchPoint> _activePoints = [];

  @override
  void initState() {
    super.initState();
    _strokes = widget.initialStrokes
        .map(
          (stroke) => SketchStroke(
            points: stroke.points
                .map((point) => SketchPoint(x: point.x, y: point.y))
                .toList(),
          ),
        )
        .toList();
  }

  void _startStroke(Offset position) {
    setState(() {
      _activePoints = [SketchPoint(x: position.dx, y: position.dy)];
    });
  }

  void _appendStroke(Offset position) {
    setState(() {
      _activePoints = [
        ..._activePoints,
        SketchPoint(x: position.dx, y: position.dy),
      ];
    });
  }

  void _endStroke() {
    if (_activePoints.isEmpty) {
      return;
    }

    setState(() {
      _strokes.add(SketchStroke(points: List<SketchPoint>.from(_activePoints)));
      _activePoints = [];
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _activePoints = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeStroke = _activePoints.isEmpty
        ? null
        : SketchStroke(points: _activePoints);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng vẽ'),
        actions: [
          TextButton(
            onPressed: _clear,
            child: const Text('Xóa hết'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _strokes),
            child: const Text('Lưu'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vẽ trực tiếp lên bảng, rồi bấm Lưu để gắn vào ghi chú.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD3DAE3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) => _startStroke(details.localPosition),
                      onPanUpdate: (details) => _appendStroke(details.localPosition),
                      onPanEnd: (_) => _endStroke(),
                      onPanCancel: _endStroke,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DrawingCanvas(
                            strokes: _strokes,
                            activeStroke: activeStroke,
                          ),
                          if (_strokes.isEmpty && activeStroke == null)
                            Center(
                              child: Text(
                                'Chạm và kéo để bắt đầu vẽ',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.black54,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}