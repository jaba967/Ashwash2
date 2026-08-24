import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../community/community_screen.dart';
import '../../courses/presentation/screens/course_catalog_screen.dart';
import '../../appointments/specialist_list_screen.dart';
import '../../knowledge_hub/knowledge_hub_screen.dart';



class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'APPOINTMENT':
        return Icons.calendar_month_rounded;
      case 'COURSE':
        return Icons.school_rounded;
      case 'COMMUNITY':
        return Icons.forum_rounded;
      case 'PROFILE':
        return Icons.verified_user_rounded;
      case 'KNOWLEDGE_HUB':
        return Icons.library_books_rounded;
      case 'SYSTEM':
        return Icons.shield_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'APPOINTMENT':
        return const Color(0xFF3B82F6);
      case 'COURSE':
        return const Color(0xFFF59E0B);
      case 'COMMUNITY':
        return const Color(0xFF8B5CF6);
      case 'PROFILE':
        return const Color(0xFF10B981);
      case 'KNOWLEDGE_HUB':
        return const Color(0xFF06B6D4);
      case 'SYSTEM':
        return const Color(0xFFEF4444);
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  String _getDateGroup(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final notifDate = DateTime(dt.year, dt.month, dt.day);
      final diff = today.difference(notifDate).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      return 'Older';
    } catch (_) {
      return 'Older';
    }
  }

  Map<String, List<NotificationModel>> _groupNotifications(List<NotificationModel> list) {
    final Map<String, List<NotificationModel>> grouped = {
      'Today': [],
      'Yesterday': [],
      'Older': [],
    };
    for (final item in list) {
      final group = _getDateGroup(item.createdAt);
      grouped[group]?.add(item);
    }
    return grouped;
  }

  String? _extractUrl(String text) {
    final regExp = RegExp(r'https?://[^\s)]+', caseSensitive: false);
    final match = regExp.firstMatch(text);
    return match?.group(0);
  }

  Future<void> _launchExternalUrl(String urlStr) async {
    try {
      final uri = Uri.parse(urlStr.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.primary, // #4E1F6E Deep Purple Header
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (provider.notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: Colors.white,
              onSelected: (val) {
                if (val == 'read_all') {
                  provider.markAllAsRead();
                } else if (val == 'clear_all') {
                  _showClearAllDialog(context, provider);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'read_all',
                  child: Row(
                    children: [
                      const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Mark all as read',
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('Clear all notifications',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.notifications.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => provider.fetchNotifications(),
                  child: _buildGroupedList(provider, isDark),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We will notify you about your appointments, courses, and wellness updates here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList(NotificationProvider provider, bool isDark) {
    final grouped = _groupNotifications(provider.notifications);
    final sections = ['Today', 'Yesterday', 'Older']
        .where((key) => grouped[key] != null && grouped[key]!.isNotEmpty)
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: sections.length,
      itemBuilder: (context, sIdx) {
        final sectionName = sections[sIdx];
        final items = grouped[sectionName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
              child: Text(
                sectionName.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.grey.shade600 : const Color(0xFF94A3B8),
                ),
              ),
            ),
            ...items.map((notif) => _buildNotificationCard(notif, provider, isDark)),
          ],
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notif, NotificationProvider provider, bool isDark) {
    final color = _getColorForType(notif.type);
    final icon = _getIconForType(notif.type);
    final isUnread = !notif.isRead;
    final extractedUrl = _extractUrl('${notif.title} ${notif.body}');

    return Dismissible(
      key: Key('notif_${notif.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        provider.deleteNotification(notif.id);
      },
      child: GestureDetector(
        onTap: () {
          if (isUnread) {
            provider.markAsRead(notif.id);
          }
          if (extractedUrl != null) {
            _launchExternalUrl(extractedUrl);
          } else {
            _handleNotificationNavigation(context, notif);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? (isUnread ? const Color(0xFF1A1A1A) : const Color(0xFF111111))
                : (isUnread ? Colors.white : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? color.withOpacity(0.4)
                  : (isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
              width: isUnread ? 1.5 : 1.0,
            ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            notif.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(notif.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Render Clickable Body Text
                    _buildClickableNotificationBody(notif.body, isUnread, isDark),

                    // Direct Action Join Button if URL Present
                    if (extractedUrl != null) ...[
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => _launchExternalUrl(extractedUrl),
                        icon: const Icon(Icons.video_call_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          'Join Video Session ➔',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClickableNotificationBody(String text, bool isUnread, bool isDark) {
    final regExp = RegExp(r'https?://[^\s)]+', caseSensitive: false);
    final matches = regExp.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isDark
              ? (isUnread ? Colors.grey.shade300 : Colors.grey.shade500)
              : (isUnread ? const Color(0xFF334155) : const Color(0xFF64748B)),
          height: 1.35,
        ),
      );
    }

    final spans = <InlineSpan>[];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? (isUnread ? Colors.grey.shade300 : Colors.grey.shade500)
                : (isUnread ? const Color(0xFF334155) : const Color(0xFF64748B)),
            height: 1.35,
          ),
        ));
      }

      final urlStr = match.group(0)!;
      spans.add(
        TextSpan(
          text: urlStr,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
            height: 1.35,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launchExternalUrl(urlStr),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(
          fontSize: 13,
          color: isDark
              ? (isUnread ? Colors.grey.shade300 : Colors.grey.shade500)
              : (isUnread ? const Color(0xFF334155) : const Color(0xFF64748B)),
          height: 1.35,
        ),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  void _handleNotificationNavigation(BuildContext context, NotificationModel notif) {
    final type = notif.type.toUpperCase();
    final relType = (notif.relatedObjectType ?? '').toUpperCase();

    // Homework feedback: open inline review bottom sheet
    if (relType == 'HOMEWORK_SUBMISSION' && notif.relatedObjectId != null) {
      _showHomeworkFeedbackSheet(context, notif);
      return;
    }

    if (type == 'COMMUNITY' || relType == 'POST' || relType == 'COMMENT') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CommunityScreen()),
      );
    } else if (type == 'COURSE' || relType == 'COURSE' || relType == 'ASSIGNMENT' || relType == 'CERTIFICATE') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CourseCatalogScreen(
            categoryId: 'ALL',
            categoryTitle: 'Courses & Wellness',
          ),
        ),
      );
    } else if (type == 'APPOINTMENT' || relType == 'APPOINTMENT' || relType == 'PRESCRIPTION') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SpecialistListScreen()),
      );
    } else if (type == 'KNOWLEDGE_HUB' || relType == 'RESOURCE') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KnowledgeHubScreen()),
      );
    }
  }

  Future<void> _showHomeworkFeedbackSheet(
    BuildContext context,
    NotificationModel notif,
  ) async {
    // Show sheet immediately with a loader, then fill data from API
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HomeworkFeedbackSheet(
        submissionId: notif.relatedObjectId!,
        notificationTitle: notif.title,
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('This will remove all notifications from your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteAllNotifications();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Homework Feedback Bottom Sheet ────────────────────────────────────────────

class _HomeworkFeedbackSheet extends StatefulWidget {
  final String submissionId;
  final String notificationTitle;

  const _HomeworkFeedbackSheet({
    required this.submissionId,
    required this.notificationTitle,
  });

  @override
  State<_HomeworkFeedbackSheet> createState() => _HomeworkFeedbackSheetState();
}

class _HomeworkFeedbackSheetState extends State<_HomeworkFeedbackSheet> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _submission;

  static const String _baseUrl = 'https://ashwash-backend.onrender.com/api';

  @override
  void initState() {
    super.initState();
    _fetchSubmission();
  }

  Future<void> _fetchSubmission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_access_token');

      final uri = Uri.parse(
        '$_baseUrl/courses/homework/submissions/${widget.submissionId}/detail/',
      );
      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          _submission = jsonDecode(res.body) as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load feedback. Please try again.';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.rate_review_rounded,
                        color: Color(0xFFF59E0B),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Specialist Feedback',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Your homework has been reviewed',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),

              const Divider(height: 24, color: Color(0xFFE2E8F0)),

              // Body
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wifi_off_rounded,
                                      size: 48, color: Color(0xFFCBD5E1)),
                                  const SizedBox(height: 12),
                                  Text(_error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Color(0xFF64748B))),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isLoading = true;
                                        _error = null;
                                      });
                                      _fetchSubmission();
                                    },
                                    child: const Text('Retry',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildContent(scrollCtrl),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollCtrl) {
    final sub = _submission!;
    final feedback = (sub['specialist_feedback'] as String? ?? '').trim();
    final answers = sub['answers'] as List<dynamic>? ?? [];
    final courseName = sub['course_name'] as String? ?? '';
    final lessonName = sub['lesson_name'] as String? ?? '';
    final submittedAt = _formatDate(sub['submitted_at'] as String?);
    final reviewedAt = _formatDate(sub['reviewed_at'] as String?);
    final isReviewed = (sub['status'] as String? ?? '') == 'reviewed';

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        // ── Meta info card ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _infoRow(Icons.school_rounded, 'Course', courseName),
              const SizedBox(height: 8),
              _infoRow(Icons.book_rounded, 'Lesson / Task', lessonName),
              const SizedBox(height: 8),
              _infoRow(Icons.schedule_rounded, 'Submitted', submittedAt),
              if (reviewedAt.isNotEmpty) ...[
                const SizedBox(height: 8),
                _infoRow(Icons.done_all_rounded, 'Reviewed On', reviewedAt,
                    iconColor: Colors.green),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Feedback Box ──────────────────────────────────────────
        if (isReviewed) ...[
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Specialist Feedback',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B).withOpacity(0.08),
                  const Color(0xFFF59E0B).withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
            ),
            child: feedback.isNotEmpty
                ? Text(
                    feedback,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF334155),
                      height: 1.55,
                    ),
                  )
                : const Text(
                    'No written feedback was provided.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Patient's Answers ─────────────────────────────────────
        if (answers.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Your Answers',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...answers.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final ans = entry.value as Map<String, dynamic>;
            final qText = ans['question_text'] as String? ?? 'Question $idx';
            final aText = (ans['answer_text'] as String? ?? '').trim();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q$idx. $qText',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    aText.isNotEmpty ? aText : '(No answer provided)',
                    style: TextStyle(
                      fontSize: 13,
                      color: aText.isNotEmpty
                          ? const Color(0xFF334155)
                          : const Color(0xFF94A3B8),
                      fontStyle:
                          aText.isEmpty ? FontStyle.italic : FontStyle.normal,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color iconColor = const Color(0xFF94A3B8)}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}

