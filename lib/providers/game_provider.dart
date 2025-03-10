import 'package:flutter/material.dart';
import '../models/card_model.dart';

class GameProvider with ChangeNotifier {
  List<CardModel> cards = [];
  int moves = 0;
  int score = 0;
  int lives = 5;  // Add life system for challenge
  CardModel? firstCard;
  CardModel? secondCard;

  // Initialize cards with sample images and shuffle
  void initializeCards() {
    List<String> images = [
      'assets/images/cat.png',
      'assets/images/dog.png',
      'assets/images/lion.png',
      'assets/images/tiger.png'
    ];

    cards = [...images, ...images]  // Duplicating for matching pairs
        .map((img) => CardModel(imagePath: img))
        .toList();

    cards.shuffle();
    notifyListeners();
  }

  // Logic for card flipping and matching
  void flipCard(CardModel card) {
    if (card.isFlipped || card.isMatched) return;

    card.isFlipped = true;

    if (firstCard == null) {
      firstCard = card;
    } else {
      secondCard = card;
      checkMatch();
    }

    notifyListeners();
  }

  void checkMatch() async {
    moves++;

    if (firstCard!.imagePath == secondCard!.imagePath) {
      firstCard!.isMatched = true;
      secondCard!.isMatched = true;
      score += 10;  // Bonus for correct match
    } else {
      await Future.delayed(const Duration(seconds: 1));
      firstCard!.isFlipped = false;
      secondCard!.isFlipped = false;
      lives--;  // Deduct life for wrong match
    }

    firstCard = null;
    secondCard = null;

    notifyListeners();
  }

  // Check for Win Condition
  bool checkWinCondition() {
    return cards.every((card) => card.isMatched);
  }

  // Reset the Game
  void resetGame() {
    initializeCards();
    moves = 0;
    score = 0;
    lives = 5;
    notifyListeners();
  }
}
