import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/providers/specialist_provider.dart';

class SpecialistAppointmentsScreen extends StatefulWidget {
  final String initialTab;
  const SpecialistAppointmentsScreen({super.key, this.initialTab = 'ALL'});

  @override
  State<SpecialistAppointmentsScreen> createState() => _SpecialistAppointmentsScreenState();
}

class _SpecialistAppointmentsScreenState extends State<SpecialistAppointmentsScreen> {
  late String _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  Future<void> _launchMeeting(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening Google Meet Video Session: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<AppLanguageProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final specProvider = Provider.of<SpecialistProvider>(context);
    final allApps = specProvider.appointments;

    final tabs = [
      {'key': 'ALL', 'labelEn': 'All', 'labelBn': 'সব'},
      {'key': 'TODAY', 'labelEn': "Today's", 'labelBn': 'আজকের'},
      {'key': 'UPCOMING', 'labelEn': 'Upcoming', 'labelBn': 'আসন্ন'},
      {'key': 'COMPLETED', 'labelEn': 'Completed', 'labelBn': 'সম্পন্ন'},
    ];

    final filtered = allApps.where((a) {
      if (_selectedTab == 'TODAY') return a.date == 'Today';
      if (_selectedTab == 'UPCOMING') return a.date != 'Today' && a.status != 'completed';
      if (_selectedTab == 'COMPLETED') return a.status == 'completed';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isBn ? 'অ্যাপয়েন্টমেন্ট ও ভিডিও সেশন' : 'Appointments & Video Sessions',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tabs Filter Row
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppColors.glassSurface,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isSelected = _selectedTab == tab['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(isBn ? tab['labelBn']! : tab['labelEn']!),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    onSelected: (_) => setState(() => _selectedTab = tab['key']!),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Appointments Feed
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      isBn ? 'কোনো সেশন নেই' : 'No sessions found',
                      style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final app = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.glassSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: NetworkImage(app.patientAvatar),
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
                                          fontSize: 16,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${app.date} • ${app.timeSlot}',
                                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
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
                            Text(
                              'Category: ${app.category}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary),
                            ),
                            if (app.notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Notes: ${app.notes}',
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                              ),
                            ],
                            const SizedBox(height: 16),

                            // Video Session & Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _launchMeeting(app.meetingLink),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                                    label: Text(
                                      isBn ? 'ভিডিও সেশন (Google Meet)' : 'Start Video (Google Meet)',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (app.status == 'pending')
                                  IconButton(
                                    onPressed: () {
                                      specProvider.updateAppointmentStatus(app.id, 'confirmed');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Appointment Approved & Confirmed!')),
                                      );
                                    },
                                    icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
