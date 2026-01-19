import 'dart:math';
import '../models/game_state.dart';
import '../models/edge.dart';
import '../models/cell.dart';

class CpuPlayer {
  final GameState game;
  final Random _rand = Random();

  CpuPlayer(this.game);

  Edge chooseMove() {
    final freeEdges = game.freeEdges;
    if (freeEdges.isEmpty) {
      throw Exception('Nessuna mossa disponibile');
    }

    // 1. PRIORITÀ MASSIMA: mosse che chiudono quadrati
    var closingMoves = _evaluateClosingMoves(freeEdges);
    closingMoves.sort((a, b) => b.score.compareTo(a.score));  // ← CORRETTO
    
    if (closingMoves.isNotEmpty) {
      return closingMoves.first.edge;
    }

    // 2. Mosse sicure (evita regalare quadrati)
    var safeMoves = freeEdges.where((e) => !_wouldGiftDoubleSquares(e)).toList();
    
    if (safeMoves.isNotEmpty) {
      var futureSafe = _evaluateFutureMoves(safeMoves);
      futureSafe.sort((a, b) => b.score.compareTo(a.score));  // ← CORRETTO
      return futureSafe.first.edge;
    }

    // 3. Mossa casuale
    return freeEdges[_rand.nextInt(freeEdges.length)];
  }

  /// VALUTAZIONE CHIUSURA QUADRATI
  List<_MoveEval> _evaluateClosingMoves(List<Edge> freeEdges) {
    List<_MoveEval> results = [];
    
    for (final edge in freeEdges) {
      int potentialSquares = 0;  // ← DEFINITO QUI
      
      final adjacentCells = _getAdjacentCells(edge);
      
      for (final cell in adjacentCells) {
        if (_isCellAlmostClosed(cell, edge)) {
          potentialSquares++;
        }
      }
      
      if (potentialSquares > 0) {
        results.add(_MoveEval(edge, potentialSquares));
      }
    }
    
    return results;
  }

  /// STRATEGIA FUTURA
  List<_MoveEval> _evaluateFutureMoves(List<Edge> freeEdges) {
    List<_MoveEval> results = [];
    
    for (final edge in freeEdges) {
      int futureScore = 0;  // ← DEFINITO QUI
      
      // +3 se crea cella con 2 lati
      final adjacentCells = _getAdjacentCells(edge);
      for (final cell in adjacentCells) {
        if (_wouldCreateTwoSides(cell, edge)) {
          futureScore += 3;
        }
      }
      
      // -5 se lascia cella con 3 lati
      if (_wouldLeaveThreeSides(edge)) {
        futureScore -= 5;
      }
      
      // +1 posizione centrale
      if (_isCentralEdge(edge)) {
        futureScore += 1;
      }
      
      results.add(_MoveEval(edge, futureScore));
    }
    
    return results;
  }

  /// Cella ha esattamente 3 lati completati (pronta da chiudere)
  bool _isCellAlmostClosed(Cell cell, Edge excludeEdge) {
    final r = cell.row;
    final c = cell.col;
    
    int ownedSides = 0;
    final sides = [
      [r, c, true],     // top
      [r + 1, c, true], // bottom
      [r, c, false],    // left
      [r, c + 1, false], // right
    ];
    
    for (final side in sides) {
      final row = side[0] as int;
      final col = side[1] as int;
      final isHorizontal = side[2] as bool;
      
      // Salta l'edge simulato
      if (row == excludeEdge.row && 
          col == excludeEdge.col && 
          isHorizontal == excludeEdge.isHorizontal) {
        continue;
      }
      
      final edge = game.findEdge(row, col, isHorizontal);
      if (edge != null && edge.owner != null) {
        ownedSides++;
      }
    }
    
    return ownedSides == 3;
  }

  /// Crea cella con esattamente 2 lati (buona posizione futura)
  bool _wouldCreateTwoSides(Cell cell, Edge edge) {
    final r = cell.row;
    final c = cell.col;
    
    int currentSides = 0;
    final sides = [
      [r, c, true],
      [r + 1, c, true],
      [r, c, false],
      [r, c + 1, false],
    ];
    
    for (final side in sides) {
      final row = side[0] as int;
      final col = side[1] as int;
      final isHorizontal = side[2] as bool;
      
      final thisEdge = game.findEdge(row, col, isHorizontal);
      if (thisEdge != null && thisEdge.owner != null) {
        currentSides++;
      }
    }
    
    // Dopo mossa: current + 1 == 2?
    return currentSides == 1;
  }

  /// Posizione centrale (strategica)
  bool _isCentralEdge(Edge edge) {
    return edge.row >= 1 && edge.row <= game.rows - 2 &&
           edge.col >= 1 && edge.col <= game.cols - 2;
  }

  /// Celle adiacenti valide
  List<Cell> _getAdjacentCells(Edge edge) {
    List<Cell> cells = [];
    
    if (edge.isHorizontal) {
      if (edge.row > 0 && edge.row - 1 < game.rows) {
        cells.add(game.cells[edge.row - 1][edge.col]);
      }
      if (edge.row < game.rows) {
        cells.add(game.cells[edge.row][edge.col]);
      }
    } else {
      if (edge.col > 0 && edge.col - 1 < game.cols) {
        cells.add(game.cells[edge.row][edge.col - 1]);
      }
      if (edge.col < game.cols) {
        cells.add(game.cells[edge.row][edge.col]);
      }
    }
    
    return cells.where((c) => c.isActive).toList();
  }

  /// Lascia cella con 3 lati all'avversario
  bool _wouldLeaveThreeSides(Edge edge) {
    for (final cell in _getAdjacentCells(edge)) {
      int sidesAfterMove = 0;
      final r = cell.row;
      final c = cell.col;
      
      if (game.findEdge(r, c, true)?.owner != null) sidesAfterMove++;
      if (game.findEdge(r + 1, c, true)?.owner != null) sidesAfterMove++;
      if (game.findEdge(r, c, false)?.owner != null) sidesAfterMove++;
      if (game.findEdge(r, c + 1, false)?.owner != null) sidesAfterMove++;
      
      if (sidesAfterMove == 2) return true;  // Dopo mossa diventa 3
    }
    return false;
  }

  /// Evita regalare 2+ quadrati
  bool _wouldGiftDoubleSquares(Edge edge) {
    int riskyCells = 0;
    for (final cell in _getAdjacentCells(edge)) {
      if (_isCellAlmostClosed(cell, edge)) {
        riskyCells++;
      }
    }
    return riskyCells >= 2;
  }
}

/// Classe helper corretta
class _MoveEval {
  final Edge edge;
  final int score;  // ← UNICO campo ora

  _MoveEval(this.edge, this.score);

  @override
  String toString() => 'Edge(${edge.row},${edge.col},H:${edge.isHorizontal}) score:$score';
}
