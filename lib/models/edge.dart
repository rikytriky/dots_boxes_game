import 'enums.dart';

class Edge {
  final int row;
  final int col;
  final bool isHorizontal;
  final bool isValid;
  Player? owner;

  Edge({
    required this.row,
    required this.col,
    required this.isHorizontal,
    required this.isValid,
    this.owner,
  });
}
