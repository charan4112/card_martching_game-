import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Matching Game - In Progress'),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
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
                        ? Image.network(card.imageUrl)
                        : const Icon(Icons.question_mark, size: 36, color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
