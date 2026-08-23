import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/services/game_score_service.dart';

enum Difficulty { easy, medium, hard }

class MemoryCard {
  final int id;
  final String icon;
  final String name;
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.icon,
    required this.name,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({Key? key}) : super(key: key);

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  Difficulty _currentDifficulty = Difficulty.medium;
  List<MemoryCard> _cards = [];
  MemoryCard? _firstFlipped;
  MemoryCard? _secondFlipped;

  bool _isProcessing = false;
  int _moves = 0;
  int _matchedPairs = 0;
  int _totalPairs = 6;
  int _secondsElapsed = 0;
  Timer? _timer;

  final List<Map<String, String>> _allSymbols = [
    {'icon': '🌸', 'name': 'Flower'},
    {'icon': '🍃', 'name': 'Leaf'},
    {'icon': '❤️', 'name': 'Heart'},
    {'icon': '🌙', 'name': 'Moon'},
    {'icon': '☀️', 'name': 'Sun'},
    {'icon': '💧', 'name': 'Water'},
    {'icon': '⭐', 'name': 'Star'},
    {'icon': '🦋', 'name': 'Butterfly'},
  ];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _moves = 0;
    _matchedPairs = 0;
    _firstFlipped = null;
    _secondFlipped = null;
    _isProcessing = false;

    int numPairs;
    if (_currentDifficulty == Difficulty.easy) {
      numPairs = 3;
    } else if (_currentDifficulty == Difficulty.medium) {
      numPairs = 6;
    } else {
      numPairs = 8;
    }

    _totalPairs = numPairs;
    final selectedSymbols = List<Map<String, String>>.from(_allSymbols)..shuffle();
    final chosen = selectedSymbols.take(numPairs).toList();

    List<MemoryCard> cardList = [];
    int idCounter = 0;
    for (var item in chosen) {
      cardList.add(MemoryCard(id: idCounter++, icon: item['icon']!, name: item['name']!));
      cardList.add(MemoryCard(id: idCounter++, icon: item['icon']!, name: item['name']!));
    }
    cardList.shuffle(Random());
    _cards = cardList;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _secondsElapsed++;
      });
    });

    setState(() {});
  }

  void _onCardTapped(MemoryCard card) {
    if (_isProcessing || card.isFlipped || card.isMatched) return;

    setState(() {
      card.isFlipped = true;
    });

    if (_firstFlipped == null) {
      _firstFlipped = card;
    } else if (_secondFlipped == null) {
      _secondFlipped = card;
      _moves++;
      _checkMatch();
    }
  }

  void _checkMatch() {
    _isProcessing = true;
    if (_firstFlipped!.name == _secondFlipped!.name) {
      setState(() {
        _firstFlipped!.isMatched = true;
        _secondFlipped!.isMatched = true;
        _matchedPairs++;
        _firstFlipped = null;
        _secondFlipped = null;
        _isProcessing = false;
      });

      if (_matchedPairs >= _totalPairs) {
        _onGameCompleted();
      }
    } else {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() {
            _firstFlipped!.isFlipped = false;
            _secondFlipped!.isFlipped = false;
            _firstFlipped = null;
            _secondFlipped = null;
            _isProcessing = false;
          });
        }
      });
    }
  }

  Future<void> _onGameCompleted() async {
    _timer?.cancel();

    // Calculate Game Score
    final int baseScore = _totalPairs * 50;
    final int moveDeduction = _moves * 5;
    final int timeDeduction = _secondsElapsed * 2;
    final int finalScore = max(10, baseScore - moveDeduction - timeDeduction + 100);

    final gameData = await GameScoreService.saveScore(
      gameId: 'memory_match',
      score: finalScore,
      durationSeconds: _secondsElapsed,
    );

    int stars = 3;
    if (_moves > _totalPairs * 2.5) stars = 1;
    else if (_moves > _totalPairs * 1.8) stars = 2;

    if (mounted) {
      _showCompletionDialog(finalScore, stars, gameData);
    }
  }

  void _showCompletionDialog(int score, int stars, GameScoreData gameData) {
    final isBn = Provider.of<AppLanguageProvider>(context, listen: false).isBangla;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  index < stars ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 38,
                );
              }),
            ),
            const SizedBox(height: 10),
            Text(
              isBn ? 'অভিনন্দন!' : 'Congratulations!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBn ? 'আপনি সব কার্ড সঠিকভাবে মেলাতে পেরেছেন!' : 'You matched all wellness cards successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white),
              ),
              child: Column(
                children: [
                  _buildStatRow(isBn ? 'মোট চাল' : 'Total Moves', '$_moves'),
                  const Divider(height: 16),
                  _buildStatRow(isBn ? 'সময় লেগেছে' : 'Time Taken', '${_secondsElapsed}s'),
                  const Divider(height: 16),
                  _buildStatRow(isBn ? 'অর্জিত স্কোর' : 'Score Earned', '+$score Points'),
                  const Divider(height: 16),
                  _buildStatRow(isBn ? 'সেরা স্কোর' : 'Best Score', '${gameData.bestScore} Points'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Text(isBn ? 'হোম পেজ' : 'Exit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startNewGame();
                  },
                  child: Text(isBn ? 'আবার খেলুন' : 'Replay', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 13)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isBn ? 'মেমোরি ম্যাচ' : 'Memory Match',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black, size: 26),
            onPressed: _startNewGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Difficulty Selector Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDifficultyChip(Difficulty.easy, isBn ? 'সহজ (Easy)' : 'Easy'),
                  const SizedBox(width: 8),
                  _buildDifficultyChip(Difficulty.medium, isBn ? 'মাঝারি (Medium)' : 'Medium'),
                  const SizedBox(width: 8),
                  _buildDifficultyChip(Difficulty.hard, isBn ? 'কঠিন (Hard)' : 'Hard'),
                ],
              ),
            ),

            // Game Stats Bar (Moves, Timer, Pairs)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderBox(Icons.touch_app_rounded, '$_moves ${isBn ? "চাল" : "Moves"}', const Color(0xFFA855F7)),
                  _buildHeaderBox(Icons.timer_rounded, '${_secondsElapsed}s', const Color(0xFF3B82F6)),
                  _buildHeaderBox(Icons.check_circle_rounded, '$_matchedPairs/$_totalPairs', const Color(0xFF10B981)),
                ],
              ),
            ),

            // Flip Cards Grid View
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  itemCount: _cards.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _currentDifficulty == Difficulty.easy ? 3 : 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return GestureDetector(
                      onTap: () => _onCardTapped(card),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: card.isFlipped || card.isMatched ? Colors.white : const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: card.isMatched
                                ? const Color(0xFF10B981)
                                : (card.isFlipped ? AppColors.primary : Colors.transparent),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: card.isFlipped
                                  ? AppColors.primary.withOpacity(0.2)
                                  : Colors.purple.shade200.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: card.isFlipped || card.isMatched
                              ? Text(
                                  card.icon,
                                  style: const TextStyle(fontSize: 34),
                                )
                              : const Icon(
                                  Icons.psychology_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(Difficulty diff, String label) {
    final bool isSelected = _currentDifficulty == diff;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentDifficulty = diff;
          });
          _startNewGame();
        }
      },
    );
  }

  Widget _buildHeaderBox(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
