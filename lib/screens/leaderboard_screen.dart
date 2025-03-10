import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Leaderboard'),
      ),
      body: ListView.builder(
        itemCount: gameProvider.leaderboard.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.star, color: Colors.yellow),
            title: Text('Score: ${gameProvider.leaderboard[index]}'),
          );
        },
      ),
    );
  }
}
