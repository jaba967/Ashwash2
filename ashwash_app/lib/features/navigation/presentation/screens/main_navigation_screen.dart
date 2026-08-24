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
          color: AppColors.lightMint, // #98E8DE Light Mint Bottom Nav Background
          boxShadow: [
            BoxShadow(
              color: AppColors.darkIndigo.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: AppColors.accent, // #45A9A9 Teal Active Indicator
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
            backgroundColor: AppColors.lightMint, // #98E8DE Light Mint Nav Background
            selectedItemColor: AppColors.primary, // #4E1F6E Deep Purple Selected
            unselectedItemColor: AppColors.secondary, // #3E3E75 Dark Indigo Unselected
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.secondary),
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
