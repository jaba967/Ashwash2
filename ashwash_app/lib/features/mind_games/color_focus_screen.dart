import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/services/mind_games_repository.dart';

class ColorFocusScreen extends StatefulWidget {
  const ColorFocusScreen({Key? key}) : super(key: key);

  @override
  State<ColorFocusScreen> createState() => _ColorFocusScreenState();
}

class _ColorFocusScreenState extends State<ColorFocusScreen> {
  final MindGamesRepository _repo = MindGamesRepository();
  final Random _random = Random();

  int _score = 0;
  int _timeLeft = 30;
  Timer? _timer;
  bool _isPlaying = false;

  final List<Map<String, dynamic>> _colors = [
    {'name': 'RED', 'nameBn': 'লাল', 'color': Colors.red},
    {'name': 'BLUE', 'nameBn': 'নীল', 'color': Colors.blue},
    {'name': 'GREEN', 'nameBn': 'সবুজ', 'color': Colors.green},
    {'name': 'YELLOW', 'nameBn': 'হলুদ', 'color': Colors.amber},
    {'name': 'PURPLE', 'nameBn': 'বেগুনি', 'color': AppColors.primary},
    {'name': 'ORANGE', 'nameBn': 'কমলা', 'color': Colors.orange},
  ];

  late String _displayedWordEn;
  late String _displayedWordBn;
  late Color _textColor;

  @override
  void initState() {
    super.initState();
    _generateNextRound();
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _timeLeft = 30;
      _isPlaying = true;
    });

    _generateNextRound();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft > 1) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _endGame();
      }
    });
  }

  void _generateNextRound() {
    final wordIndex = _random.nextInt(_colors.length);
    final colorIndex = _random.nextInt(_colors.length);

    setState(() {
      _displayedWordEn = _colors[wordIndex]['name'];
      _displayedWordBn = _colors[wordIndex]['nameBn'];
      _textColor = _colors[colorIndex]['color'];
    });
  }

  void _checkAnswer(Color selectedColor) {
    if (!_isPlaying) return;

    if (selectedColor == _textColor) {
      setState(() {
        _score += 10;
      });
    } else {
      setState(() {
        _score = (_score - 5).clamp(0, 9999);
      });
    }

    _generateNextRound();
  }

  void _endGame() async {
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
    });

    await _repo.saveGameScore(
      gameId: 'color_focus',
      score: _score,
      durationSeconds: 30,
    );

    if (mounted) {
      _showGameOverModal();
    }
  }

  void _showGameOverModal() {
    final isBn = Provider.of<AppLanguageProvider>(context, listen: false).isBangla;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                child: const Icon(Icons.psychology_rounded, color: Colors.black, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                isBn ? 'সময় শেষ!' : 'Time Up!',
                style: AppTypography.heading1(context),
              ),
              const SizedBox(height: 8),
              Text(
                isBn ? 'আপনার একাগ্রতা পরীক্ষা সম্পন্ন হয়েছে' : 'Great mental concentration workout!',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isBn ? 'অর্জিত স্কোর: +$_score' : 'Score Earned: +$_score',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _startGame();
                      },
                      icon: const Icon(Icons.refresh_rounded, color: Colors.black),
                      label: Text(isBn ? 'আবার খেলুন' : 'Play Again', style: const TextStyle(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(isBn ? 'সম্পন্ন' : 'Done', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
      appBar: AppBar(
        title: Text(isBn ? 'কালার ফোকাস' : 'Color Focus', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricTile(isBn ? 'সময়' : 'Time', '${_timeLeft}s'),
                  _buildMetricTile(isBn ? 'স্কোর' : 'Score', '+$_score'),
                ],
              ),
              const Spacer(),

              Text(
                isBn ? 'লেখাটির কালার (রং) ম্যাচ করুন, লেখার অর্থ নয়!' : 'Select the COLOR of the word, not the text meaning!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white),
                ),
                child: Center(
                  child: Text(
                    isBn ? _displayedWordBn : _displayedWordEn,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: _textColor,
                    ),
                  ),
                ),
              ),
              const Spacer(),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final colorItem = _colors[index];
                  return InkWell(
                    onTap: () => _checkAnswer(colorItem['color']),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorItem['color'],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          isBn ? colorItem['nameBn'] : colorItem['name'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlaying ? AppColors.danger : AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isPlaying ? _endGame : _startGame,
                  child: Text(
                    _isPlaying ? (isBn ? 'গেম শেষ করুন' : 'End Game') : (isBn ? 'শুরু করুন' : 'Start Game'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
        ],
      ),
    );
  }
}
