import 'enums.dart';

class Cell {
  final int row;
  final int col;
  bool isActive;
  Player? owner;
  
  // NUOVO: per animazione pulsazione
  double pulseScale = 1.0;     // scala 1.0 → 1.3 → 1.0
  double pulseOpacity = 0.0;   // opacità extra 0 → 0.3 → 0
  bool isAnimating = false;    // flag animazione attiva

  Cell({
    required this.row,
    required this.col,
    this.isActive = true,
    this.owner,
    this.pulseScale = 1.0,
    this.pulseOpacity = 0.0,
    this.isAnimating = false,
  });
}

