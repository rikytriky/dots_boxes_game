import 'package:flutter/material.dart';
import '../models/enums.dart';
import 'game_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade900, Colors.black],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.grid_4x4, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Gioco dei Quadrati',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Dots & Boxes Irregolare',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 60),
              _buildMenuButton(
                context,
                'Giocatore vs CPU',
                Icons.smart_toy,
                GameMode.cpu,
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                '2 Giocatori',
                Icons.people,
                GameMode.twoPlayers,
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                'Corsa contro il tempo ⏱️',  // ← NUOVO
                Icons.timer,
                GameMode.timedMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    IconData icon,
    GameMode mode,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GamePage(mode: mode)),
        );
      },
      icon: Icon(icon, size: 28),
      label: Text(text, style: const TextStyle(fontSize: 20)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
