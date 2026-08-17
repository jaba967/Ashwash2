import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/knowledge_hub_provider.dart';
import '../../../../core/providers/language_provider.dart';
import 'interactive_memory_game_screen.dart';

class MindGamesScreen extends StatelessWidget {
  const MindGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hubProvider = Provider.of<KnowledgeHubProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final difficultyTabs = [
      {'key': 'ALL', 'labelEn': 'All', 'labelBn': 'সব'},
      {'key': 'EASY', 'labelEn': 'Easy', 'labelBn': 'সহজ'},
      {'key': 'MEDIUM', 'labelEn': 'Medium', 'labelBn': 'মাঝারি'},
      {'key': 'HARD', 'labelEn': 'Hard', 'labelBn': 'কঠিন'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'মাইন্ড গেম' : 'Mind Games'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Banner Title Card (Matching Figma Page 5)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
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
                      child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn ? 'মাইন্ড গেম' : 'Mind Games',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isBn ? 'মজার গেমের মাধ্যমে মানসিক স্বাস্থ্য উন্নত করুন' : 'Improve mental wellness through fun games',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Difficulty Filter Tabs (Matching Figma Page 5)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              children: difficultyTabs.map((tab) {
                final isSelected = hubProvider.selectedGameDifficulty == tab['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      isBn ? tab['labelBn']! : tab['labelEn']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      hubProvider.setGameDifficulty(tab['key']!);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Games List View
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: hubProvider.mindGames.length,
              itemBuilder: (context, index) {
                final game = hubProvider.mindGames[index];
                final difficulty = game['difficulty'] ?? 'EASY';
                final benefits = (game['benefits'] as String? ?? '').split(',');

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge & Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 28),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: difficulty == 'EASY'
                                  ? AppColors.success.withOpacity(0.15)
                                  : AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              difficulty,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: difficulty == 'EASY' ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Text(
                        game['title'] ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        game['description'] ?? '',
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),

                      // Time & Category Metadata
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text('${game['duration_mins']} min', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 16),
                          Icon(Icons.bolt_rounded, size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(game['category'] ?? 'Brain', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Benefits Chips Row (Matching Figma Page 5)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: benefits.map((benefit) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              benefit.trim(),
                              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Start Game Pill Button (Matching Figma Page 5)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const InteractiveMemoryGameScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(
                            isBn ? 'গেম শুরু করুন' : 'Start Game',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
