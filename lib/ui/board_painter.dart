import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/enums.dart';

class BoardPainter extends CustomPainter {
  final GameState game;

  BoardPainter({required this.game});

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / (game.cols + 1);
    final cellHeight = size.height / (game.rows + 1);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final freeEdgePaint = Paint()
      ..color = Colors.grey.withOpacity(0.4)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final player1EdgePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final player2EdgePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    // Disegna quadrati chiusi
    for (var r = 0; r < game.rows; r++) {
      for (var c = 0; c < game.cols; c++) {
        final cell = game.cells[r][c];
        if (!cell.isActive) continue;

        if (cell.owner != null) {
          final rect = Rect.fromLTWH(
            (c + 0.5) * cellWidth,
            (r + 0.5) * cellHeight,
            cellWidth,
            cellHeight,
          );

          final fillPaint = Paint()
            ..color = cell.owner == Player.human1
                ? Colors.red.withOpacity(0.3)
                : Colors.blue.withOpacity(0.3)
            ..style = PaintingStyle.fill;

          canvas.drawRect(rect, fillPaint);
        }
      }
    }

    // Disegna lati
    for (final edge in game.edges) {
      if (!edge.isValid) continue;

      Paint paint;
      if (edge.owner == null) {
        paint = freeEdgePaint;
      } else if (edge.owner == Player.human1) {
        paint = player1EdgePaint;
      } else {
        paint = player2EdgePaint;
      }

      Offset p1, p2;
      if (edge.isHorizontal) {
        final y = (edge.row + 0.5) * cellHeight;
        final x1 = (edge.col + 0.5) * cellWidth;
        final x2 = (edge.col + 1.5) * cellWidth;
        p1 = Offset(x1, y);
        p2 = Offset(x2, y);
      } else {
        final x = (edge.col + 0.5) * cellWidth;
        final y1 = (edge.row + 0.5) * cellHeight;
        final y2 = (edge.row + 1.5) * cellHeight;
        p1 = Offset(x, y1);
        p2 = Offset(x, y2);
      }

      canvas.drawLine(p1, p2, paint);
    }

    // Disegna SOLO punti che supportano lati validi
    Set<Offset> visibleDots = {};
    for (final edge in game.edges) {
      if (!edge.isValid) continue;
      
      Offset p1, p2;
      if (edge.isHorizontal) {
        final y = (edge.row + 0.5) * cellHeight;
        final x1 = (edge.col + 0.5) * cellWidth;
        final x2 = (edge.col + 1.5) * cellWidth;
        p1 = Offset(x1, y);
        p2 = Offset(x2, y);
      } else {
        final x = (edge.col + 0.5) * cellWidth;
        final y1 = (edge.row + 0.5) * cellHeight;
        final y2 = (edge.row + 1.5) * cellHeight;
        p1 = Offset(x, y1);
        p2 = Offset(x, y2);
      }
      
      visibleDots.add(p1);
      visibleDots.add(p2);
    }

    // Disegna solo punti visibili
    for (final dot in visibleDots) {
      canvas.drawCircle(dot, 6, dotPaint);
    }

  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}
