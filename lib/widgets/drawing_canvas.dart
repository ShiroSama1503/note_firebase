import 'package:flutter/material.dart';

import '../models/note.dart';

class DrawingCanvas extends StatelessWidget {
  final List<SketchStroke> strokes;
  final SketchStroke? activeStroke;
  final Color strokeColor;
  final double strokeWidth;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    this.activeStroke,
    this.strokeColor = Colors.black,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DrawingCanvasPainter(
        strokes: strokes,
        activeStroke: activeStroke,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DrawingCanvasPainter extends CustomPainter {
  final List<SketchStroke> strokes;
  final SketchStroke? activeStroke;
  final Color strokeColor;
  final double strokeWidth;

  const _DrawingCanvasPainter({
    required this.strokes,
    required this.activeStroke,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFFE7EBF0)
      ..strokeWidth = 1;
    const gridSize = 24.0;

    for (double dx = 0; dx <= size.width; dx += gridSize) {
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (double dy = 0; dy <= size.height; dy += gridSize) {
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }
    if (activeStroke != null) {
      _drawStroke(canvas, activeStroke!, paint);
    }
  }

  void _drawStroke(Canvas canvas, SketchStroke stroke, Paint paint) {
    if (stroke.points.isEmpty) {
      return;
    }

    if (stroke.points.length == 1) {
      final point = stroke.points.first;
      canvas.drawCircle(
        Offset(point.x, point.y),
        strokeWidth / 2,
        Paint()..color = strokeColor,
      );
      return;
    }

    final path = Path()..moveTo(stroke.points.first.x, stroke.points.first.y);
    for (final point in stroke.points.skip(1)) {
      path.lineTo(point.x, point.y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingCanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.activeStroke != activeStroke ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}