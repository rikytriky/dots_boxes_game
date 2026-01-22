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
  Edge? lastPlayedEdge;  

  // TIMER MODALITÀ CORSA CONTRO TEMPO
  bool isTimedMode = false;
  double timeLeft = 15.0;
  static double TURN_DURATION = 15.0;

  // Metodo per resettare timer
  void resetTimer() {
    timeLeft = TURN_DURATION;
  }

  // Metodo per aggiornare timer (chiamato ogni frame)
  void updateTimer(double deltaSeconds) {
    if (!isTimedMode) return;
    
    timeLeft -= deltaSeconds;
    
    if (timeLeft <= 0) {
      // Tempo scaduto: punto extra all'avversario
      _handleTimeout();
    }
  }

  void _handleTimeout() {
    // Punto extra al giocatore che NON ha il turno
    if (currentPlayer == Player.human1) {
      player2Score++;
    } else {
      player1Score++;
    }
    
    // resetta timer
    resetTimer();
  }

  GameState({this.rows = 8, this.cols = 8, double? turnDuration}) {
    if (turnDuration != null) {
      TURN_DURATION = turnDuration;
    }
    timeLeft = TURN_DURATION;
    _generateGrid();
  }

  void _generateGrid() {
    // 1. Inizializza TUTTE celle attive
    cells = List.generate(rows, (r) => 
      List.generate(cols, (c) => Cell(row: r, col: c, isActive: true))
    );

    final rand = Random();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        // Disattiva solo BORDI (non interne)
        final isBorder = r <= 0 || r >= rows-1 || c <= 0 || c >= cols-1;
        if (isBorder && rand.nextDouble() < 0.3) {
          cells[r][c].isActive = false;
        }
      }
    }

    // 2. RIGENERA edge DOPO
    _generateEdges();

    // 3. AGGIORNA isActive: cella valida = supportata da 4 edge
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final sides = _getFourSidesOfCell(r, c);
        final allSidesExist = sides.every((e) => e != null);
        cells[r][c].isActive = allSidesExist;
      }
    }

  }

  void _generateEdges() {
    edges = [];

    // === Lati ORIZZONTALI ===
    for (int r = 0; r <= rows; r++) {  // righe da 0 a rows
      for (int c = 0; c < cols; c++) {  // colonne da 0 a cols-1
        // Lato orizzontale esiste se supporta almeno una cella
        bool topCell = (r > 0) && cells[r - 1][c].isActive;
        bool bottomCell = (r < rows) && cells[r][c].isActive;
        
        if (topCell || bottomCell) {
          edges.add(Edge(
            row: r,
            col: c,  // ← COLONNA ESATTA della cella
            isHorizontal: true,
            isValid: true,
          ));
        }
      }
    }

    // === Lati VERTICALI ===
    for (int r = 0; r < rows; r++) {  // righe celle da 0 a rows-1
      for (int c = 0; c <= cols; c++) {  // colonne da 0 a cols
        // Lato verticale esiste se supporta almeno una cella
        bool leftCell = (c > 0) && cells[r][c - 1].isActive;
        bool rightCell = (c < cols) && cells[r][c].isActive;
        
        if (leftCell || rightCell) {
          edges.add(Edge(
            row: r,  // ← RIGA ESATTA della cella
            col: c,
            isHorizontal: false,
            isValid: true,
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
    lastPlayedEdge = edge;
    
    final closed = _checkClosedSquares(edge, player);  // ← Ora corretto
    resetTimer();
    if (closed == 0) {
      _nextPlayer();
      return false;
    }
    
    // ✅ TURNO EXTRA se ha chiuso almeno 1 quadrato
    return true;
  }

  void _nextPlayer() {
    if (gameMode == GameMode.twoPlayers || gameMode == GameMode.timedMode) {
      currentPlayer = currentPlayer == Player.human1 ? Player.human2 : Player.human1;
    } else {
      currentPlayer = currentPlayer == Player.human1 ? Player.cpu : Player.human1;
    }
  }


  /// FUNZIONE CORRETTA: controlla TUTTE le celle adiacenti all'edge
  int _checkClosedSquares(Edge edge, Player player) {
    int closed = 0;
    final List<Cell> adjacentCells = [];

    if (edge.isHorizontal) {
      // Edge ORIZZONTALE (row, col, true)
      // - Cella SOPRA: riga = edge.row - 1, colonna = edge.col
      // - Cella SOTTO: riga = edge.row, colonna = edge.col
      
      // Cella sopra
      int topRow = edge.row - 1;
      int topCol = edge.col;
      if (topRow >= 0 && topRow < rows && topCol >= 0 && topCol < cols) {
        final cell = cells[topRow][topCol];
        //if (cell.isActive) {
          adjacentCells.add(cell);
          //print('Edge H(${edge.row},${edge.col}) -> cella SOPRA ($topRow,$topCol)');
        //}
      }
      
      // Cella sotto
      int bottomRow = edge.row;
      int bottomCol = edge.col;
      if (bottomRow >= 0 && bottomRow < rows && bottomCol >= 0 && bottomCol < cols) {
        final cell = cells[bottomRow][bottomCol];
        //if (cell.isActive) {
          adjacentCells.add(cell);
          //print('Edge H(${edge.row},${edge.col}) -> cella SOTTO ($bottomRow,$bottomCol)');
        //}
      }
      
    } else {
      // Edge VERTICALE (row, col, false)
      // - Cella SINISTRA: riga = edge.row, colonna = edge.col - 1
      // - Cella DESTRA: riga = edge.row, colonna = edge.col
      
      // Cella sinistra
      int leftRow = edge.row;
      int leftCol = edge.col - 1;
      if (leftRow >= 0 && leftRow < rows && leftCol >= 0 && leftCol < cols) {
        final cell = cells[leftRow][leftCol];
        //if (cell.isActive) {
          adjacentCells.add(cell);
          //print('Edge V(${edge.row},${edge.col}) -> cella SINISTRA ($leftRow,$leftCol)');
        //}
      }
      
      // Cella destra
      int rightRow = edge.row;
      int rightCol = edge.col;
      if (rightRow >= 0 && rightRow < rows && rightCol >= 0 && rightCol < cols) {
        final cell = cells[rightRow][rightCol];
        //if (cell.isActive) {
          adjacentCells.add(cell);
          //print('Edge V(${edge.row},${edge.col}) -> cella DESTRA ($rightRow,$rightCol)');
        //}
      }
    }

    //print('Edge (${edge.row},${edge.col}, h=${edge.isHorizontal}) -> '
      //    'celle adiacenti trovate: ${adjacentCells.length}');

    // Controlla chiusura per ogni cella adiacente
    for (final cell in adjacentCells) {
      if (cell.owner != null) {
        //print('Cella (${cell.row},${cell.col}) già assegnata a ${cell.owner}');
        continue;
      }

      final wasClosed = isCellClosed(cell);
      //print('Check cella (${cell.row},${cell.col}) -> chiusa? $wasClosed');

      if (wasClosed) {
        cell.owner = player;
        closed++;

        // 🎬 AVVIA ANIMAZIONE PULSAZIONE
        cell.pulseScale = 1.3;
        cell.pulseOpacity = 0.4;
        cell.isAnimating = true;

        if (player == Player.human1) {
          player1Score++;
        } else {
          player2Score++;
        }
        //print('*** PUNTO per $player! Cella (${cell.row},${cell.col}) ***');
      }
    }

    //print('=== Edge (${edge.row},${edge.col}) ha chiuso $closed celle ===\n');
    return closed;
  }


  bool isCellClosed(Cell cell) {
    final r = cell.row;
    final c = cell.col;

    // I 4 lati della cella (r,c)
    final top = findEdge(r, c, true);         // sopra
    final bottom = findEdge(r + 1, c, true);  // sotto
    final left = findEdge(r, c, false);       // sinistra
    final right = findEdge(r, c + 1, false);  // destra

    // Debug dettagliato
    //print('isCellClosed($r,$c): '
      //    'top(${r},${c},H)=${top?.owner}, '
        //  'bottom(${r+1},${c},H)=${bottom?.owner}, '
          //'left(${r},${c},V)=${left?.owner}, '
          //'right(${r},${c+1},V)=${right?.owner}');

    // Se manca un lato, non chiusa
    if (top == null || bottom == null || left == null || right == null) {
     // print('  -> LATO MANCANTE!');
      return false;
    }

    // Tutti e 4 devono avere owner
    final closed = top.owner != null &&
                  bottom.owner != null &&
                  left.owner != null &&
                  right.owner != null;

    return closed;
  }

  Edge? findEdge(int row, int col, bool isHorizontal) {
    // Cerca edge con coordinate ESATTE per questo lato
    try {
      return edges.firstWhere(
        (e) => e.row == row && 
              e.col == col && 
              e.isHorizontal == isHorizontal &&
              e.isValid,
      );
    } catch (e) {
      return null;
    }
  }

  List<Edge?> _getFourSidesOfCell(int r, int c) {
    return [
      // TOP: orizzontale SOPRA la cella (riga r, colonna c)
      findEdge(r, c, true),
      
      // BOTTOM: orizzontale SOTTO la cella (riga r+1, colonna c)
      findEdge(r + 1, c, true),
      
      // LEFT: verticale SINISTRA della cella (riga r, colonna c)
      findEdge(r, c, false),
      
      // RIGHT: verticale DESTRA della cella (riga r, colonna c+1)
      findEdge(r, c + 1, false),
    ];
  }

  void updateAnimations() {
    bool hasAnimating = false;
    for (var row in cells) {
      for (var cell in row) {
        if (cell.isAnimating) {
          hasAnimating = true;
          // Fade out pulsazione
          cell.pulseOpacity *= 0.92;
          cell.pulseScale *= 0.96;
          
          if (cell.pulseScale < 1.01 && cell.pulseOpacity < 0.02) {
            cell.pulseScale = 1.0;
            cell.pulseOpacity = 0.0;
            cell.isAnimating = false;
          }
        }
      }
    }
    // Trigger repaint se animazioni attive
    if (hasAnimating) {
      // GamePage chiamerà setState()
    }
  }

  List<Edge> get freeEdges => edges.where((e) => e.isValid && e.owner == null).toList();
}
