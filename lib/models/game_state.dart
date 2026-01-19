import 'dart:math';
import 'enums.dart';
import 'cell.dart';
import 'edge.dart';

class GameState {
  final int rows;
  final int cols;
  late List<List<Cell>> cells;
  late List<Edge> edges;
  Player currentPlayer = Player.human1;
  GameMode gameMode = GameMode.cpu;
  int player1Score = 0;
  int player2Score = 0;

  GameState({this.rows = 8, this.cols = 8}) {
    _generateGrid();
    _generateEdges();
  }

  void _generateGrid() {
    final rand = Random();
    cells = List.generate(
      rows,
      (r) => List.generate(
        cols,
        (c) => Cell(row: r, col: c, isActive: true),
      ),
    );

    // Irregolarità: 25% bordi, 10% interno per griglia grande
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final isBorder = r == 0 || r == rows - 1 || c == 0 || c == cols - 1;
        final deactivateChance = isBorder ? 0.25 : 0.10;  // ← PIÙ IRREGOLARE
        if (rand.nextDouble() < deactivateChance) {
          cells[r][c].isActive = false;
        }
      }
    }
  }


  void _generateEdges() {
    edges = [];

    // Lati orizzontali
    for (var r = 0; r <= rows; r++) {
      for (var c = 0; c < cols; c++) {
        bool topActive = r > 0 && cells[r - 1][c].isActive;
        bool bottomActive = r < rows && cells[r][c].isActive;
        
        if (topActive || bottomActive) {
          // Lato valido solo se supporta almeno una cella attiva
          bool isValidEdge = topActive || bottomActive;
          edges.add(Edge(
            row: r, 
            col: c, 
            isHorizontal: true,
            isValid: isValidEdge,
          ));
        }
      }
    }

    // Lati verticali
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c <= cols; c++) {
        bool leftActive = c > 0 && cells[r][c - 1].isActive;
        bool rightActive = c < cols && cells[r][c].isActive;
        
        if (leftActive || rightActive) {
          bool isValidEdge = leftActive || rightActive;
          edges.add(Edge(
            row: r, 
            col: c, 
            isHorizontal: false,
            isValid: isValidEdge,
          ));
        }
      }
    }
  }

  bool get isGameOver => edges.every((e) => e.owner != null);

  bool canPlayHuman(Player player) {
    if (isGameOver) return false;
    if (gameMode == GameMode.twoPlayers) {
      return currentPlayer == player;
    } else {
      return currentPlayer == Player.human1;
    }
  }

  bool playEdge(Edge edge, Player player) {
    if (edge.owner != null || !edge.isValid) return false;
    
    edge.owner = player;
    
    final closed = _checkClosedSquares(edge, player);  // ← Ora corretto
    
    if (closed == 0) {
      _nextPlayer();
      return false;
    }
    
    // ✅ TURNO EXTRA se ha chiuso almeno 1 quadrato
    return true;
  }

  void _nextPlayer() {
    if (gameMode == GameMode.twoPlayers) {
      currentPlayer = currentPlayer == Player.human1 ? Player.human2 : Player.human1;
    } else {
      currentPlayer = currentPlayer == Player.human1 ? Player.cpu : Player.human1;
    }
  }

  /// FUNZIONE CORRETTA: controlla TUTTE le celle adiacenti all'edge
  int _checkClosedSquares(Edge edge, Player player) {
    int closed = 0;
    
    // Per ogni edge, controlla fino a 4 celle potenzialmente influenzate
    List<List<int>> candidateCells = [];
    
    if (edge.isHorizontal) {
      // Lato orizzontale: controlla celle sopra e sotto
      if (edge.row > 0) {
        candidateCells.add([edge.row - 1, edge.col]);  // cella sopra
      }
      if (edge.row < rows) {
        candidateCells.add([edge.row, edge.col]);      // cella sotto
      }
    } else {
      // Lato verticale: controlla celle sinistra e destra
      if (edge.col > 0) {
        candidateCells.add([edge.row, edge.col - 1]);  // cella sinistra
      }
      if (edge.col < cols) {
        candidateCells.add([edge.row, edge.col]);      // cella destra
      }
    }
    
    // Per ogni cella candidata, verifica se è stata chiusa DA QUESTA mossa
    for (final cellPos in candidateCells) {
      final r = cellPos[0];
      final c = cellPos[1];
      
      if (r < 0 || r >= rows || c < 0 || c >= cols) continue;
      final cell = cells[r][c];
      
      if (!cell.isActive) continue;
      
      // ✅ VERIFICA: quadrato chiuso SOLO DOPO questa mossa
      if (isCellClosed(cell) && cell.owner == null) {
        cell.owner = player;
        closed++;
        
        // Assegna punti
        if (player == Player.human1) {
          player1Score++;
        } else {
          player2Score++;
        }
      }
    }
    
    return closed;
  }


  bool isCellClosed(Cell cell) {
    final r = cell.row;
    final c = cell.col;
    
    final sides = _getFourSidesOfCell(r, c);
    
    // DEBUG: stampa per verificare
    // print('Cell $r,$c sides: ${sides.map((e) => e?.owner ?? 'null').toList()}');
    
    // TUTTI i 4 lati devono esistere e avere owner
    bool allExist = sides.every((e) => e != null);
    bool allOwned = allExist && sides.every((e) => e!.owner != null);
    
    return allExist && allOwned;
  }


  Edge? findEdge(int row, int col, bool isHorizontal) {
    try {
      return edges.firstWhere(
        (e) => e.row == row && e.col == col && e.isHorizontal == isHorizontal,
      );
    } catch (e) {
      return null;
    }
  }

  /// Ritorna i 4 edge di una cella (o null se non esistono)
  List<Edge?> _getFourSidesOfCell(int r, int c) {
    return [
      // Top
      findEdge(r, c, true),
      // Bottom  
      findEdge(r + 1, c, true),
      // Left
      findEdge(r, c, false),
      // Right
      findEdge(r, c + 1, false),
    ];
  }


  List<Edge> get freeEdges => edges.where((e) => e.isValid && e.owner == null).toList();
}
