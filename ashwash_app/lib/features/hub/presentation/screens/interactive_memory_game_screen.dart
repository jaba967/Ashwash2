import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/dashboard_provider.dart';

class InteractiveMemoryGameScreen extends StatefulWidget {
  const InteractiveMemoryGameScreen({super.key});

  @override
  State<InteractiveMemoryGameScreen> createState() => _InteractiveMemoryGameScreenState();
}

class _InteractiveMemoryGameScreenState extends State<InteractiveMemoryGameScreen> {
  final List<String> _emojis = ['🌸', '☀️', '🌱', '🦋', '🌸', '☀️', '🌱', '🦋'];
  late List<bool> _cardFlips;
  late List<bool> _cardMatches;

  int? _firstSelectedIndex;
  bool _isProcessing = false;
  int _moves = 0;
  int _matchedPairs = 0;

  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _emojis.shuffle();
    _cardFlips = List.generate(_emojis.length, (_) => false);
    _cardMatches = List.generate(_emojis.length, (_) => false);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onCardTapped(int index) {
    if (_isProcessing || _cardFlips[index] || _cardMatches[index]) return;

    setState(() {
      _cardFlips[index] = true;
    });

    if (_firstSelectedIndex == null) {
      _firstSelectedIndex = index;
    } else {
      _moves++;
      _isProcessing = true;
      final firstIndex = _firstSelectedIndex!;

      if (_emojis[firstIndex] == _emojis[index]) {
        // Match found!
        setState(() {
          _cardMatches[firstIndex] = true;
          _cardMatches[index] = true;
          _matchedPairs++;
          _firstSelectedIndex = null;
          _isProcessing = false;
        });

        if (_matchedPairs == _emojis.length ~/ 2) {
          _timer?.cancel();
          _showWinDialog();
        }
      } else {
        // Not a match, flip back after brief pause
        Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _cardFlips[firstIndex] = false;
              _cardFlips[index] = false;
              _firstSelectedIndex = null;
              _isProcessing = false;
            });
          }
        });
      }
    }
  }

  void _showWinDialog() {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    dashboardProvider.fetchDashboardData();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.emoji_events_rounded, size: 50, color: Colors.amber),
              SizedBox(height: 8),
              Text('Puzzle Completed!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Congratulations! You matched all pairs in $_moves moves and $_secondsElapsed seconds.\n\n+50 Wellness Points Earned! 🎉',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Return to Games'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Match'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header Stats Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatPill('Moves', '$_moves', Icons.touch_app_rounded),
                  _buildStatPill('Time', '$_secondsElapsed s', Icons.timer_rounded),
                  _buildStatPill('Pairs', '$_matchedPairs/4', Icons.star_rounded),
                ],
              ),
              const SizedBox(height: 32),

              // Game Grid
              Expanded(
                child: GridView.builder(
                  itemCount: _emojis.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final isFlipped = _cardFlips[index] || _cardMatches[index];

                    return GestureDetector(
                      onTap: () => _onCardTapped(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isFlipped ? Colors.white : AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _cardMatches[index] ? AppColors.success : AppColors.primary,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            isFlipped ? _emojis[index] : '🧠',
                            style: TextStyle(
                              fontSize: isFlipped ? 48 : 36,
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
        ),
      ),
    );
  }

  Widget _buildStatPill(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
