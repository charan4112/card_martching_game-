import 'dart:async';
import 'package:flutter/material.dart';
import '../models/card_model.dart';

class GameProvider with ChangeNotifier {
  List<CardModel> cards = [];
  int moves = 0;
  int score = 0;
  int lives = 5;
  int timeTaken = 0;
  int hints = 3;
  int streak = 0;
  List<int> leaderboard = [];
  bool isPaused = false;
  CardModel? firstCard;
  CardModel? secondCard;
  Timer? timer;

  // Initialize cards with Google-hosted image links
  void initializeCards() {
    List<String> images = [
      'https://i.imgur.com/XdYxvXS.png',
      'https://i.imgur.com/AjP8qEe.png',
      'https://i.imgur.com/NWhxpU7.png',
      'https://i.imgur.com/VmSbGZP.png'
    ];

    cards = [...images, ...images]
        .map((img) => CardModel(imageUrl: img))
        .toList();

    cards.shuffle();

    timeTaken = 0;
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!isPaused) {
        timeTaken++;
        notifyListeners();
      }
    });

    notifyListeners();
  }

  // Pause/Resume Feature
  void togglePause() {
    isPaused = !isPaused;
    notifyListeners();
  }

  // Card Flipping and Matching Logic
  void flipCard(CardModel card) {
    if (card.isFlipped || card.isMatched || isPaused) return;

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

    if (firstCard!.imageUrl == secondCard!.imageUrl) {
      firstCard!.isMatched = true;
      secondCard!.isMatched = true;
      
      streak++;
      score += (10 + (streak * 2)); // Streak Bonus

    } else {
      await Future.delayed(const Duration(seconds: 1));
      firstCard!.isFlipped = false;
      secondCard!.isFlipped = false;
      score -= 5;
      lives--;
      streak = 0;
    }

    firstCard = null;
    secondCard = null;

    if (checkWinCondition()) {
      timer?.cancel();
      leaderboard.add(score);
      leaderboard.sort((a, b) => b.compareTo(a));
      leaderboard = leaderboard.take(5).toList();
    }

    notifyListeners();
  }

  void resetGame() {
    initializeCards();
    moves = 0;
    score = 0;
    lives = 5;
    hints = 3;
    timeTaken = 0;
    streak = 0;
    isPaused = false;
    notifyListeners();
  }

  bool checkWinCondition() {
    return cards.every((card) => card.isMatched);
  }
}
