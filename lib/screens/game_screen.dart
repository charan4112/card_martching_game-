import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'leaderboard_screen.dart'; // ✅ Correct Import

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameProvider>(context, listen: false).initializeCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Matching Game'),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (gameProvider.checkWinCondition())
            const Center(
              child: Text(
                '🎉 Congratulations! You won!',
                style: TextStyle(fontSize: 24, color: Colors.green),
              ),
            ),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaderboardScreen(),  // ✅ Corrected Constructor
                ),
              );
            },
            child: const Text('🏅 View Leaderboard'),
          ),

          ElevatedButton(
            onPressed: () => gameProvider.resetGame(),
            child: const Text('🔄 Restart Game'),
          ),
        ],
      ),
    );
  }
}
