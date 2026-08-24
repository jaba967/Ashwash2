import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/services/game_score_service.dart';
import 'breathing_exercise_screen.dart';
import 'memory_match_screen.dart';
import 'mood_match_screen.dart';

class MindGamesHubScreen extends StatefulWidget {
  const MindGamesHubScreen({Key? key}) : super(key: key);

  @override
  State<MindGamesHubScreen> createState() => _MindGamesHubScreenState();
}

class _MindGamesHubScreenState extends State<MindGamesHubScreen> {
  GameScoreData? _breathingData;
  GameScoreData? _memoryData;
  GameScoreData? _moodData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllGameScores();
  }

  Future<void> _loadAllGameScores() async {
    setState(() => _isLoading = true);
    final breathing = await GameScoreService.getGameData('breathing_exercise');
    final memory = await GameScoreService.getGameData('memory_match');
    final mood = await GameScoreService.getGameData('mood_match');

    if (mounted) {
      setState(() {
        _breathingData = breathing;
        _memoryData = memory;
        _moodData = mood;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.lightGrayishGreen, // #F0F8F0 Light Grayish Green Canvas
      appBar: AppBar(
        backgroundColor: AppColors.deepForestGreen, // #2E8B57 Deep Forest Green Header
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isBn ? 'মাইন্ড গেমসমূহ (Mind Games)' : 'Mind Games Hub',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadAllGameScores,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  // Banner Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC084FC), Color(0xFFA855F7), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA855F7).withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.psychology_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBn
                                        ? 'মাইন্ডফুলনেস ও ব্রেইন ট্রেইনিং'
                                        : 'Wellness & Brain Training',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    isBn
                                        ? 'খেলে খেলে মানসিক চাপ কমান ও মনোযোগ বাড়ান'
                                        : 'Reduce stress and improve focus while playing',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    isBn ? 'গেম নির্বাচন করুন' : 'SELECT A MIND GAME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // GAME 1: Breathing Exercise
                  _buildGameCard(
                    context,
                    isDark: isDark,
                    title: isBn
                        ? 'শ্বাসের ব্যায়াম (Breathing Exercise)'
                        : 'Breathing Exercise',
                    subtitle: isBn
                        ? '৪-৪-৪ রিদ্যমিক শ্বাসের মাধ্যমে প্রশান্তি'
                        : '4-4-4 Rhythmic cycle for instant calm & relaxation',
                    imagePath: 'assets/images/breathing_exercise_icon.jpg',
                    accentColor: const Color(0xFF8B5CF6),
                    bestScore: _breathingData?.bestScore ?? 0,
                    playCount: _breathingData?.playCount ?? 0,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BreathingExerciseScreen()),
                      );
                      _loadAllGameScores();
                    },
                  ),
                  const SizedBox(height: 16),

                  // GAME 2: Memory Match
                  _buildGameCard(
                    context,
                    isDark: isDark,
                    title: isBn ? 'মেমোরি ম্যাচ (Memory Match)' : 'Memory Match',
                    subtitle: isBn
                        ? 'ওয়েলনেস কার্ড মেলাুন ও স্মৃতিশক্তি বাড়ান'
                        : 'Match beautiful wellness cards & train focus',
                    imagePath: 'assets/images/memory_match_icon.jpg',
                    accentColor: const Color(0xFF3B82F6),
                    bestScore: _memoryData?.bestScore ?? 0,
                    playCount: _memoryData?.playCount ?? 0,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MemoryMatchScreen()),
                      );
                      _loadAllGameScores();
                    },
                  ),
                  const SizedBox(height: 16),

                  // GAME 3: Mood Match
                  _buildGameCard(
                    context,
                    isDark: isDark,
                    title: isBn ? 'মুড ম্যাচ (Mood Match)' : 'Mood Match',
                    subtitle: isBn
                        ? 'বাস্তব জীবনের পরিস্থিতির সাথে আবেগ মেলান'
                        : 'Drag & Drop matching emotions with situations',
                    imagePath: 'assets/images/mood_match_icon.jpg',
                    accentColor: const Color(0xFF10B981),
                    bestScore: _moodData?.bestScore ?? 0,
                    playCount: _moodData?.playCount ?? 0,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MoodMatchScreen()),
                      );
                      _loadAllGameScores();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    required String subtitle,
    required String imagePath,
    required Color accentColor,
    required int bestScore,
    required int playCount,
    required VoidCallback onTap,
  }) {
    final isBn = Provider.of<AppLanguageProvider>(context, listen: false).isBangla;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Game Icon Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    imagePath,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 72,
                        height: 72,
                        color: accentColor.withOpacity(0.15),
                        child: Icon(Icons.psychology_rounded,
                            color: accentColor, size: 36),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Card Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.amber.shade900.withOpacity(0.3)
                                  : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? Colors.amber.shade700
                                    : Colors.amber.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Color(0xFFF59E0B), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$bestScore Pts',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF59E0B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$playCount ${isBn ? "বার খেলা হয়েছে" : "Played"}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: isDark ? Colors.grey.shade600 : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
