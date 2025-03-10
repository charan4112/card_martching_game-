import 'package:flutter/material.dart';

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
