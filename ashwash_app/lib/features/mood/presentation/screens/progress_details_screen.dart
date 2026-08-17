import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/dashboard_provider.dart';
import '../../../../core/providers/language_provider.dart';

class ProgressDetailsScreen extends StatelessWidget {
  const ProgressDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'অগ্রগতি' : 'Progress'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big Circular Progress Gauge Card (Matching Figma Page 4 bottom-left)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 20.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
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
                  // Circular Ring with Percentage Center
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: dashboardProvider.courseProgressPercent / 100.0,
                          strokeWidth: 12,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${dashboardProvider.courseProgressPercent}%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isBn
                        ? 'চমৎকার কাজ করছেন! এই ধারাবাহিকতা বজায় রাখুন।'
                        : 'Keep up the great work! You\'re doing amazing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2x2 Metric Counters Grid (Matching Figma Page 4)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.4,
              children: [
                _buildStatBox(
                  context,
                  title: '3/7',
                  label: isBn ? 'লেসন সম্পন্ন' : 'Lessons Completed',
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primary.withOpacity(0.12),
                ),
                _buildStatBox(
                  context,
                  title: '${dashboardProvider.sessionsAttended}',
                  label: isBn ? 'সেশন শেষ' : 'Sessions Attended',
                  icon: Icons.calendar_month_rounded,
                  iconColor: AppColors.categorySpecialChild,
                  iconBg: AppColors.categorySpecialChild.withOpacity(0.12),
                ),
                _buildStatBox(
                  context,
                  title: '${dashboardProvider.tasksCompleted}',
                  label: isBn ? 'টাস্ক সম্পন্ন' : 'Tasks Completed',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppColors.success,
                  iconBg: AppColors.success.withOpacity(0.12),
                ),
                _buildStatBox(
                  context,
                  title: '${dashboardProvider.pointsEarned}',
                  label: isBn ? 'পয়েন্ট অর্জিত' : 'Points Earned',
                  icon: Icons.emoji_events_outlined,
                  iconColor: AppColors.categoryCorporate,
                  iconBg: AppColors.categoryCorporate.withOpacity(0.12),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Course Progress Details Section
            Text(
              isBn ? 'কোর্স ভিত্তিক অগ্রগতি' : 'Course Progress',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            // Enrolled Courses List Items
            ...dashboardProvider.enrolledCourses.map((course) {
              final int progress = course['progress_percentage'] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          course['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '$progress%',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course['completed_lessons']} of ${course['total_lessons']} lessons',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress / 100.0,
                        color: AppColors.primary,
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Motivational Quote Card Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.inputBgLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                isBn
                    ? '"প্রতিটি পদক্ষেপই একটি অগ্রগতি। এগিয়ে যান! 💪"'
                    : '"Every step forward is progress. Keep going! 💪"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(
    BuildContext context, {
    required String title,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
