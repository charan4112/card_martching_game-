import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CardMatchingApp());
}

/* 
   Data class to store completed or abandoned game attempts
   - outcome: 'WIN' if completed all matches, 'LOSE' if out of lives, 'QUIT' if reset mid-game
*/
class GameRecord {
  final int id;
  final String playerName;
  final int finalScore;
  final int finalMoves;
  final int finalLives;
  final int finalTime;
  final String outcome;
  GameRecord({
    required this.id,
    required this.playerName,
    required this.finalScore,
    required this.finalMoves,
    required this.finalLives,
    required this.finalTime,
    required this.outcome,
  });
}

/* Each game card's data model */
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

class CardMatchingApp extends StatefulWidget {
  const CardMatchingApp({Key? key}) : super(key: key);
  @override
  State<CardMatchingApp> createState() => _CardMatchingAppState();
}

class _CardMatchingAppState extends State<CardMatchingApp> {
  bool isDark = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDark ? ThemeData.dark() : ThemeData.light(),
      initialRoute: '/start',
      routes: {
        '/start': (_) => StartScreen(onToggleTheme: () => setState(() => isDark = !isDark)),
        '/instructions': (_) => const InstructionScreen(),
        '/leaderboard': (_) => const LeaderboardScreen(),
      },
    );
  }
}

class StartScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const StartScreen({Key? key, required this.onToggleTheme}) : super(key: key);

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final TextEditingController _nameCtrl = TextEditingController();

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Matching - Start'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.pushNamed(context, '/instructions'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/back.JPG', fit: BoxFit.cover)),
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter Name',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Your Name',
                      hintStyle: TextStyle(color: Colors.white54),
                      fillColor: Colors.white10,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _startGame,
                    child: const Text('Start Game'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a name!')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(playerName: name)));
  }
}

