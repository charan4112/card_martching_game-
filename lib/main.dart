import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const CardMatchingGame());

class CardMatchingGame extends StatefulWidget {
  const CardMatchingGame({super.key});

  @override
  _CardMatchingGameState createState() => _CardMatchingGameState();
}

class _CardMatchingGameState extends State<CardMatchingGame> {
  List<String> images = [
    'https://i.imgur.com/XdYxvXS.png',
    'https://i.imgur.com/AjP8qEe.png',
    'https://i.imgur.com/NWhxpU7.png',
    'https://i.imgur.com/VmSbGZP.png'
  ];

  late List<CardModel> cards;
  CardModel? firstCard;
  CardModel? secondCard;
  int score = 0;
  int moves = 0;
  int lives = 5;
  bool isDarkMode = false;
  bool isPaused = false;
  bool showVictory = false;

  late ConfettiController confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    initializeCards();
    confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  void initializeCards() {
    cards = [...images, ...images].map((img) => CardModel(imageUrl: img)).toList();
    cards.shuffle();
    score = 0;
    moves = 0;
    lives = 5;
    firstCard = null;
    secondCard = null;
    showVictory = false;
  }

  Future<void> playSound(String soundPath) async {
    await _audioPlayer.play(AssetSource(soundPath));
  }

  void flipCard(CardModel card) async {
    if (isPaused || card.isFlipped || card.isMatched) return;

    setState(() {
      card.isFlipped = true;
    });

    playSound('click.mp3');

    if (firstCard == null) {
      firstCard = card;
    } else {
      secondCard = card;
      moves++;

      if (firstCard!.imageUrl == secondCard!.imageUrl) {
        setState(() {
          firstCard!.isMatched = true;
          secondCard!.isMatched = true;
          score += 10;
        });

        playSound('match.mp3');

        if (cards.every((card) => card.isMatched)) {
          confettiController.play();
          playSound('victory.mp3');
          setState(() => showVictory = true);
        }

      } else {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          firstCard!.isFlipped = false;
          secondCard!.isFlipped = false;
          lives--;
        });
      }

      firstCard = null;
      secondCard = null;
    }
  }

  void resetGame() {
    setState(() {
      initializeCards();
      confettiController.stop();
    });
  }

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('🔥 Spicy Card Matching Game 🔥'),
          backgroundColor: Colors.deepPurpleAccent,
          actions: [
            Switch(
              value: isDarkMode,
              onChanged: (value) => setState(() => isDarkMode = value),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: resetGame,
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background Image for Improved UI
            Positioned.fill(
              child: Image.network(
                'https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0',
                fit: BoxFit.cover,
              ),
            ),

            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '🔥 Score: $score | Moves: $moves | Lives: $lives 🔥',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return GestureDetector(
                        onTap: () => flipCard(card),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: card.isFlipped ? Colors.orangeAccent : Colors.blueAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: card.isFlipped
                              ? Image.network(card.imageUrl, errorBuilder: (_, __, ___) => const Icon(Icons.error))
                              : const Icon(Icons.question_mark, size: 36, color: Colors.white),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Victory Confetti Animation
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
              ),
            ),

            if (showVictory)
              const Center(
                child: Text(
                  '🎉 YOU WIN! 🎉',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.yellow),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Card Model for Game Logic
class CardModel {
  final String imageUrl;
  bool isFlipped;
  bool isMatched;

  CardModel({
    required this.imageUrl,
    this.isFlipped = false,
    this.isMatched = false,
  });
}
