import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/services/game_score_service.dart';

class EmotionItem {
  final String id;
  final String emoji;
  final String nameEn;
  final String nameBn;
  final Color color;

  EmotionItem({
    required this.id,
    required this.emoji,
    required this.nameEn,
    required this.nameBn,
    required this.color,
  });
}

class SituationTarget {
  final String id;
  final String emotionId;
  final String situationEn;
  final String situationBn;
  EmotionItem? matchedEmotion;

  SituationTarget({
    required this.id,
    required this.emotionId,
    required this.situationEn,
    required this.situationBn,
    this.matchedEmotion,
  });
}

class MoodMatchScreen extends StatefulWidget {
  const MoodMatchScreen({Key? key}) : super(key: key);

  @override
  State<MoodMatchScreen> createState() => _MoodMatchScreenState();
}

class _MoodMatchScreenState extends State<MoodMatchScreen> {
  int _score = 0;
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _isCompleted = false;

  final List<EmotionItem> _emotions = [
    EmotionItem(id: 'happy', emoji: '😄', nameEn: 'Happy', nameBn: 'খুশি', color: const Color(0xFFF59E0B)),
    EmotionItem(id: 'calm', emoji: '🧘', nameEn: 'Calm', nameBn: 'প্রশান্ত', color: const Color(0xFF10B981)),
    EmotionItem(id: 'excited', emoji: '🥳', nameEn: 'Excited', nameBn: 'উত্তেজিত', color: const Color(0xFFA855F7)),
    EmotionItem(id: 'anxious', emoji: '😰', nameEn: 'Anxious', nameBn: 'উদ্বিগ্ন', color: const Color(0xFF3B82F6)),
    EmotionItem(id: 'sad', emoji: '😢', nameEn: 'Sad', nameBn: 'দুঃখিত', color: Colors.white),
    EmotionItem(id: 'angry', emoji: '😡', nameEn: 'Angry', nameBn: 'রাগান্বিত', color: const Color(0xFFEF4444)),
  ];

  late List<SituationTarget> _targets;
  late List<EmotionItem> _availableEmotions;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _timer?.cancel();
    _score = 0;
    _secondsElapsed = 0;
    _isCompleted = false;

    _availableEmotions = List.from(_emotions)..shuffle();

