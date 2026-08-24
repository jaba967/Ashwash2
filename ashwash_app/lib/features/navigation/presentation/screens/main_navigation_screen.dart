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
          color: AppColors.paleGreen, // #E0EEE0 Pale Green Bottom Nav Surface
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: AppColors.goldenrod.withOpacity(0.4), // #DAA520 Goldenrod Active Indicator
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
            backgroundColor: AppColors.paleGreen, // #E0EEE0 Pale Green Surface
            selectedItemColor: AppColors.deepForestGreen, // #2E8B57 Deep Forest Green Selected
            unselectedItemColor: AppColors.charcoalGray, // #36454F Charcoal Gray Unselected
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.deepForestGreen),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.charcoalGray),
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
