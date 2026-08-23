import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/services/game_score_service.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({Key? key}) : super(key: key);

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  Timer? _phaseTimer;
  Timer? _totalDurationTimer;

  int _currentPhaseIndex = 0; // 0: Inhale (4s), 1: Hold (4s), 2: Exhale (4s)
  int _secondsLeftInPhase = 4;
  int _completedCycles = 0;
  int _totalTimeSeconds = 0;
  bool _isPlaying = true;
  bool _isFinished = false;

  final List<String> _phasesEn = ['Inhale...', 'Hold...', 'Exhale...'];
  final List<String> _phasesBn = ['শ্বাস নিন...', 'ধরে রাখুন...', 'শ্বাস ছাড়ুন...'];
  final List<Color> _phaseColors = [
    const Color(0xFF8B5CF6), // Purple Inhale
    const Color(0xFF0EA5E9), // Cyan Hold
    const Color(0xFF10B981), // Emerald Exhale
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startExercise();
  }

  void _startExercise() {
    _controller.forward();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) return;

      setState(() {
        _secondsLeftInPhase--;
        _totalTimeSeconds++;
      });

      if (_secondsLeftInPhase <= 0) {
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    setState(() {
      _currentPhaseIndex = (_currentPhaseIndex + 1) % 3;
      _secondsLeftInPhase = 4;

      if (_currentPhaseIndex == 0) {
        _completedCycles++;
        _controller.forward(from: 0.0);
      } else if (_currentPhaseIndex == 1) {
        // Hold: keep circle static at peak scale
      } else if (_currentPhaseIndex == 2) {
        _controller.reverse(from: 1.0);
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        if (_currentPhaseIndex == 0) _controller.forward();
        if (_currentPhaseIndex == 2) _controller.reverse();
      } else {
        _controller.stop();
      }
    });
  }

  Future<void> _finishExercise() async {
    _phaseTimer?.cancel();
    _controller.stop();

    final int finalScore = _completedCycles * 10;
    final gameData = await GameScoreService.saveScore(
      gameId: 'breathing_exercise',
      score: finalScore,
      durationSeconds: _totalTimeSeconds,
    );

    setState(() {
      _isFinished = true;
    });

    if (mounted) {
      _showResultDialog(finalScore, gameData);
    }
  }

  String _getRating(int cycles, bool isBn) {
    if (cycles >= 5) return isBn ? 'চমৎকার! (Excellent)' : 'Excellent';
    if (cycles >= 3) return isBn ? 'খুব ভালো! (Good)' : 'Good';
    return isBn ? 'আরও চর্চা প্রয়োজন (Needs Practice)' : 'Needs Practice';
  }

  void _showResultDialog(int score, GameScoreData gameData) {
    final isBn = Provider.of<AppLanguageProvider>(context, listen: false).isBangla;
    final rating = _getRating(_completedCycles, isBn);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.self_improvement_rounded, color: Color(0xFFA855F7), size: 40),
            ),
            const SizedBox(height: 12),
            Text(
              rating,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBn ? 'আপনার মন এখন প্রশান্ত ও শান্ত!' : 'Your mind is now calm and relaxed!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white),
              ),
              child: Column(
                children: [
                  _buildResultRow(isBn ? 'মোট সাইকেল' : 'Completed Cycles', '$_completedCycles'),
                  const Divider(height: 16),
                  _buildResultRow(isBn ? 'অর্জিত স্কোর' : 'Score Earned', '+$score Points'),
                  const Divider(height: 16),
                  _buildResultRow(isBn ? 'সেরা স্কোর' : 'Best Score', '${gameData.bestScore} Points'),
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
                    setState(() {
                      _completedCycles = 0;
                      _totalTimeSeconds = 0;
                      _currentPhaseIndex = 0;
                      _secondsLeftInPhase = 4;
                      _isPlaying = true;
                      _isFinished = false;
                    });
                    _startExercise();
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

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
      ],
    );
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _totalDurationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;
    final currentPhaseText = isBn ? _phasesBn[_currentPhaseIndex] : _phasesEn[_currentPhaseIndex];
    final currentColor = _phaseColors[_currentPhaseIndex];

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
          isBn ? 'শ্বাসের ব্যায়াম' : 'Breathing Exercise',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Score & Timer Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.purple.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '${_completedCycles * 10} Score',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.loop_rounded, color: Colors.black, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '$_completedCycles ${isBn ? "সাইকেল" : "Cycles"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Animated Breathing Circle with Aura Glow
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer aura ring 1
                    Container(
                      width: 260 * _scaleAnimation.value,
                      height: 260 * _scaleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentColor.withOpacity(0.12),
                      ),
                    ),
                    // Outer aura ring 2
                    Container(
                      width: 210 * _scaleAnimation.value,
                      height: 210 * _scaleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentColor.withOpacity(0.22),
                      ),
                    ),
                    // Center Breathing Circle
                    Container(
                      width: 170 * _scaleAnimation.value,
                      height: 170 * _scaleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            currentColor.withOpacity(0.9),
                            currentColor,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentPhaseText,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_secondsLeftInPhase}s',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Control & Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPlaying ? Colors.amber.shade700 : AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _togglePlayPause,
                        icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                        label: Text(
                          _isPlaying ? (isBn ? 'পজ' : 'Pause') : (isBn ? 'চালু করুন' : 'Resume'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _finishExercise,
                        child: Text(
                          isBn ? 'শেষ করুন' : 'Finish',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
