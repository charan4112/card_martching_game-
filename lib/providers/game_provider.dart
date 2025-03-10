import 'dart:async';
import 'package:flutter/material.dart';
import '../models/card_model.dart';

class GameProvider with ChangeNotifier {
  List<CardModel> cards = [];
  int moves = 0;
  int score = 0;
  int lives = 5; 
  int timeTaken = 0; // New Timer Variable
  CardModel? firstCard;
  CardModel? secondCard;
  Timer? timer;

  // Initialize cards with sample images and shuffle
  void initializeCards() {
    List<String> images = [
      'assets/images/cat.png',
      'assets/images/dog.png',
      'assets/images/lion.png',
      'assets/images/tiger.png'
    ];

    cards = [...images, ...images]
        .map((img) => CardModel(imagePath: img))
        .toList();

    cards.shuffle();

    // Start Timer when game starts
    timeTaken = 0;
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      timeTaken++;
      notifyListeners();
    });

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
      
      // Add bonus if matched quickly
      if (timeTaken <= 3) {
        score += 15; // Quick match bonus
      } else {
        score += 10; // Standard points for a correct match
      }
    } else {
      await Future.delayed(const Duration(seconds: 1));
      firstCard!.isFlipped = false;
      secondCard!.isFlipped = false;
      score -= 5; // Penalty for incorrect match
      lives--;     // Lose a life on incorrect match
    }

    firstCard = null;
    secondCard = null;

    // Stop Timer if game is completed
    if (checkWinCondition()) {
      timer?.cancel();
    }

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
    timeTaken = 0;
    notifyListeners();
  }
}
