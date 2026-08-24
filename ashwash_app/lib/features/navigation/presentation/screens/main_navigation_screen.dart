import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/dashboard_provider.dart';
import '../../../../core/providers/specialist_provider.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../community/community_screen.dart';
import '../../../profile/profile_screen.dart';
import '../../../../core/services/fcm_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    FCMService.initFCM(context);
    // Fetch fresh data for the logged-in user from backend on every login/entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
      Provider.of<SpecialistProvider>(context, listen: false).fetchPatientBookedSessionsFromBackend();
    });
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkForestSurface : AppColors.paleGreen, // #2C3E3F in Dark, #E0EEE0 in Light
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : AppColors.primary.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: isDark
                ? AppColors.deepForestGreen.withOpacity(0.5)
                : AppColors.goldenrod.withOpacity(0.4),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              if (index == 0) {
                Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? AppColors.darkForestSurface : AppColors.paleGreen,
            selectedItemColor: isDark ? AppColors.sageGreen : AppColors.deepForestGreen,
            unselectedItemColor: isDark ? AppColors.sageGreen.withOpacity(0.7) : AppColors.charcoalGray,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isDark ? AppColors.sageGreen : AppColors.deepForestGreen,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isDark ? AppColors.sageGreen.withOpacity(0.7) : AppColors.charcoalGray,
            ),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined),
                activeIcon: Icon(Icons.groups_rounded),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
