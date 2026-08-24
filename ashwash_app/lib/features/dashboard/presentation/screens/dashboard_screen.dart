import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/dashboard_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/my_courses_list.dart';
import '../../../profile/my_enrolled_courses_screen.dart';
import '../../../hub/presentation/screens/knowledge_hub_screen.dart';
import '../../../mind_games/mind_games_hub_screen.dart';
import '../../../courses/presentation/screens/course_catalog_screen.dart';
import '../../../appointments/specialist_list_screen.dart';
import '../../../notifications/screens/notification_screen.dart';
import '../../../../core/providers/notification_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.lightGrayishGreen, // #F0F8F0 Light Grayish Green Canvas
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.deepForestGreen, // #2E8B57 Deep Forest Green Header
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 36,
              width: 36,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.health_and_safety, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 10),
            const Text(
              'Ashwash',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 28, color: Colors.white),
                if (notifProvider.unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.accent, // #45A9A9 Teal badge
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        notifProvider.unreadCount > 99 ? '99+' : '${notifProvider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dashboardProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => dashboardProvider.fetchDashboardData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 2. Quick Actions 2x2 Grid
                    QuickActionsGrid(
                      onActionTap: (route) {
                        if (route == 'knowledge_hub') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const KnowledgeHubScreen()),
                          );
                        } else if (route == 'mind_game') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MindGamesHubScreen()),
                          );
                        } else if (route == 'browse_courses') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CourseCatalogScreen(
                                categoryId: 'ALL',
                                categoryTitle: 'Browse Courses',
                              ),
                            ),
                          );
                        } else if (route == 'book_session') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SpecialistListScreen()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Navigating to $route...')),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // 3. My Courses Section
                    MyCoursesList(
                      onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyEnrolledCoursesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
