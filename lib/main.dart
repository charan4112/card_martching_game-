import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const CardMatchingGame());
}

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
  late ConfettiController confettiController;

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
  }

  void flipCard(CardModel card) async {
    if (isPaused || card.isFlipped || card.isMatched) return;

    setState(() {
      card.isFlipped = true;
    });

    if (firstCard == null) {
      firstCard = card;
    } else {
      secondCard = card;
      moves++;

      if (firstCard!.imageUrl == secondCard!.imageUrl) {
        // Match found
        setState(() {
          firstCard!.isMatched = true;
          secondCard!.isMatched = true;
          score += 10;
        });

        if (cards.every((card) => card.isMatched)) {
          confettiController.play();
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
          title: const Text('Card Matching Game'),
          actions: [
            Switch(
              value: isDarkMode,
              onChanged: (value) {
                setState(() {
                  isDarkMode = value;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: resetGame,
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Score: $score | Moves: $moves | Lives: $lives',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                              ? Image.network(card.imageUrl)
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
