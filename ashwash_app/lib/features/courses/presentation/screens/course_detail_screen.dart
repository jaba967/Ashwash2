import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/api_service.dart' as mock_api;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/dashboard_provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/models/course_model.dart';
import '../../../appointments/specialist_list_screen.dart';
import '../widgets/lesson_player_dialog.dart';
import '../widgets/assignment_modal_dialog.dart';
import '../widgets/quiz_dialog.dart';
import 'course_certificate_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;

  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final Set<String> _completedLessonIds = {};
  final Set<String> _completedAssignmentIds = {};
  double _quizScore = 0.0;
  bool _quizPassed = false;
  Map<String, dynamic>? _issuedCertData;
  bool _hasShownCompletionDialog = false;

  @override
  void initState() {
    super.initState();
    _syncProgressFromBackend();
  }

  Future<void> _loadSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final courseId = widget.course.id;

      final savedLessons = prefs.getStringList('course_${courseId}_completed_lessons') ?? [];
      final savedAssignments = prefs.getStringList('course_${courseId}_completed_assignments') ?? [];
      final savedQuizPassed = prefs.getBool('course_${courseId}_quiz_passed') ?? false;
      final savedIsCompleted = prefs.getBool('course_${courseId}_is_completed') ?? false;

      if (mounted) {
        setState(() {
          _completedLessonIds.addAll(savedLessons);
          _completedAssignmentIds.addAll(savedAssignments);
          _quizPassed = savedQuizPassed;

          if (savedIsCompleted) {
            _hasShownCompletionDialog = true;
            for (var m in widget.course.modules) {
              for (var l in m.lessons) {
                _completedLessonIds.add(l.id);
              }
            }
            for (var a in widget.course.assignments) {
              _completedAssignmentIds.add(a.id);
            }
            if (widget.course.quizQuestions.isNotEmpty) {
              _quizPassed = true;
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveProgressToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final courseId = widget.course.id;

      await prefs.setStringList('course_${courseId}_completed_lessons', _completedLessonIds.toList());
      await prefs.setStringList('course_${courseId}_completed_assignments', _completedAssignmentIds.toList());
      await prefs.setBool('course_${courseId}_quiz_passed', _quizPassed);
      if (_overallProgressPercentage >= 99.0) {
        await prefs.setBool('course_${courseId}_is_completed', true);
      }
    } catch (_) {}
  }

  /// Fetches real completed lesson IDs and course progress from backend.
  Future<void> _syncProgressFromBackend() async {
    await _loadSavedProgress();
    try {
      final int targetCourseId = widget.course.id;
      // Fetch enrolled courses to get completed lesson IDs and progress
      final res = await ApiService.get(ApiEndpoints.enrolledCourses, requireAuth: true);
      if (res is List) {
        for (var item in res) {
          if (item is Map) {
            int? itemCourseId;
            if (item['course'] is Map) {
              itemCourseId = item['course']['id'] is int 
                  ? item['course']['id'] 
                  : int.tryParse(item['course']['id'].toString());
            } else if (item['course'] is int) {
              itemCourseId = item['course'];
            } else if (item['course'] != null) {
              itemCourseId = int.tryParse(item['course'].toString());
            }

            if (itemCourseId != null && itemCourseId == targetCourseId) {
              final bool backendCompleted = item['is_completed'] == true || (item['progress_percentage'] is num && item['progress_percentage'] >= 100);
              if (backendCompleted && mounted) {
                setState(() {
                  _hasShownCompletionDialog = true; // don't re-show popup
                  for (var m in widget.course.modules) {
                    for (var l in m.lessons) {
                      _completedLessonIds.add(l.id);
                    }
                  }
                  for (var a in widget.course.assignments) {
                    _completedAssignmentIds.add(a.id);
                  }
                  if (widget.course.quizQuestions.isNotEmpty) {
                    _quizPassed = true;
                  }
                });
                _saveProgressToLocal();
              }
              break;
            }
          }
        }
      }
      // Sync certificate data
      _checkAndSyncCertificate();
    } catch (_) {}
  }

  int get _totalLessons {
    int total = 0;
    for (var m in widget.course.modules) {
      total += m.lessons.length;
    }
    return total;
  }

  double get _overallProgressPercentage {
    if (_totalLessons == 0) return 0.0;

    double totalWeight = 50.0;
    double earnedWeight = (_completedLessonIds.length / _totalLessons) * 50.0;

    if (widget.course.assignments.isNotEmpty) {
      totalWeight += 30.0;
      earnedWeight += (_completedAssignmentIds.length / widget.course.assignments.length) * 30.0;
    }

    if (widget.course.quizQuestions.isNotEmpty) {
      totalWeight += 20.0;
      earnedWeight += (_quizPassed ? 1.0 : 0.0) * 20.0;
    }

    if (totalWeight == 0.0) return 0.0;
    return (earnedWeight / totalWeight) * 100.0;
  }

  bool get _isCertificateUnlocked {
    if (_issuedCertData != null && _issuedCertData!['recommendation_status'] == 'submitted') {
      return true;
    }
    return false;
  }

  void _checkAndShowCompletionModal() {
    if (_overallProgressPercentage >= 99.0 && !_hasShownCompletionDialog) {
      _hasShownCompletionDialog = true;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Column(
            children: [
              Icon(Icons.workspace_premium_rounded, size: 54, color: Colors.amber),
              SizedBox(height: 10),
              Text(
                '🎉 Course Completed!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Congratulations! You have completed 100% of "${widget.course.titleEn}".',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: const Text(
                  'Your completion certificate request has been sent to your specialist. They will review your performance and issue your official certificate shortly!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Awesome!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _launchVideoUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _checkAndSyncCertificate() async {
    try {
      final String courseIdStr = widget.course.id.toString().replaceAll(RegExp(r'[^0-9]'), '');
      final res = await ApiService.get('${ApiEndpoints.courses}$courseIdStr/certificate/', requireAuth: true);
      if (res is Map<String, dynamic> && mounted) {
        setState(() {
          _issuedCertData = res;
        });
      }
    } catch (_) {}
  }

  void _showCertificateDialog() {
    _checkAndSyncCertificate();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseCertificateScreen(course: widget.course),
      ),
    );
  }

  void _showCoursePaymentModal(BuildContext context, bool isBn, CourseModel course) {
    final mobileController = TextEditingController(text: '01711982341');
    final otpController = TextEditingController(text: '123456');
    final pinController = TextEditingController(text: '12345');
    bool isLoading = false;
    const primaryThemeColor = Color(0xFFE2136E);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBn ? 'bKash কোর্স পেমেন্ট' : 'Course bKash Payment',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryThemeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'bKash Sandbox API',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Invoice Summary Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryThemeColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryThemeColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Invoice: INV-CRS-${course.id}',
                              style: const TextStyle(fontSize: 12, color: primaryThemeColor, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Fee: ৳${course.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.titleEn,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'bKash Mobile Number',
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Verification OTP',
                            prefixIcon: const Icon(Icons.password),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'PIN Code',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryThemeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setModalState(() => isLoading = true);
                              final dashProvider = Provider.of<DashboardProvider>(context, listen: false);
                              final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
                              String verifiedTrxId = 'TR0011${DateTime.now().millisecondsSinceEpoch}';

                              // Call bKash REST API Endpoint
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              final currentUser = authProvider.currentUser;
                              final patientFullName = currentUser != null
                                  ? '${currentUser.firstName} ${currentUser.lastName}'.trim()
                                  : '';
                              final patientDisplayName = patientFullName.isNotEmpty
                                  ? patientFullName
                                  : (currentUser?.username ?? 'Patient');

                              try {
                                const payEndpoint = 'payments/bkash/execute/';
                                final response = await ApiService.post(
                                  payEndpoint,
                                  {
                                    'amount': course.price,
                                    'purpose': 'Course Enrollment: ${course.titleEn}',
                                    'mobile_number': mobileController.text.trim(),
                                    'otp': otpController.text.trim(),
                                    'pin': pinController.text.trim(),
                                    if (currentUser?.id != null) 'patient_id': currentUser!.id,
                                    if (currentUser?.id != null) 'patient': currentUser!.id,
                                    'patient_name': patientDisplayName,
                                    if (currentUser?.email != null) 'patient_email': currentUser!.email,
                                  },
                                  requireAuth: true,
                                );

                                if (response != null && response['transaction_id'] != null) {
                                  verifiedTrxId = response['transaction_id'].toString();
                                }
                              } catch (_) {}

                              // Enroll user in local state & sync backend
                              await dashProvider.enrollCourse({
                                'id': course.id,
                                'title': course.titleEn,
                                'description': course.descriptionEn,
                                'completed_lessons': 0,
                                'total_lessons': _totalLessons,
                                'progress_percentage': 0,
                                'format': 'Both',
                                'instructor': course.instructorName,
                                'specialist': course.specialistName,
                                'price': course.price,
                                'transaction_id': verifiedTrxId,
                              });

                              // Notify Specialist & Admin Portal
                              notifProvider.addNotification(
                                title: isBn ? 'নতুন কোর্স এনরোলমেন্ট!' : 'New Course Enrollment!',
                                message: isBn
                                    ? '${course.specialistName}-এর "${course.titleBn}" কোর্সে সফলতা সহ এনরোলমেন্ট সম্পন্ন হয়েছে। (TrxID: $verifiedTrxId)'
                                    : 'Enrolled in "${course.titleEn}" with ${course.specialistName}. (TrxID: $verifiedTrxId)',
                              );

                              Navigator.pop(modalCtx);
                              if (mounted) {
                                _showEnrollmentSuccessDialog(context, isBn, verifiedTrxId, course);
                              }
                            },
                      child: isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              isBn ? '🔒 পেমেন্ট সম্পন্ন ও এনরোল করুন (৳${course.price.toStringAsFixed(0)})' : '🔒 Confirm & Pay ৳${course.price.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEnrollmentSuccessDialog(BuildContext context, bool isBn, String trxId, CourseModel course) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 54),
              ),
              const SizedBox(height: 16),
              Text(
                isBn ? 'কোর্স এনরোলমেন্ট সফল হয়েছে!' : 'Course Enrolled Successfully!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isBn
                    ? 'আপনি সফলতা সহ "${course.titleBn}" কোর্সে এনরোল হয়েছেন। আপনার স্পেশালিস্ট ${course.specialistName}-এর কাছে নোটিফিকেশন সিঙ্ক হয়েছে।'
                    : 'You have successfully enrolled in "${course.titleEn}". Notification synced to specialist ${course.specialistName} & Admin Portal.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  'bKash TrxID: $trxId',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close Dialog
                  },
                  child: Text(isBn ? 'কোর্স শুরু করুন' : 'Start Learning Now', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final allCourses = mock_api.ApiService().getMockCourses();

    final bool isEnrolledInApp = dashboardProvider.isCourseEnrolled(course.id, course.titleEn);

    // Automatically filter related courses
    final relatedCourses = allCourses.where((c) => c.id != course.id).take(3).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Video / Banner SliverAppBar
          SliverAppBar(
            expandedHeight: 240.0,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    course.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(color: AppColors.primary),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: IconButton(
                      iconSize: 72,
                      icon: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
                      ),
                      onPressed: () => _launchVideoUrl(course.introVideo),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            course.categorySlug.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isBn ? course.titleBn : course.titleEn,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Course Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildChip(Icons.timer_outlined, course.duration),
                      _buildChip(Icons.people_outline_rounded, '${course.studentsCount} Enrolled'),
                      _buildChip(Icons.star_rounded, '${course.rating} ⭐', color: Colors.amber.shade700),
                      _buildChip(Icons.speed_rounded, course.difficulty),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Progress Bar Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Overall Course Progress', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                            Text(
                              '${isEnrolledInApp ? _overallProgressPercentage.toStringAsFixed(0) : 0}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: isEnrolledInApp ? (_overallProgressPercentage / 100) : 0.0,
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          color: AppColors.primary,
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEnrolledInApp 
                            ? '${_completedLessonIds.length} of $_totalLessons Lessons Completed | ${_completedAssignmentIds.length}/${course.assignments.length} Assignments'
                            : '0 of $_totalLessons Lessons Completed | 0/${course.assignments.length} Assignments',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Instructor & Specialist Card
                  Text('Course Instructor & Specialist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course.instructorName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                                  Text(course.instructorDesignation, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                                  Text('${course.instructorExperience} • ${course.instructorRating.toStringAsFixed(1)} ★', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Clinical Specialist: ${course.specialistName}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Theme.of(context).colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(course.specialistDegree, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SpecialistListScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Book Session', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // About Course & Learning Objectives
                  Text(isBn ? 'এই কোর্স সম্পর্কে' : 'About This Course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text(
                    isBn ? course.descriptionBn : course.descriptionEn,
                    style: TextStyle(fontSize: 14, height: 1.5, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 16),

                  Text(isBn ? 'লার্নিং অবজেক্টিভস' : 'Learning Objectives', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  ...(isBn ? course.learningOutcomesBn : course.learningOutcomesEn).map((outcome) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(outcome, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9)))),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 28),

                  // Course Curriculum (Collapsible Modules)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isBn ? 'কোর্স মডিউলসমূহ' : 'Course Curriculum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      Text('${course.modules.length} Modules', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...course.modules.map((module) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ExpansionTile(
                        title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text('${module.lessons.length} Lessons', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        children: module.lessons.map((lesson) {
                          final isCompleted = _completedLessonIds.contains(lesson.id);
                          return ListTile(
                            leading: Icon(
                              lesson.type == 'video'
                                  ? Icons.play_circle_outline_rounded
                                  : lesson.type == 'audio'
                                      ? Icons.headset_rounded
                                      : lesson.type == 'pdf'
                                          ? Icons.picture_as_pdf_rounded
                                          : Icons.article_rounded,
                              color: AppColors.primary,
                            ),
                            title: Text(lesson.title, style: TextStyle(fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                            subtitle: Text('${lesson.duration} • ${lesson.type.toUpperCase()}'),
                            trailing: Icon(
                              isCompleted ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                              color: isCompleted ? Colors.green : Colors.grey,
                              size: isCompleted ? 22 : 16,
                            ),
                            onTap: () {
                              if (!isEnrolledInApp) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isBn ? 'এই কোর্সটির লেসন দেখতে আগে কোর্সে এনরোল করুন।' : 'Please enroll in the course to view lessons.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              showDialog(
                                context: context,
                                builder: (_) => LessonPlayerDialog(
                                  lesson: lesson,
                                  onCompleted: () {
                                    setState(() {
                                      _completedLessonIds.add(lesson.id);
                                    });
                                    _saveProgressToLocal();
                                    _checkAndSyncCertificate();
                                    _checkAndShowCompletionModal();
                                  },
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),

                  // Assignments Section
                  if (course.assignments.isNotEmpty) ...[
                    const Text('Course Assignments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...course.assignments.map((assignment) {
                      final isDone = _completedAssignmentIds.contains(assignment.id);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: Icon(
                            isDone ? Icons.task_alt_rounded : Icons.assignment_outlined,
                            color: isDone ? Colors.green : AppColors.primary,
                            size: 28,
                          ),
                          title: Text(assignment.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(assignment.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: ElevatedButton(
                            onPressed: () {
                              if (!isEnrolledInApp) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isBn ? 'টাস্ক সাবমিট করতে আগে কোর্সে এনরোল করুন।' : 'Please enroll in the course before submitting assignments.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              showDialog(
                                context: context,
                                builder: (_) => AssignmentModalDialog(
                                  assignment: assignment,
                                  onSubmitted: () {
                                    setState(() {
                                      _completedAssignmentIds.add(assignment.id);
                                    });
                                    _saveProgressToLocal();
                                    _checkAndSyncCertificate();
                                    _checkAndShowCompletionModal();
                                  },
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDone ? Colors.green : AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(isDone ? 'Completed ✓' : 'Start Task', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                  ],

                  // Quiz Section
                  if (course.quizQuestions.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.quiz_rounded, size: 44, color: AppColors.primary),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Final Course Quiz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('${course.quizQuestions.length} Questions • Passing Score 70%', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                if (_quizPassed)
                                  const Text('Passed with 70%+ score! 🎉', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (!isEnrolledInApp) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isBn ? 'কুইজ দিতে আগে কোর্সে এনরোল করুন।' : 'Please enroll in the course before taking the quiz.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              showDialog(
                                context: context,
                                builder: (_) => QuizDialog(
                                  quizQuestions: course.quizQuestions,
                                  onQuizCompleted: (score, passed) {
                                    setState(() {
                                      _quizScore = score;
                                      _quizPassed = passed;
                                    });
                                    _saveProgressToLocal();
                                    _checkAndSyncCertificate();
                                    _checkAndShowCompletionModal();
                                  },
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: Text(_quizPassed ? 'Retake' : 'Attempt Quiz', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Certificate Banner Section
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _isCertificateUnlocked 
                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.amber.shade900.withOpacity(0.3) : Colors.amber.shade50) 
                        : (_overallProgressPercentage >= 99.0 || (_issuedCertData != null && _issuedCertData!['recommendation_status'] == 'pending'))
                            ? Colors.purple.withOpacity(0.08)
                            : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _isCertificateUnlocked 
                          ? Colors.amber 
                          : (_overallProgressPercentage >= 99.0 || (_issuedCertData != null && _issuedCertData!['recommendation_status'] == 'pending'))
                              ? Colors.purple.shade300
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCertificateUnlocked 
                            ? Icons.workspace_premium_rounded 
                            : (_overallProgressPercentage >= 99.0 || (_issuedCertData != null && _issuedCertData!['recommendation_status'] == 'pending'))
                                ? Icons.pending_actions_rounded
                                : Icons.lock_clock_rounded,
                          size: 44,
                          color: _isCertificateUnlocked 
                            ? Colors.amber.shade600 
                            : (_overallProgressPercentage >= 99.0 || (_issuedCertData != null && _issuedCertData!['recommendation_status'] == 'pending'))
                                ? Colors.purple
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isCertificateUnlocked 
                                  ? 'Certificate Issued! 🎉' 
                                  : (_overallProgressPercentage >= 99.0 || (_issuedCertData != null && _issuedCertData!['recommendation_status'] == 'pending'))
                                      ? 'Course Completed (Pending Review) ⏳'
                                      : 'Course Certificate (Locked)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
                              ),
                              Text(
                                _isCertificateUnlocked
                                    ? 'Your official certificate has been issued by your specialist. Click below to view & download.'
                                    : (_overallProgressPercentage >= 99.0 || (_issuedCertData != null && _issuedCertData!['recommendation_status'] == 'pending'))
                                        ? 'You completed 100%! Certificate request is pending specialist review.'
                                        : 'Complete 100% lessons, assignments & quiz to unlock certificate.',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isCertificateUnlocked ? _showCertificateDialog : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCertificateUnlocked ? Colors.amber.shade700 : Colors.grey,
                          ),
                          child: const Text('View Certificate', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Rate & Review Section
                  if (_overallProgressPercentage == 100.0 && isEnrolledInApp) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star_rate_rounded, size: 44, color: Colors.blue.shade600),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rate & Review Course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                                Text('Share your experience with others', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                builder: (_) => RateReviewBottomSheet(course: course),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
                            child: const Text('Rate Now', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Related Courses Section
                  Text('Related Courses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: relatedCourses.length,
                      itemBuilder: (ctx, idx) {
                        final rel = relatedCourses[idx];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => CourseDetailScreen(course: rel)),
                            );
                          },
                          child: Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.asset(rel.thumbnail, height: 100, width: double.infinity, fit: BoxFit.cover),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(isBn ? rel.titleBn : rel.titleEn, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text('${rel.duration} • ${rel.rating} ⭐', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Sticky Bar (Dynamic Enroll vs Continue Learning Button)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isBn ? 'কোর্স ফি' : 'Course Price', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Text(
                  course.isFree ? (isBn ? 'বিনামূল্যে' : 'FREE') : '৳${course.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (isEnrolledInApp) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isBn ? 'আপনার কোর্স পাঠ্যসূচি প্লে করা হচ্ছে...' : 'Resuming your course lessons...'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  } else if (course.isFree) {
                    // Free course explicit enrollment
                    final dashProvider = Provider.of<DashboardProvider>(context, listen: false);
                    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
                    await dashProvider.enrollCourse({
                      'id': course.id,
                      'title': course.titleEn,
                      'description': course.descriptionEn,
                      'completed_lessons': 0,
                      'total_lessons': _totalLessons,
                      'progress_percentage': 0,
                      'format': 'Both',
                      'instructor': course.instructorName,
                      'specialist': course.specialistName,
                      'price': 0.0,
                    });

                    notifProvider.addNotification(
                      title: isBn ? 'নতুন কোর্স এনরোলমেন্ট!' : 'New Course Enrollment!',
                      message: isBn
                          ? '${course.specialistName}-এর "${course.titleBn}" কোর্সে সফলতা সহ এনরোলমেন্ট সম্পন্ন হয়েছে।'
                          : 'Enrolled in "${course.titleEn}" with ${course.specialistName}.',
                    );

                    if (mounted) {
                      _showEnrollmentSuccessDialog(context, isBn, 'FREE-ENROLL', course);
                    }
                  } else {
                    _showCoursePaymentModal(context, isBn, course);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isEnrolledInApp
                      ? (isBn ? 'শেখা চালিয়ে যান ➔' : 'Continue Learning ➔')
                      : (course.isFree
                          ? (isBn ? 'ফ্রি এনরোল করুন ➔' : 'Enroll Free Course ➔')
                          : (isBn ? 'কোর্সে এনরোল করুন ➔' : 'Enroll Course ➔')),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}

class RateReviewBottomSheet extends StatefulWidget {
  final CourseModel course;
  const RateReviewBottomSheet({Key? key, required this.course}) : super(key: key);

  @override
  State<RateReviewBottomSheet> createState() => _RateReviewBottomSheetState();
}

class _RateReviewBottomSheetState extends State<RateReviewBottomSheet> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiService.tokenKey) ?? '';
      
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/courses/api/courses/${widget.course.id}/rate/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rating': _rating,
          'review_text': _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you! Your review has been submitted successfully.'), backgroundColor: Colors.green),
          );
        }
      } else {
        final err = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err['detail'] ?? 'Failed to submit review. You may have already reviewed this course.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again later.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Rate Course: ${widget.course.titleEn}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text('How was your experience?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                iconSize: 44,
                icon: Icon(
                  index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber.shade600,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your thoughts about this course (optional)...',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSubmitting 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Submit Review', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
