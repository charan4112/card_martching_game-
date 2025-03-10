import 'package:flutter/material.dart';

class CardModel {
  final String imagePath;
  bool isFlipped;
  bool isMatched;

  CardModel({
    required this.imagePath,
    this.isFlipped = false,
    this.isMatched = false,
  });
}
