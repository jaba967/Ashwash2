import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/mood_progress_provider.dart';
import '../../../../core/providers/language_provider.dart';

class MentalHealthReportScreen extends StatefulWidget {
  const MentalHealthReportScreen({super.key});

  @override
  State<MentalHealthReportScreen> createState() => _MentalHealthReportScreenState();
}

class _MentalHealthReportScreenState extends State<MentalHealthReportScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<MoodProgressProvider>(context, listen: false).fetchMentalHealthReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodProgressProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final report = moodProvider.reportData;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'মানসিক স্বাস্থ্য রিপোর্ট' : 'Mental Health Report'),
        elevation: 0,
      ),
      body: moodProvider.isLoading || report == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title Banner Card (Matching Figma Page 6)
                  Container(
                    width: double.infinity,
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
                      children: [
                        const Icon(Icons.assignment_turned_in_rounded, size: 40, color: Colors.white),
                        const SizedBox(height: 10),
                        Text(
                          isBn ? 'মানসিক স্বাস্থ্য রিপোর্ট' : 'Mental Health Report',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBn ? 'আপনার সামগ্রিক যাত্রার সম্পূর্ণ রেকর্ড' : 'Complete record of your journey',
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 20),

                        // Download Report Button
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Generating PDF report for download...'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                          icon: const Icon(Icons.download_rounded, color: AppColors.primary),
                          label: Text(
                            isBn ? 'রিপোর্ট ডাউনলোড করুন' : 'Download Report',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Overview Grid (2x2)
                  Text(
                    isBn ? 'সংক্ষিপ্ত তথ্য' : 'Overview',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildOverviewStat(
                        context,
                        title: '${report['overview_stats']['courses_enrolled']}',
                        subtitle: isBn ? 'এনরোল্ড কোর্স' : 'Courses Enrolled',
                        icon: Icons.menu_book_rounded,
                        color: AppColors.primary,
                      ),
                      _buildOverviewStat(
                        context,
                        title: '${report['overview_stats']['lessons_completed']}',
                        subtitle: isBn ? 'লেসন সম্পন্ন' : 'Lessons Completed',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.success,
                      ),
                      _buildOverviewStat(
                        context,
                        title: '${report['overview_stats']['sessions_attended']}',
                        subtitle: isBn ? 'সেশন শেষ' : 'Sessions Attended',
                        icon: Icons.calendar_month_rounded,
                        color: AppColors.categorySpecialChild,
                      ),
                      _buildOverviewStat(
                        context,
                        title: '${report['overview_stats']['points_earned']}',
                        subtitle: isBn ? 'পয়েন্ট অর্জিত' : 'Points Earned',
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.categoryCorporate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Specialist Review Notes Section (Matching Figma Page 6)
                  Text(
                    isBn ? 'বিশেষজ্ঞের পরামর্শ ও মন্তব্য' : 'Specialist Notes',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  ...List.generate(
                    (report['specialist_notes'] as List).length,
                    (index) {
                      final note = report['specialist_notes'][index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primary.withOpacity(0.15),
                                  child: const Text('D', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note['specialist_name'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        note['date_str'],
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (starIndex) => const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              note['note'],
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Treatment Timeline Section (Matching Figma Page 6)
                  Text(
                    isBn ? 'চিকিৎসা সময়রেখা' : 'Treatment Timeline',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  ...List.generate(
                    (report['treatment_timeline'] as List).length,
                    (index) {
                      final event = report['treatment_timeline'][index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                                ),
                                if (index < (report['treatment_timeline'] as List).length - 1)
                                  Container(
                                    width: 2,
                                    height: 40,
                                    color: Colors.grey.shade300,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event['date_str'],
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    event['title'],
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  if (event['description'] != null)
                                    Text(
                                      event['description'],
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewStat(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}