class InstructionScreen extends StatelessWidget {
  const InstructionScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instructions')),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/back.JPG', fit: BoxFit.cover)),
          SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: const Text(
                'HOW TO PLAY:\n'
                ' - 12 cards total (Bob, Kaaju, Raju, Sweety ×3)\n'
                ' - Matches: (Sweety ↔ Raju), (Bob ↔ Kaaju)\n'
                ' - Flip two cards:\n'
                '   * If match => +10 points.\n'
                '   * If mismatch => lose 1 life.\n'
                ' - You have 5 lives.\n'
                ' - Score, Moves, Timer.\n'
                ' - Pause or Reset at any time.\n'
                ' - If all matched => Confetti, store record as WIN.\n'
                ' - If out of lives => store record as LOSE.\n'
                ' - If reset mid-game => store record as QUIT.\n'
                ' - See all game records in Leaderboard.\n'
                'Enjoy!\n',
                style: TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  Database? _db;
  List<GameRecord> records = [];

  @override
  void initState() {
    super.initState();
    _initDB().then((_) => _fetchRecords());
  }

  Future<void> _initDB() async {
    final dp = await getDatabasesPath();
    final fp = p.join(dp, 'match_game.db');
    _db = await openDatabase(
      fp,
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE IF NOT EXISTS gameHistory (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          playerName TEXT,
          finalScore INTEGER,
          finalMoves INTEGER,
          finalLives INTEGER,
          finalTime INTEGER,
          outcome TEXT
        )
      '''),
    );
  }

  Future<void> _fetchRecords() async {
    if (_db == null) return;
    final raw = await _db!.query('gameHistory', orderBy: 'id DESC');
    final list = raw.map((r) => GameRecord(
      id: r['id'] as int,
      playerName: r['playerName'] as String,
      finalScore: r['finalScore'] as int,
      finalMoves: r['finalMoves'] as int,
      finalLives: r['finalLives'] as int,
      finalTime: r['finalTime'] as int,
      outcome: r['outcome'] as String,
    )).toList();
    setState(() => records = list);
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game History')),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/back.JPG', fit: BoxFit.cover)),
          records.isEmpty
              ? const Center(child: Text('No Records Yet!', style: TextStyle(fontSize: 20, color: Colors.white)))
              : ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (ctx, i) {
                    final rec = records[i];
                    return ListTile(
                      title: Text(
                        '[${rec.outcome}] ${rec.playerName}: Score=${rec.finalScore}, Moves=${rec.finalMoves}, Lives=${rec.finalLives}, Time=${_fmtTime(rec.finalTime)}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  String _fmtTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class GameScreen extends StatefulWidget {
  final String playerName;
  const GameScreen({Key? key, required this.playerName}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Database? _db;
  bool dbOk = false;

  List<String> images = [
    'assets/images/bob.JPG',
    'assets/images/kaaju.JPG',
    'assets/images/raju.JPG',
    'assets/images/sweety.JPG',
  ];
  late List<CardModel> cards;
  CardModel? firstC, secondC;

  int score = 0;
  int moves = 0;
  int lives = 5;
  bool isPaused = false;
  bool showVictory = false;
  String msg = '';

  int elapsed = 0;
  Timer? timer;
  late ConfettiController confetti;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initDB().then((_) {
      dbOk = true;
      _setupGame();
      _startTimer();
    });
    confetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  Future<void> _initDB() async {
    final dp = await getDatabasesPath();
    final fp = p.join(dp, 'match_game.db');
    _db = await openDatabase(
      fp,
      version: 1,
      onCreate: (db, v) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS gameHistory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            playerName TEXT,
            finalScore INTEGER,
            finalMoves INTEGER,
            finalLives INTEGER,
            finalTime INTEGER,
            outcome TEXT
          )
        ''');
      },
    );
  }

  void _setupGame() {
    final list = [...images, ...images, ...images];
    cards = list.map((x) => CardModel(imageUrl: x)).toList();
    cards.shuffle();
    score = 0;
    moves = 0;
    lives = 5;
    firstC = null;
    secondC = null;
    msg = '';
    showVictory = false;
  }

  void _startTimer() {
    elapsed = 0;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!isPaused) {
        setState(() => elapsed++);
      }
    });
  }

  void _stopTimer() {
    timer?.cancel();
    timer = null;
  }

  @override
  void dispose() {
    confetti.dispose();
    _stopTimer();
    super.dispose();
  }

  bool _customMatch(CardModel a, CardModel b) {
    final x = a.imageUrl.toLowerCase();
    final y = b.imageUrl.toLowerCase();
    // Sweety ↔ Raju, Bob ↔ Kaaju
    if ((x.contains('sweety') && y.contains('raju')) ||
        (x.contains('raju') && y.contains('sweety')) ||
        (x.contains('bob') && y.contains('kaaju')) ||
        (x.contains('kaaju') && y.contains('bob'))) {
      return true;
    }
    return false;
  }

  void _flipCard(CardModel c) async {
    if (isPaused || c.isFlipped || c.isMatched || lives < 1) return;
    setState(() => c.isFlipped = true);
    _playSound('click.mp3');

    if (firstC == null) {
      firstC = c;
    } else {
      secondC = c;
      moves++;
      if (_customMatch(firstC!, secondC!)) {
        setState(() {
          firstC!.isMatched = true;
          secondC!.isMatched = true;
          score += 10;
          msg = 'Matched!';
        });
        _playSound('match.mp3');
        if (cards.every((cd) => cd.isMatched)) {
          confetti.play();
          msg = 'All Matched! You Win!';
          showVictory = true;
          _stopTimer();
          _playSound('victory.mp3');
          if (dbOk) await _saveGameRecord(outcome: 'WIN');
        }
      } else {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          firstC!.isFlipped = false;
          secondC!.isFlipped = false;
          lives--;
          msg = 'Mismatch!';
        });
        if (lives < 1) {
          _stopTimer();
          msg = 'Game Over! Out of Lives.';
          if (dbOk) await _saveGameRecord(outcome: 'LOSE');
        }
      }
      firstC = null;
      secondC = null;
    }
  }

  Future<void> _saveGameRecord({required String outcome}) async {
    if (_db == null) return;
    await _db!.insert('gameHistory', {
      'playerName': widget.playerName,
      'finalScore': score,
      'finalMoves': moves,
      'finalLives': lives,
      'finalTime': elapsed,
      'outcome': outcome,
    });
  }

  void _playSound(String file) async {
    await _audioPlayer.play(AssetSource(file));
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
      msg = isPaused ? 'Game Paused' : 'Game Resumed';
    });
  }

  void _resetGame() async {
    _stopTimer();
    if (dbOk && lives > 0 && !showVictory) {
      // If we forcibly reset mid-game, record "QUIT"
      await _saveGameRecord(outcome: 'QUIT');
    }
    confetti.stop();
    _setupGame();
    _startTimer();
  }

  String _fmtTime(int s) {
    final m = s ~/ 60;
    final ss = s % 60;
    return '${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quick Help'),
        content: const Text(
          ' - Flip two cards.\n'
          ' - Sweety↔Raju or Bob↔Kaaju => +10.\n'
          ' - Otherwise => lose 1 life.\n'
          ' - Win by matching all before lives=0.\n'
          ' - Reset mid-game => outcome=QUIT.\n'
          ' - Score, moves, time all recorded.\n'
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Playing: ${widget.playerName}'),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: _showHelp),
          IconButton(icon: const Icon(Icons.pause), onPressed: _togglePause),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetGame),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/back.JPG', fit: BoxFit.cover)),
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Score: $score | Moves: $moves | Lives: $lives | Time: ${_fmtTime(elapsed)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Text(msg, style: const TextStyle(fontSize: 18, color: Colors.yellow)),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (ctx, i) {
                    final cd = cards[i];
                    return GestureDetector(
                      onTap: () => _flipCard(cd),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: cd.isFlipped ? Colors.orangeAccent : Colors.yellowAccent[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: cd.isFlipped
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(cd.imageUrl, fit: BoxFit.cover),
                              )
                            : Center(
                                child: Text(
                                  'Tap',
                                  style: TextStyle(
                                    color: Colors.brown[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
