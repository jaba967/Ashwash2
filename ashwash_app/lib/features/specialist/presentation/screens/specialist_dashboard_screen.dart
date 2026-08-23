import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/specialist_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../community/community_screen.dart';
import 'complete_specialist_profile_screen.dart';
import 'specialist_patient_management_screen.dart';
import 'specialist_appointments_screen.dart';
import 'specialist_homework_review_screen.dart';
import 'specialist_course_management_screen.dart';
import 'specialist_course_creator_screen.dart';

class SpecialistDashboardScreen extends StatelessWidget {
  const SpecialistDashboardScreen({super.key});

  Future<void> _launchMeeting(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening Google Meet Video Session: $url')),
        );
      }
    }
  }

  void _showRatingModal(BuildContext context, SpecialistProfileModel profile, bool isBn, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 54),
            const SizedBox(height: 12),
            Text(
              '${profile.rating} / 5.0 Rating',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
            Text(
              'Based on ${profile.totalReviews} verified patient reviews',
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              isBn ? '"ডঃ মেখলা সরকারের কাউন্সেলিং আমার পোস্টপার্টাম জীবন পরিবর্তন করেছে।"' : '"Dr. Mekhala\'s counseling completely transformed my postpartum journey."',
              textAlign: TextAlign.center,
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<AppLanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = themeProvider.isDarkMode || Theme.of(context).brightness == Brightness.dark;
    final authUser = Provider.of<AuthProvider>(context).currentUser;
    final specProvider = Provider.of<SpecialistProvider>(context);
    final profile = specProvider.profile;

    final String doctorName = authUser != null && authUser.firstName.isNotEmpty
        ? '${authUser.firstName} ${authUser.lastName}'.trim()
        : profile.fullName;
    final String avatarUrl = profile.avatarUrl ?? 'https://corecdn.doctime.com.bd/persons/578875/profile_photos/Fe6ibomQLhBJuUQFq4cjQGkAnPeWDtUsO8AOMqIn.png';

    final todayAppointments = specProvider.appointments.where((a) => a.date == 'Today').toList();
    final pendingHW = specProvider.pendingHomeworkSubmissions;
    final activeCourses = specProvider.createdCourses;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            ClipOval(
              child: Image.network(
                avatarUrl,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  width: 36,
                  height: 36,
                  color: AppColors.primary.withOpacity(0.15),
                  child: const Icon(Icons.person_rounded, size: 20, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  isBn ? 'সাইকোলজিস্ট প্যানেল' : 'Specialist Panel',
                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompleteSpecialistProfileScreen())),
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: isDark ? Colors.white : Colors.black),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Specialist Banner Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? 'স্বাগতম, $doctorName' : 'Welcome, $doctorName',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile.specialization,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        isBn ? 'ভেরিফাইড স্পেশালিস্ট অ্যাকাউন্ট' : 'Verified Specialist Account',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Summary Metrics Grid (6 Relatable & Clickable Tiles)
            Text(
              isBn ? 'আজকের ওভারভিউ (ক্লিক করুন)' : 'Overview Metrics (Clickable)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: [
                _buildClickableMetricTile(
                  context,
                  count: todayAppointments.length.toString(),
                  label: isBn ? 'আজকের সেশন' : "Today's Sessions",
                  icon: Icons.video_camera_front_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialistAppointmentsScreen(initialTab: 'TODAY'))),
                ),
                _buildClickableMetricTile(
                  context,
                  count: pendingHW.length.toString(),
                  label: isBn ? 'পেন্ডিং হোমওয়ার্ক' : 'Pending HW',
                  icon: Icons.pending_actions_rounded,
                  color: Colors.orange,
                  isDark: isDark,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialistHomeworkReviewScreen())),
                ),
                _buildClickableMetricTile(
                  context,
                  count: activeCourses.length.toString(),
                  label: isBn ? 'সক্রিয় কোর্স' : 'Active Courses',
                  icon: Icons.auto_stories_rounded,
                  color: Colors.purple,
                  isDark: isDark,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialistCourseManagementScreen())),
                ),

                _buildClickableMetricTile(
                  context,
                  count: '${profile.totalReviews}',
                  label: isBn ? 'সম্পন্ন সেশন' : 'Completed',
                  icon: Icons.verified_user_rounded,
                  color: Colors.teal,
                  isDark: isDark,
                  onTap: null,
                ),
                _buildClickableMetricTile(
                  context,
                  count: '৳${profile.consultationFee}',
                  label: isBn ? 'সেশন ফি' : 'Fee (BDT)',
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.green,
                  isDark: isDark,
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions Section
            Text(
              isBn ? 'দ্রুত পদক্ষেপ' : 'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildActionCard(
                  context,
                  title: isBn ? 'রোগী ব্যবস্থাপনা' : 'Patient Directory',
                  subtitle: isBn ? 'হিস্ট্রি ও নোটস' : 'Charts & Notes',
                  icon: Icons.people_outline_rounded,
                  color: AppColors.primary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialistPatientManagementScreen())),
                  isDark: isDark,
                ),
                _buildActionCard(
                  context,
                  title: isBn ? 'সেশন ও অ্যাপয়েন্টমেন্ট' : 'Appointments',
                  subtitle: isBn ? 'অনলাইন সেশন ম্যানেজ' : 'Video Meetings',
                  icon: Icons.videocam_outlined,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialistAppointmentsScreen())),
                  isDark: isDark,
                ),
                _buildActionCard(
                  context,
                  title: isBn ? 'হোমওয়ার্ক রিভিউ' : 'Homework Review',
                  subtitle: isBn ? 'মূল্যায়ন ও ফিডব্যাক' : 'Grade Submissions',
                  icon: Icons.rate_review_outlined,
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialistHomeworkReviewScreen())),
                  isDark: isDark,
                ),
                _buildActionCard(
                  context,
                  title: isBn ? 'কোর্স তৈরি ও ম্যানেজ' : 'Course Manager',
                  subtitle: isBn ? 'ভিডিও/PDF আপলোড' : 'Manage Courses',
                  icon: Icons.auto_stories_rounded,
                  color: Colors.purple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialistCourseManagementScreen())),
                  isDark: isDark,
                ),
                _buildActionCard(
                  context,
                  title: isBn ? 'কমিউনিটি উত্তর' : 'Community Reply',
                  subtitle: isBn ? 'ভেরিফাইড ব্যাজ উত্তর' : 'Verified Answers',
                  icon: Icons.forum_outlined,
                  color: Colors.pink,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen()));
                  },
                  isDark: isDark,
                ),
                _buildActionCard(
                  context,
                  title: isBn ? 'প্রোফাইল ও সেটিংস' : 'Profile Settings',
                  subtitle: isBn ? 'সময় ও ফি আপডেট' : 'Edit Doctor Profile',
                  icon: Icons.person_pin_rounded,
                  color: Colors.teal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompleteSpecialistProfileScreen())),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Today's Appointments Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isBn ? 'আজকের অ্যাপয়েন্টমেন্ট' : "Today's Appointments",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialistAppointmentsScreen())),
                  child: Text(isBn ? 'সব দেখুন' : 'View All', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...todayAppointments.map((app) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white : Colors.white),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipOval(
                            child: Image.network(
                              app.patientAvatar,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                width: 44,
                                height: 44,
                                color: AppColors.primary.withOpacity(0.15),
                                child: const Icon(Icons.person_rounded, size: 24, color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.patientName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  '${app.timeSlot} • ${app.category}',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: app.status == 'confirmed' ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              app.status.toUpperCase(),
                              style: TextStyle(
                                color: app.status == 'confirmed' ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _launchMeeting(context, app.meetingLink),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                              label: Text(
                                isBn ? 'ভিডিও সেশন শুরু করুন (Google Meet)' : 'Start Session (Google Meet)',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableMetricTile(
    BuildContext context, {
    required String count,
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: Colors.white) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: isDark ? Colors.white : Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white : Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
