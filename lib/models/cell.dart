import 'enums.dart';

class Cell {
  final int row;
  final int col;
  bool isActive;
  Player? owner;

  Cell({
    required this.row,
    required this.col,
    this.isActive = true,
    this.owner,
  });
}
