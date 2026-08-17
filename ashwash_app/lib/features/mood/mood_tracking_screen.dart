import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_language_provider.dart';

class MoodTrackingScreen extends StatefulWidget {
  const MoodTrackingScreen({Key? key}) : super(key: key);

  @override
  State<MoodTrackingScreen> createState() => _MoodTrackingScreenState();
}

class _MoodTrackingScreenState extends State<MoodTrackingScreen> {
  int _selectedMood = 1;
  final TextEditingController _noteController = TextEditingController();

  final List<Map<String, String>> _moods = [
    {'emoji': '😃', 'labelEn': 'Awesome', 'labelBn': 'দুর্দান্ত'},
    {'emoji': '😊', 'labelEn': 'Happy', 'labelBn': 'খুশি'},
    {'emoji': '😐', 'labelEn': 'Neutral', 'labelBn': 'স্বাভাবিক'},
    {'emoji': '😔', 'labelEn': 'Sad', 'labelBn': 'দুঃখিত'},
    {'emoji': '😢', 'labelEn': 'Awful', 'labelBn': 'খুব খারাপ'},
  ];

  @override
  Widget build(BuildContext context) {
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'মুড ট্র্যাকার' : 'Mood Tracker', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isBn ? 'আজ আপনি কেমন অনুভব করছেন?' : 'How are you feeling right now?', style: AppTypography.heading2(context)),
            const SizedBox(height: 20),

            // Emoji selector row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_moods.length, (index) {
                final m = _moods[index];
                final isSelected = _selectedMood == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = index),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 10)] : [],
                        ),
                        child: Text(m['emoji']!, style: const TextStyle(fontSize: 30)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isBn ? m['labelBn']! : m['labelEn']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),

            // Note Input
            Text(isBn ? 'নোট লিখুন (ঐচ্ছিক)' : 'Add a note (optional)', style: AppTypography.heading3(context)),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isBn ? 'আপনার মন খারাপ বা ভালো লাগার কারণ লিখুন...' : 'Write down what triggered this mood...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isBn ? 'মুড লগ সংরক্ষণ করা হয়েছে!' : 'Mood logged successfully!')),
                  );
                  Navigator.pop(context);
                },
                child: Text(isBn ? 'সংরক্ষণ করুন' : 'Save Mood', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