    _targets = [
      SituationTarget(
        id: '1',
        emotionId: 'anxious',
        situationEn: 'Feeling nervous before an important presentation or test',
        situationBn: 'গুরুত্বপূর্ণ পরীক্ষা বা প্রেজেন্টেশনের আগে দুশ্চিন্তা হওয়া',
      ),
      SituationTarget(
        id: '2',
        emotionId: 'happy',
        situationEn: 'Meeting a dear old friend after a long time',
        situationBn: 'দীর্ঘদিন পর প্রিয় কোনো মানুষের সাথে দেখা হওয়া',
      ),
      SituationTarget(
        id: '3',
        emotionId: 'calm',
        situationEn: 'Feeling peaceful after completing a 4-7-8 breathing session',
        situationBn: 'মাইন্ডফুলনেস ও শ্বাসের ব্যায়ামের পর হালকা অনুভূতি',
      ),
      SituationTarget(
        id: '4',
        emotionId: 'excited',
        situationEn: 'Getting an offer letter for your dream achievement',
        situationBn: 'স্বপ্নের কোনো কাজে বড় সাফল্য বা অফার পাওয়া',
      ),
      SituationTarget(
        id: '5',
        emotionId: 'sad',
        situationEn: 'Losing a favourite memory item unexpectedly',
        situationBn: 'নিজের কোনো প্রিয় স্মারক বস্তু হারিয়ে যাওয়া',
      ),
      SituationTarget(
        id: '6',
        emotionId: 'angry',
        situationEn: 'Facing unfair treatment or unexpected obstacles',
        situationBn: 'অহেতুক কোনো বাধার সম্মুখীন হওয়া বা বিরক্ত বোধ করা',
      ),
    ]..shuffle();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isCompleted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });

    setState(() {});
  }

  void _checkGameCompletion() {
    bool allMatched = _targets.every((t) => t.matchedEmotion != null);
    if (allMatched && !_isCompleted) {
      _isCompleted = true;
      _timer?.cancel();
      _onGameFinished();
    }
  }

  Future<void> _onGameFinished() async {
    final gameData = await GameScoreService.saveScore(
      gameId: 'mood_match',
      score: _score,
      durationSeconds: _secondsElapsed,
    );

    if (mounted) {
      _showEncouragementDialog(gameData);
    }
  }

  void _showEncouragementDialog(GameScoreData gameData) {
    final isBn = Provider.of<AppLanguageProvider>(context, listen: false).isBangla;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Icon(Icons.celebration_rounded, color: Color(0xFFF59E0B), size: 48),
            const SizedBox(height: 10),
            Text(
              isBn ? 'দুর্দান্ত মানসিক ম্যাচ!' : 'Awesome Emotion Match!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBn
                  ? 'আপনি অনুভূতির সঠিক বোধগম্যতা অর্জন করেছেন। নিজের আবেগকে চেনা মানসিক সুস্থতার প্রথম ধাপ!'
                  : 'You successfully matched all emotional states! Understanding your feelings is the first step to mental wellness.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
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
                  _buildResultRow(isBn ? 'অর্জিত পয়েন্ট' : 'Score Earned', '+$_score Points'),
                  const Divider(height: 16),
                  _buildResultRow(isBn ? 'সময় লেগেছে' : 'Time Taken', '${_secondsElapsed}s'),
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
                    _initGame();
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

  Widget _buildResultRow(String label, String val) {
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
          isBn ? 'মুড ম্যাচ (Drag & Drop)' : 'Mood Match',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black, size: 26),
            onPressed: _initGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Score & Timer Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '$_score Points',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isBn ? 'উপযুক্ত ইমোজিটি টেনে নিচের বাক্সে বসান' : 'Drag emotion badge into matching scenario',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Draggable Emotion Badges Row
            Container(
              height: 75,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _availableEmotions.length,
                itemBuilder: (context, idx) {
                  final emotion = _availableEmotions[idx];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Draggable<EmotionItem>(
                      data: emotion,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: emotion.color,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: emotion.color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emotion.emoji, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Text(
                                isBn ? emotion.nameBn : emotion.nameEn,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildEmotionBadge(emotion, isBn),
                      ),
                      child: _buildEmotionBadge(emotion, isBn),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Target Situation Cards List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _targets.length,
                itemBuilder: (context, idx) {
                  final target = _targets[idx];
                  final bool isMatched = target.matchedEmotion != null;

                  return DragTarget<EmotionItem>(
                    onAccept: (receivedEmotion) {
                      if (receivedEmotion.id == target.emotionId) {
                        setState(() {
                          target.matchedEmotion = receivedEmotion;
                          _availableEmotions.removeWhere((e) => e.id == receivedEmotion.id);
                          _score += 5;
                        });
                        _checkGameCompletion();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isBn ? 'সঠিক উত্তর! (+৫ পয়েন্ট)' : 'Correct Match! (+5 Points)'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isBn ? 'ভুল উত্তর, আবার চেষ্টা করুন!' : 'Incorrect match, try again!'),
                            backgroundColor: Colors.redAccent,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isMatched ? target.matchedEmotion!.color.withOpacity(0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isMatched
                                ? target.matchedEmotion!.color
                                : (candidateData.isNotEmpty ? AppColors.primary : Colors.white),
                            width: isMatched || candidateData.isNotEmpty ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                isBn ? target.situationBn : target.situationEn,
                                style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (isMatched)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: target.matchedEmotion!.color,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Text(target.matchedEmotion!.emoji, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 6),
                                    Text(
                                      isBn ? target.matchedEmotion!.nameBn : target.matchedEmotion!.nameEn,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                width: 90,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white, style: BorderStyle.solid),
                                ),
                                child: Center(
                                  child: Text(
                                    isBn ? 'ড্রপ করুন' : 'Drop here',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionBadge(EmotionItem item, bool isBn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(
            isBn ? item.nameBn : item.nameEn,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
