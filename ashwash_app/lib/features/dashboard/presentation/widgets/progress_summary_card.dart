import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/dashboard_provider.dart';
import '../../../../core/providers/language_provider.dart';

class ProgressSummaryCard extends StatelessWidget {
  final VoidCallback onViewAll;

  const ProgressSummaryCard({super.key, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBn = langProvider.isBangla;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isBn ? 'আপনার অগ্রগতি' : 'Your Progress',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Metrics Summary Row (Matching Figma Page 4 Cards)
        Row(
          children: [
            // Card 1: Course Progress
            Expanded(
              child: _buildMetricCard(
                context,
                title: '${dashboardProvider.courseProgressPercent}%',
                subtitle: isBn ? 'কোর্স অগ্রগতি' : 'Course Progress',
                icon: Icons.menu_book_rounded,
                iconBgColor: AppColors.primary.withOpacity(0.12),
                iconColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),

            // Card 2: Sessions Attended (5)
            Expanded(
              child: _buildMetricCard(
                context,
                title: '${dashboardProvider.sessionsAttended}',
                subtitle: isBn ? 'সেশন শেষ' : 'Sessions Attended',
                icon: Icons.calendar_month_rounded,
                iconBgColor: AppColors.categorySpecialChild.withOpacity(0.12),
                iconColor: AppColors.categorySpecialChild,
              ),
            ),
            const SizedBox(width: 12),

            // Card 3: Tasks Completed (1)
            Expanded(
              child: _buildMetricCard(
                context,
                title: '${dashboardProvider.tasksCompleted}',
                subtitle: isBn ? 'টাস্ক সম্পন্ন' : 'Tasks Completed',
                icon: Icons.trending_up_rounded,
                iconBgColor: AppColors.success.withOpacity(0.12),
                iconColor: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
