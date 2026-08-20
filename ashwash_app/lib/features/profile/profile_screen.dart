import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/specialist_provider.dart';
import '../auth/presentation/screens/login_screen.dart';
import '../notifications/screens/notification_screen.dart';
import 'my_enrolled_courses_screen.dart';
import 'my_patient_sessions_screen.dart';
import 'settings_screen.dart';
import 'report_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _coursesCount = 0;
  int _sessionsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser == null) {
        authProvider.fetchProfile();
      }
      _fetchStats();
    });
  }

  Future<void> _fetchStats() async {
    // 1. Fetch booked sessions from backend independently
    try {
      if (mounted) {
        final specProvider = Provider.of<SpecialistProvider>(context, listen: false);
        await specProvider.fetchPatientBookedSessionsFromBackend();
        if (mounted) {
          setState(() {
            _sessionsCount = specProvider.patientBookedSessions.length;
          });
        }
      }
    } catch (_) {}

    // 2. Fetch enrolled courses count from backend independently
    try {
      final enrolledData = await ApiService.get(ApiEndpoints.enrolledCourses, requireAuth: true);
      int coursesCount = 0;
      if (enrolledData is List) {
        coursesCount = enrolledData.length;
      } else if (enrolledData is Map && enrolledData['results'] is List) {
        coursesCount = (enrolledData['results'] as List).length;
      } else if (enrolledData is Map && enrolledData['enrolled_courses'] is List) {
        coursesCount = (enrolledData['enrolled_courses'] as List).length;
      } else if (enrolledData is Map && enrolledData['count'] is int) {
        coursesCount = enrolledData['count'];
      }

      if (!mounted) return;

      Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();

      if (mounted) {
        setState(() {
          _coursesCount = coursesCount;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);

    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = authProvider.currentUser;

    final String displayName = user != null && user.firstName.isNotEmpty
        ? '${user.firstName} ${user.lastName}'.trim()
        : (user?.username.isNotEmpty == true ? user!.username : 'User');
    final String email = user?.email.isNotEmpty == true ? user!.email : 'user@example.com';
    final String initial = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';

    final specialistProvider = Provider.of<SpecialistProvider>(context);
    final int realCoursesCount = _coursesCount;
    final int realSessionsCount = specialistProvider.patientBookedSessions.length > _sessionsCount
        ? specialistProvider.patientBookedSessions.length
        : _sessionsCount;

    // PROFILE PICTURE FROM DEVICE/BACKEND
    ImageProvider? avatarImage;
    final avatarStr = user?.avatar;
    if (avatarStr != null && avatarStr.isNotEmpty) {
      if (avatarStr.startsWith('data:image') || avatarStr.length > 200) {
        try {
          final cleanBase64 = avatarStr.contains(',') ? avatarStr.split(',').last : avatarStr;
          avatarImage = MemoryImage(base64Decode(cleanBase64));
        } catch (_) {}
      } else if (avatarStr.startsWith('http')) {
        avatarImage = NetworkImage(avatarStr);
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          isBn ? 'প্রোফাইল' : 'Profile',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    size: 26,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationScreen()),
                    );
                  },
                ),
                if (notifProvider.unreadCount > 0)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          children: [
            // User Avatar Badge (Supports Uploaded Device Profile Photo)
            Center(
              child: Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA855F7), width: 3),
                  gradient: avatarImage == null
                      ? const LinearGradient(
                          colors: [Color(0xFFC084FC), Color(0xFFA855F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA855F7).withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.transparent,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // User Name
            Text(
              displayName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),

            // User Email
            Text(
              email,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),

            // Real Interactive Stats Cards Row (Clickable to view actual details)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyEnrolledCoursesScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: _buildStatBox(
                      context,
                      count: '$realCoursesCount',
                      label: isBn ? 'কোর্সসমূহ' : 'Courses',
                      icon: Icons.menu_book_rounded,
                      iconColor: const Color(0xFFA855F7),
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyPatientSessionsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: _buildStatBox(
                      context,
                      count: '$realSessionsCount',
                      label: isBn ? 'সেশনসমূহ' : 'Sessions',
                      icon: Icons.calendar_today_outlined,
                      iconColor: const Color(0xFF3B82F6),
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Vertical Menu Options Cards
            _buildMenuItemCard(
              context,
              title: isBn ? 'মানসিক স্বাস্থ্য রিপোর্ট' : 'Mental Health Report',
              icon: Icons.assignment_outlined,
              iconColor: const Color(0xFF3B82F6),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildMenuItemCard(
              context,
              title: isBn ? 'সেটিংস (অ্যাকাউন্ট পরিচালনা)' : 'Settings & Account',
              icon: Icons.settings_outlined,
              iconColor: const Color(0xFF64748B),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildMenuItemCard(
              context,
              title: isBn ? 'সহায়তা ও সাপোর্ট' : 'Help & Support',
              icon: Icons.help_outline_rounded,
              iconColor: const Color(0xFF10B981),
              isDark: isDark,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isBn ? 'সাপোর্ট টিম শীঘ্রই আপনার সাথে যোগাযোগ করবে' : 'Support team will contact you shortly'),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // Red Logout Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                label: Text(
                  isBn ? 'লগ আউট' : 'Log Out',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stat Summary Card Widget
  Widget _buildStatBox(
    BuildContext context, {
    required String count,
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Menu List Card Widget with Trailing Arrow Chevron
  Widget _buildMenuItemCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Icon(icon, color: iconColor, size: 22),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            size: 20,
          ),
        ),
      ),
    );
  }
}
