import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/game_state.dart';
import '../models/edge.dart';
import '../cpu/cpu_player.dart';
import 'board_painter.dart';

class GamePage extends StatefulWidget {
  final GameMode mode;

  const GamePage({super.key, required this.mode});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late GameState game;
  late CpuPlayer cpu;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    game = GameState(rows: 8, cols: 8);
    game.gameMode = widget.mode;
    cpu = CpuPlayer(game);
  }

  void _restartGame() {
    setState(() {
      _initGame();
    });
  }

  void _showGameOverDialog() {
    String title;
    String message;
    IconData icon;
    Color iconColor;

    if (game.player1Score > game.player2Score) {
      if (widget.mode == GameMode.cpu) {
        title = 'VITTORIA! 🎉';
        message = 'Hai battuto la CPU!';
      } else {
        title = 'Giocatore 1 Vince! 🎉';
        message = 'Complimenti al rosso!';
      }
      icon = Icons.emoji_events;
      iconColor = Colors.amber;
    } else if (game.player1Score < game.player2Score) {
      if (widget.mode == GameMode.cpu) {
        title = 'SCONFITTA 😢';
        message = 'La CPU ti ha battuto!';
      } else {
        title = 'Giocatore 2 Vince! 🎉';
        message = 'Complimenti al blu!';
      }
      icon = widget.mode == GameMode.cpu ? Icons.sentiment_dissatisfied : Icons.emoji_events;
      iconColor = widget.mode == GameMode.cpu ? Colors.grey : Colors.amber;
    } else {
      title = 'PAREGGIO! 🤝';
      message = 'Nessun vincitore questa volta.';
      icon = Icons.handshake;
      iconColor = Colors.orange;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(icon, size: 60, color: iconColor),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Punteggio Finale',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildScoreBox('Giocatore 1', game.player1Score, Colors.red),
                _buildScoreBox(
                  widget.mode == GameMode.cpu ? 'CPU' : 'Giocatore 2',
                  game.player2Score,
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(message, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _restartGame();
            },
            icon: const Icon(Icons.refresh, color: Colors.green),
            label: const Text('Gioca ancora', style: TextStyle(color: Colors.green)),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.home, color: Colors.white70),
            label: const Text('Menu', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBox(String label, int score, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            '$score',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  void _onTapDown(TapDownDetails details, Size size) {
    final currentIsHuman = game.currentPlayer == Player.human1 ||
        (widget.mode == GameMode.twoPlayers && game.currentPlayer == Player.human2);

    if (!currentIsHuman || game.isGameOver) return;

    final edge = _detectEdgeFromTap(details.localPosition, size);
    if (edge == null || edge.owner != null) return;

    final player = game.currentPlayer;
    final extraTurn = game.playEdge(edge, player);

    setState(() {});

    if (game.isGameOver) {
      Future.delayed(const Duration(milliseconds: 300), _showGameOverDialog);
      return;
    }

    if (!extraTurn && widget.mode == GameMode.cpu) {
      _playCpuTurn();
    }
  }

  void _playCpuTurn() async {
    await Future.delayed(const Duration(milliseconds: 500));

    while (game.currentPlayer == Player.cpu && !game.isGameOver) {
      // ← NUOVO: usa solo lati validi
      if (game.freeEdges.isEmpty) break;
      
      final edge = cpu.chooseMove();
      final extraTurn = game.playEdge(edge, Player.cpu);

      setState(() {});

      if (game.isGameOver) {
        Future.delayed(const Duration(milliseconds: 300), _showGameOverDialog);
        return;
      }

      if (!extraTurn) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }


  Edge? _detectEdgeFromTap(Offset pos, Size size) {
    final cellWidth = size.width / (game.cols + 1);
    final cellHeight = size.height / (game.rows + 1);
    const hitTolerance = 20.0;

    Edge? closest;
    double bestDist = double.infinity;

    // ← NUOVO: filtra solo lati validi e liberi
    for (final edge in game.edges.where((e) => e.isValid && e.owner == null)) {
      
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

      final dist = _distancePointToSegment(pos, p1, p2);
      if (dist < hitTolerance && dist < bestDist) {
        bestDist = dist;
        closest = edge;
      }
    }

    return closest;
  }


  double _distancePointToSegment(Offset p, Offset a, Offset b) {
    final ap = p - a;
    final ab = b - a;
    final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (ab2 == 0) return (p - a).distance;
    double t = (ap.dx * ab.dx + ap.dy * ab.dy) / ab2;
    t = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance;
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayerText = game.currentPlayer == Player.human1
        ? 'Giocatore 1 (Rosso)'
        : (widget.mode == GameMode.cpu ? 'CPU (Blu)' : 'Giocatore 2 (Blu)');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.mode == GameMode.cpu ? 'vs CPU' : '2 Giocatori'),
        backgroundColor: Colors.deepPurple.shade900,
        actions: [
          IconButton(
            onPressed: _restartGame,
            icon: const Icon(Icons.refresh),
            tooltip: 'Ricomincia',
          ),
        ],
      ),
      body: Column(
        children: [
          // Punteggio
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            color: Colors.grey.shade900,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPlayerScore('G1', game.player1Score, Colors.red,
                    game.currentPlayer == Player.human1),
                Text(
                  'vs',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                ),
                _buildPlayerScore(
                  widget.mode == GameMode.cpu ? 'CPU' : 'G2',
                  game.player2Score,
                  Colors.blue,
                  game.currentPlayer != Player.human1,
                ),
              ],
            ),
          ),

          // Griglia di gioco
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onTapDown: (details) => _onTapDown(details, size),
                    child: CustomPaint(
                      size: size,
                      painter: BoardPainter(game: game),
                    ),
                  );
                },
              ),
            ),
          ),

          // Indicatore turno
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade900,
            child: Text(
              game.isGameOver ? 'Partita terminata!' : 'Turno: $currentPlayerText',
              style: TextStyle(
                fontSize: 18,
                color: game.currentPlayer == Player.human1 ? Colors.red : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(String label, int score, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Text(
            '$score',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
