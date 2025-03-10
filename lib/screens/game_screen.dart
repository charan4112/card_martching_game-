import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/card_model.dart';

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
          // Score & Moves Display
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Score: ${gameProvider.score} | Moves: ${gameProvider.moves} | Lives: ${gameProvider.lives}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Game Board
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: gameProvider.cards.length,
              itemBuilder: (context, index) {
                final card = gameProvider.cards[index];

                return GestureDetector(
                  onTap: () => gameProvider.flipCard(card),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: card.isFlipped
                          ? Colors.orangeAccent
                          : Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: card.isFlipped
                        ? Image.asset(card.imagePath)
                        : const Icon(Icons.question_mark, size: 36, color: Colors.white),
                  ),
                );
              },
            ),
          ),

          // Restart Button
          ElevatedButton(
            onPressed: () {
              gameProvider.resetGame();
            },
            child: const Text('Restart Game'),
          ),
        ],
      ),
    );
  }
}
