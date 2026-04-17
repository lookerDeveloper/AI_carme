import 'package:flutter/material.dart';
import '../../domain/entities/camera_enums.dart';

class GridOverlay extends StatelessWidget {
  final GridType gridType;
  final Color lineColor;

  const GridOverlay({
    super.key,
    required this.gridType,
    this.lineColor = Colors.white30,
  });

  @override
  Widget build(BuildContext context) {
    if (gridType == GridType.none) return const SizedBox.shrink();

    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(gridType: gridType, lineColor: lineColor),
    );
  }
}

class _GridPainter extends CustomPainter {
  final GridType gridType;
  final Color lineColor;

  _GridPainter({required this.gridType, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    switch (gridType) {
      case GridType.ruleOfThirds:
        _drawRuleOfThirds(canvas, size, paint);
        break;
      case GridType.goldenRatio:
        _drawGoldenRatio(canvas, size, paint);
        break;
      case GridType.symmetry:
        _drawSymmetry(canvas, size, paint);
        break;
      case GridType.none:
        break;
    }
  }

  void _drawRuleOfThirds(Canvas canvas, Size size, Paint paint) {
    final thirdW = size.width / 3;
    final thirdH = size.height / 3;

    for (int i = 1; i <= 2; i++) {
      canvas.drawLine(
        Offset(thirdW * i, 0),
        Offset(thirdW * i, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, thirdH * i),
        Offset(size.width, thirdH * i),
        paint,
      );
    }
  }

  void _drawGoldenRatio(Canvas canvas, Size size, Paint paint) {
    const phi = 0.618;
    final w1 = size.width * phi;
    final w2 = size.width * (1 - phi);
    final h1 = size.height * phi;
    final h2 = size.height * (1 - phi);

    canvas.drawLine(Offset(w1, 0), Offset(w1, size.height), paint);
    canvas.drawLine(Offset(w2, 0), Offset(w2, size.height), paint);
    canvas.drawLine(Offset(0, h1), Offset(size.width, h1), paint);
    canvas.drawLine(Offset(0, h2), Offset(size.width, h2), paint);
  }

  void _drawSymmetry(Canvas canvas, Size size, Paint paint) {
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    final diagonalPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset.zero, Offset(size.width, size.height), diagonalPaint);
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      diagonalPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
