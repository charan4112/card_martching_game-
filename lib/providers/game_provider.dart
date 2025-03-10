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
  int streak = 0;  // New Streak Bonus System
  List<int> leaderboard = [];
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
      timeTaken++;
      notifyListeners();
    });

    notifyListeners();
  }

  // Card Flipping and Matching Logic
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

    if (firstCard!.imageUrl == secondCard!.imageUrl) {
      firstCard!.isMatched = true;
      secondCard!.isMatched = true;
      
      // Streak Bonus
      streak++;
      score += (10 + (streak * 2)); // Consecutive correct match bonus

    } else {
      await Future.delayed(const Duration(seconds: 1));
      firstCard!.isFlipped = false;
      secondCard!.isFlipped = false;
      score -= 5;
      lives--;
      streak = 0; // Reset streak if incorrect
    }

    firstCard = null;
    secondCard = null;

    if (checkWinCondition()) {
      timer?.cancel();
      leaderboard.add(score);
      leaderboard.sort((a, b) => b.compareTo(a)); // Sort in descending order
      leaderboard = leaderboard.take(5).toList(); // Top 5 scores only
    }

    notifyListeners();
  }

  // Hint System - Reveal one card for 3 seconds
  void useHint() {
    if (hints == 0) return;

    hints--;

    final hiddenCards = cards.where((card) => !card.isFlipped && !card.isMatched).toList();
    if (hiddenCards.isNotEmpty) {
      final hintCard = hiddenCards[0];
      hintCard.isFlipped = true;

      Future.delayed(const Duration(seconds: 3), () {
        hintCard.isFlipped = false;
        notifyListeners();
      });
    }

    notifyListeners();
  }

  bool checkWinCondition() {
    return cards.every((card) => card.isMatched);
  }

  void resetGame() {
    initializeCards();
    moves = 0;
    score = 0;
    lives = 5;
    hints = 3;
    timeTaken = 0;
    streak = 0;
    notifyListeners();
  }
}
