import 'package:flutter/material.dart';
import '../models/enums.dart';
import 'game_page.dart';

class PlayerNamesDialog extends StatefulWidget {
  final GameMode mode;

  const PlayerNamesDialog({super.key, required this.mode});

  @override
  State<PlayerNamesDialog> createState() => _PlayerNamesDialogState();
}

class _PlayerNamesDialogState extends State<PlayerNamesDialog> {
  final _player1Controller = TextEditingController(text: '');
  final _player2Controller = TextEditingController(text: '');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  void _startGame() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GamePage(
            mode: widget.mode,
            player1Name: _player1Controller.text.trim(),
            player2Name: _player2Controller.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.mode == GameMode.timedMode 
            ? 'Corsa contro il tempo' 
            : '2 Giocatori'),
        backgroundColor: Colors.deepPurple.shade900,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade900, Colors.black],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.mode == GameMode.timedMode 
                        ? Icons.timer 
                        : Icons.people,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Inserisci i nomi dei giocatori',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // Campo Giocatore 1
                  _buildPlayerInput(
                    controller: _player1Controller,
                    label: 'Giocatore 1',
                    icon: Icons.person,
                    color: Colors.red,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Campo Giocatore 2
                  _buildPlayerInput(
                    controller: _player2Controller,
                    label: 'Giocatore 2',
                    icon: Icons.person_outline,
                    color: Colors.blue,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Pulsante Inizia
                  ElevatedButton.icon(
                    onPressed: _startGame,
                    icon: const Icon(Icons.play_arrow, size: 28),
                    label: const Text(
                      'Inizia Partita',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 18,
                      ),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color),
        prefixIcon: Icon(icon, color: color),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color.withValues(alpha: 0.5), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Inserisci un nome';
        }
        if (value.trim().length > 15) {
          return 'Massimo 15 caratteri';
        }
        return null;
      },
      maxLength: 15,
    );
  }
}
