import 'package:flutter/material.dart';
import '../models/edge.dart';
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
      ..color = Colors.grey.withValues(alpha: 0.4)
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

    final lastMovePaint = Paint()
      ..color = Colors.yellowAccent
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = Colors.grey.shade300.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Disegna quadrati chiusi
    for (var r = 0; r < game.rows; r++) {
      for (var c = 0; c < game.cols; c++) {
        final cell = game.cells[r][c];
        
        if (cell.owner != null) {
          // TUE coordinate esatte
          final baseLeft = (c + 0.5) * cellWidth;
          final baseTop = (r + 0.5) * cellHeight;
          final baseWidth = cellWidth;
          final baseHeight = cellHeight;
          
          // Applica pulsazione mantenendo centro
          final scaledWidth = baseWidth * cell.pulseScale;
          final scaledHeight = baseHeight * cell.pulseScale;
          
          // Offset per mantenere centro fisso
          final offsetX = (baseWidth - scaledWidth) / 2;
          final offsetY = (baseHeight - scaledHeight) / 2;
          
          final scaledRect = Rect.fromLTWH(
            baseLeft + offsetX,         // ← centro orizzontale
            baseTop + offsetY,          // ← centro verticale
            scaledWidth,
            scaledHeight,
          );

          final fillPaint = Paint()
            ..color = (cell.owner == Player.human1 
                ? Colors.red 
                : Colors.blue)
              .withValues(alpha: 0.3 + cell.pulseOpacity) // ← pulsazione brillante
            ..style = PaintingStyle.fill;
            
          canvas.drawRect(scaledRect, fillPaint);

          /*final fillPaint = Paint()
            ..color = cell.owner == Player.human1
                ? Colors.red.withOpacity(0.3)
                : Colors.blue.withOpacity(0.3)
            ..style = PaintingStyle.fill;

          canvas.drawRect(rect, fillPaint);*/
        } else {
          if (!cell.isActive) {
            final rect = Rect.fromLTWH(
              (c + 0.5) * cellWidth,
              (r + 0.5) * cellHeight,
              cellWidth,
              cellHeight,
            );
            canvas.drawRect(rect, inactivePaint);
          }
        }
      }
    }

    // 1) Disegna tutti i lati normalmente
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

      final segment = _edgeToSegment(edge, cellWidth, cellHeight);
      canvas.drawLine(segment.$1, segment.$2, paint);
    }

    // 2) Disegna per ultimo l'ULTIMA MOSSA, sopra gli altri
    final last = game.lastPlayedEdge;
    if (last != null) {
      final segment = _edgeToSegment(last, cellWidth, cellHeight);
      canvas.drawLine(segment.$1, segment.$2, lastMovePaint);
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

  (Offset, Offset) _edgeToSegment(Edge edge, double cellWidth, double cellHeight) {
    if (edge.isHorizontal) {
      final y = (edge.row + 0.5) * cellHeight;
      final x1 = (edge.col + 0.5) * cellWidth;
      final x2 = (edge.col + 1.5) * cellWidth;
      return (Offset(x1, y), Offset(x2, y));
    } else {
      final x = (edge.col + 0.5) * cellWidth;
      final y1 = (edge.row + 0.5) * cellHeight;
      final y2 = (edge.row + 1.5) * cellHeight;
      return (Offset(x, y1), Offset(x, y2));
    }
  }


  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}
