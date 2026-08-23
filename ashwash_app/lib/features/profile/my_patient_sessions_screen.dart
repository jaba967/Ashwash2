import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/specialist_provider.dart';
import '../appointments/specialist_list_screen.dart';

class MyPatientSessionsScreen extends StatefulWidget {
  const MyPatientSessionsScreen({Key? key}) : super(key: key);

  @override
  State<MyPatientSessionsScreen> createState() => _MyPatientSessionsScreenState();
}

class _MyPatientSessionsScreenState extends State<MyPatientSessionsScreen> {
  String _selectedFilter = 'all'; // 'all', 'confirmed', 'pending', 'cancelled'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SpecialistProvider>(context, listen: false).fetchPatientBookedSessionsFromBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final specialistProvider = Provider.of<SpecialistProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allAppointments = specialistProvider.patientBookedSessions;

    List<SpecialistAppointmentModel> filteredAppointments = allAppointments;
    if (_selectedFilter == 'confirmed') {
      filteredAppointments = allAppointments.where((a) => a.status.toLowerCase() == 'confirmed' || a.status.toLowerCase() == 'completed').toList();
    } else if (_selectedFilter == 'pending') {
      filteredAppointments = allAppointments.where((a) => a.status.toLowerCase() == 'pending').toList();
    } else if (_selectedFilter == 'cancelled') {
      filteredAppointments = allAppointments.where((a) => a.status.toLowerCase() == 'cancelled' || a.status.toLowerCase() == 'missed').toList();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isBn ? 'আমার বুকিংকৃত সেশনসমূহ' : 'My Booked Sessions',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs (All, Confirmed, Pending, Missed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.glassSurface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', isBn ? 'সকল সেশন (${allAppointments.length})' : 'All (${allAppointments.length})', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('confirmed', isBn ? 'কনফার্মড / সম্পন্ন' : 'Confirmed / Completed', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('pending', isBn ? 'পেন্ডিং (অপেক্ষমান)' : 'Pending', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('cancelled', isBn ? 'মিসড / বাতিল' : 'Missed / Cancelled', isDark),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Session List or Empty State
          Expanded(
            child: filteredAppointments.isEmpty
                ? _buildEmptyState(context, isBn, isDark)
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredAppointments.length,
                    itemBuilder: (context, index) {
                      final app = filteredAppointments[index];
                      return _buildAppointmentCard(context, app, isBn, isDark);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SpecialistListScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          isBn ? 'নতুন সেশন বুক করুন' : 'Book New Session',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, bool isDark) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? const Color(0xFF1E1F2C) : Colors.grey.shade100,
      onSelected: (_) => setState(() => _selectedFilter = filterKey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  /// Parses timeSlot string like "10:00 AM - 11:00 AM" with appointment date
  /// to determine the real-time session window status.
  /// Returns: 'live' | 'expired' | 'upcoming' | 'unknown'
  String _getTimingStatus(String dateStr, String timeSlot) {
    try {
      // Parse appointment date (format: "d/M/yyyy" or "yyyy-MM-dd")
      DateTime? appointmentDate;
      if (dateStr.contains('-')) {
        appointmentDate = DateTime.tryParse(dateStr);
      } else {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          appointmentDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
      if (appointmentDate == null) return 'unknown';

      final parts = timeSlot.split(' - ');
      if (parts.length != 2) return 'unknown';

      DateTime parseTime(String timeStr) {
        final t = timeStr.trim().toUpperCase();
        final isPm = t.endsWith('PM');
        final timePart = t.replaceAll('AM', '').replaceAll('PM', '').trim();
        final hm = timePart.split(':');
        int hour = int.parse(hm[0]);
        final minute = int.parse(hm[1]);
        if (isPm && hour != 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        return DateTime(
          appointmentDate!.year,
          appointmentDate.month,
          appointmentDate.day,
          hour,
          minute,
        );
      }

      final startDt = parseTime(parts[0]);
      final endDt = parseTime(parts[1]);
      final now = DateTime.now();

      if (now.isAfter(startDt) && now.isBefore(endDt)) return 'live';
      if (now.isAfter(endDt)) return 'expired';
      return 'upcoming';
    } catch (_) {
      return 'unknown';
    }
  }

  Widget _buildAppointmentCard(BuildContext context, SpecialistAppointmentModel app, bool isBn, bool isDark) {
    Color statusColor;
    String statusText;

    final statusLower = app.status.toLowerCase();
    if (statusLower == 'confirmed' || statusLower == 'completed') {
      statusColor = const Color(0xFF10B981); // Green
      statusText = isBn ? 'কনফার্মড (সম্পন্ন)' : 'Confirmed / Completed';
    } else if (statusLower == 'pending') {
      statusColor = const Color(0xFFF59E0B); // Amber
      statusText = isBn ? 'পেন্ডিং (অপেক্ষমান)' : 'Pending Review';
    } else {
      statusColor = const Color(0xFFEF4444); // Red
      statusText = isBn ? 'মিসড / বাতিল' : 'Missed / Cancelled';
    }

    // Real-time timing status (only show for pending/confirmed, not completed/cancelled)
    final timingStatus = (statusLower == 'pending' || statusLower == 'confirmed')
        ? _getTimingStatus(app.date, app.timeSlot)
        : null;


    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor / Specialist Info Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                backgroundImage: app.patientAvatar.startsWith('http') ? NetworkImage(app.patientAvatar) : null,
                child: !app.patientAvatar.startsWith('http')
                    ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 28)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(
                        app.specialistName.isNotEmpty ? app.specialistName : 'Dr. Mekhala Sarkar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      isBn ? 'ক্লিনিক্যাল সাইকোলজিস্ট' : 'Clinical Psychologist & Consultant',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // Timing status badge row (shown below header for live/expired sessions)
          if (timingStatus == 'live' || timingStatus == 'expired') ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: timingStatus == 'live'
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : const Color(0xFFEF4444).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: timingStatus == 'live'
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    width: 1,
                  ),
                ),
                child: Text(
                  timingStatus == 'live'
                      ? (isBn ? '🟢 সেশন চলছে' : '🟢 Live Now')
                      : (isBn ? '⏰ মেয়াদ শেষ' : '⏰ Expired'),
                  style: TextStyle(
                    color: timingStatus == 'live'
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Date, Time Slot & Category Details
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${app.date}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                app.timeSlot,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Category Badge
          Row(
            children: [
              const Icon(Icons.category_outlined, size: 18, color: Color(0xFFA855F7)),
              const SizedBox(width: 8),
              Text(
                '${isBn ? 'ক্যাটাগরি' : 'Category'}: ',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              Text(
                app.category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),

          // Action Button (Google Meet Link if confirmed)
          if (statusLower == 'confirmed' && app.meetingLink.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(app.meetingLink);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                icon: const Icon(Icons.video_call_rounded, color: Colors.white, size: 20),
                label: Text(
                  isBn ? 'গুগল মিট সেশনে যুক্ত হন' : 'Join Google Meet Session',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isBn, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isBn ? 'কোনো বুক করা সেশন পাওয়া যায়নি' : 'No Booked Sessions Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBn
                  ? 'মানসিক স্বাস্থ্য বিশেষজ্ঞ ও সাইকোলজিস্টের সাথে সেশন বুক করতে নিচের বাটনে চাপ দিন।'
                  : 'Book a consultation session with expert clinical psychologists to get personalized support.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SpecialistListScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                isBn ? 'বিশেষজ্ঞ সেশন বুক করুন' : 'Book a Specialist Session',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
