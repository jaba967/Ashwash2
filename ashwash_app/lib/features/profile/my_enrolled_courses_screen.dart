import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../data/models/course_model.dart';
import '../courses/presentation/screens/course_detail_screen.dart';
import '../courses/presentation/screens/course_certificate_screen.dart';

class MyEnrolledCoursesScreen extends StatefulWidget {
  const MyEnrolledCoursesScreen({Key? key}) : super(key: key);

  @override
  State<MyEnrolledCoursesScreen> createState() => _MyEnrolledCoursesScreenState();
}

class _MyEnrolledCoursesScreenState extends State<MyEnrolledCoursesScreen> {
  List<Map<String, dynamic>> _rawCourses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEnrolledCourses();
  }

  Future<void> _fetchEnrolledCourses() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // Fetch enrolled courses from backend
      final data = await ApiService.get(ApiEndpoints.enrolledCourses, requireAuth: true);
      List<Map<String, dynamic>> courses = [];

      if (data is List) {
        courses = data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      } else if (data is Map && data['results'] is List) {
        courses = (data['results'] as List).map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      } else if (data is Map && data['enrolled_courses'] is List) {
        courses = (data['enrolled_courses'] as List).map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      }

      if (courses.isEmpty && mounted) {
        final dashCourses = Provider.of<DashboardProvider>(context, listen: false).enrolledCourses;
        if (dashCourses.isNotEmpty) {
          courses = dashCourses;
        }
      }

      setState(() { _rawCourses = courses; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        final dashCourses = Provider.of<DashboardProvider>(context, listen: false).enrolledCourses;
        if (dashCourses.isNotEmpty) {
          setState(() { _rawCourses = dashCourses; _isLoading = false; });
          return;
        }
      }
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  /// Build a real CourseModel from the API course map (same logic as course_catalog_screen)
  CourseModel _buildCourseModel(Map<String, dynamic> course) {
    double parseDbl(dynamic val, [double defaultVal = 0.0]) {
      if (val == null) return defaultVal;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? defaultVal;
      return defaultVal;
    }

    int parseI(dynamic val, [int defaultVal = 0]) {
      if (val == null) return defaultVal;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? defaultVal;
      return defaultVal;
    }

    // Support both enrolled course wrapper and direct course object
    final Map<String, dynamic> courseData = (course['course'] is Map)
        ? Map<String, dynamic>.from(course['course'])
        : course;

    final int courseId = parseI(courseData['id'], DateTime.now().millisecondsSinceEpoch % 100000);
    final String courseTitle = courseData['title_en']?.toString() ?? courseData['title_bn']?.toString() ?? courseData['title']?.toString() ?? 'Mental Health Course';
    final String courseDesc = courseData['description_en']?.toString() ?? courseData['description_bn']?.toString() ?? courseData['description']?.toString() ?? '';
    final double coursePrice = parseDbl(courseData['price']);
    final double courseRating = parseDbl(courseData['average_rating'], 4.9);
    final int durationWeeks = parseI(courseData['duration_weeks'], 4);
    final String enrolledCountStr = courseData['enrolled_count']?.toString() ?? '0';
    final bool isFree = courseData['is_free'] == true || coursePrice == 0.0;

    final Map<String, dynamic> instDetails = (courseData['instructor_details'] is Map)
        ? Map<String, dynamic>.from(courseData['instructor_details'])
        : {};
    final String instructorName = instDetails['name']?.toString()
        ?? courseData['instructor']?.toString()
        ?? courseData['specialist']?.toString()
        ?? 'Mental Health Specialist';
    final String specDegree = instDetails['qualification']?.toString()
        ?? courseData['specialist_degree']?.toString()
        ?? 'Psychiatry & Behavioral Specialist';
    final String specPhoto = (instDetails['avatar_url']?.toString().isNotEmpty == true)
        ? instDetails['avatar_url'].toString()
        : (courseData['specialist_photo']?.toString() ?? 'https://corecdn.doctime.com.bd/persons/578875/profile_photos/Fe6ibomQLhBJuUQFq4cjQGkAnPeWDtUsO8AOMqIn.png');

    // Build real modules/lessons
    List<CourseModule> parsedModules = [];

    if (courseData['modules'] is List && (courseData['modules'] as List).isNotEmpty) {
      for (var m in (courseData['modules'] as List)) {
        if (m is Map) {
          final mTitle = m['title_en']?.toString() ?? m['title']?.toString() ?? 'Module';
          final mLessons = (m['lessons'] is List) ? (m['lessons'] as List) : [];
          parsedModules.add(
            CourseModule(
              id: 'm_${m['id'] ?? DateTime.now().millisecondsSinceEpoch}',
              title: mTitle,
              lessons: mLessons.map<CourseLesson>((l) {
                final lessonMap = l is Map ? l : {};
                final lTitle = lessonMap['title_en']?.toString() ?? lessonMap['title']?.toString() ?? 'Lesson Content';
                final lType = (lessonMap['type']?.toString() ?? lessonMap['content_en']?.toString() ?? 'video').toLowerCase();
                final String lFile = (lessonMap['video_url']?.toString().isNotEmpty == true)
                    ? lessonMap['video_url'].toString()
                    : ((lessonMap['file']?.toString().isNotEmpty == true)
                        ? lessonMap['file'].toString()
                        : ((lessonMap['url']?.toString().isNotEmpty == true)
                            ? lessonMap['url'].toString()
                            : (lessonMap['content_url']?.toString() ?? '')));

                final bool hasHomework = lessonMap['homework_questions'] is List && (lessonMap['homework_questions'] as List).isNotEmpty;
                final bool hasLegacy = lessonMap['assignments'] is List && (lessonMap['assignments'] as List).isNotEmpty;
                List legacyQs = [];
                if (hasLegacy) {
                  final a = (lessonMap['assignments'] as List)[0];
                  legacyQs.add({
                    'id': a['id'] ?? 999,
                    'question_text': a['instruction_en'] ?? a['instruction_bn'] ?? 'Complete the assigned task',
                    'answer_type': 'long',
                    'is_required': true
                  });
                }

                return CourseLesson(
                  id: 'l_${lessonMap['id'] ?? DateTime.now().millisecondsSinceEpoch}',
                  title: lTitle,
                  duration: '${lessonMap['duration_minutes'] ?? 15} mins',
                  type: (hasHomework || hasLegacy || lType.contains('task')) ? 'task' : (lType.contains('audio') ? 'audio' : (lType.contains('pdf') ? 'pdf' : 'video')),
                  contentUrl: (lFile.isNotEmpty && lFile.startsWith('http'))
                      ? lFile
                      : 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785525213/Postpartum_Depression_mood_disorder_after_child_birth_in_Bangla_Dr_Mekhala_Sarkar_-_Dr._Mekhala_Sarkar_720p_h264_twt9ei.mp4',
                  description: lessonMap['instruction_en']?.toString() ?? lessonMap['content_en']?.toString() ?? 'Lesson: $lTitle',
                  homeworkQuestions: hasHomework ? (lessonMap['homework_questions'] as List) : legacyQs,
                );
              }).toList(),
            ),
          );
        }
      }
    }

    // Fallback: top-level lessons list
    if (parsedModules.isEmpty && courseData['lessons'] is List && (courseData['lessons'] as List).isNotEmpty) {
      parsedModules.add(
        CourseModule(
          id: 'spec_m1_$courseId',
          title: 'Module 1 – $courseTitle',
          lessons: (courseData['lessons'] as List).map<CourseLesson>((l) {
            final lessonMap = l is Map ? l : {};
            final lTitle = lessonMap['title']?.toString() ?? lessonMap['title_en']?.toString() ?? 'Lesson Content';
            final lType = (lessonMap['type']?.toString() ?? 'video').toLowerCase();
            final String lFile = (lessonMap['video_url']?.toString().isNotEmpty == true)
                ? lessonMap['video_url'].toString()
                : ((lessonMap['file']?.toString().isNotEmpty == true)
                    ? lessonMap['file'].toString()
                    : ((lessonMap['url']?.toString().isNotEmpty == true)
                        ? lessonMap['url'].toString()
                        : (lessonMap['content_url']?.toString() ?? '')));

            final bool hasHomework = lessonMap['homework_questions'] is List && (lessonMap['homework_questions'] as List).isNotEmpty;
            final bool hasLegacy = lessonMap['assignments'] is List && (lessonMap['assignments'] as List).isNotEmpty;
            List legacyQs = [];
            if (hasLegacy) {
              final a = (lessonMap['assignments'] as List)[0];
              legacyQs.add({
                'id': a['id'] ?? 999,
                'question_text': a['instruction_en'] ?? a['instruction_bn'] ?? 'Complete the assigned task',
                'answer_type': 'long',
                'is_required': true
              });
            }

            return CourseLesson(
              id: 'l_${lessonMap['id'] ?? DateTime.now().millisecondsSinceEpoch}',
              title: lTitle,
              duration: '15 mins',
              type: (hasHomework || hasLegacy || lType.contains('task')) ? 'task' : (lType.contains('audio') ? 'audio' : (lType.contains('pdf') ? 'pdf' : 'video')),
              contentUrl: (lFile.isNotEmpty && lFile.startsWith('http'))
                  ? lFile
                  : 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785525213/Postpartum_Depression_mood_disorder_after_child_birth_in_Bangla_Dr_Mekhala_Sarkar_-_Dr._Mekhala_Sarkar_720p_h264_twt9ei.mp4',
              description: lessonMap['instruction_en']?.toString() ?? lessonMap['content_en']?.toString() ?? 'Lesson: $lTitle',
              homeworkQuestions: hasHomework ? (lessonMap['homework_questions'] as List) : legacyQs,
            );
          }).toList(),
        ),
      );
    }

    // Fallback module if none found
    if (parsedModules.isEmpty) {
      parsedModules.add(
        CourseModule(
          id: 'm1_$courseId',
          title: 'Module 1 – $courseTitle Overview',
          lessons: [
            CourseLesson(
              id: 'l1_$courseId',
              title: 'Lesson 1: Introduction to $courseTitle',
              duration: '15 mins',
              type: 'video',
              contentUrl: 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785525213/Postpartum_Depression_mood_disorder_after_child_birth_in_Bangla_Dr_Mekhala_Sarkar_-_Dr._Mekhala_Sarkar_720p_h264_twt9ei.mp4',
              description: 'Introduction to $courseTitle.',
            ),
          ],
        ),
      );
    }

    // Build real assignments list
    List<CourseAssignment> assignments = [];
    if (courseData['assignments'] is List) {
      for (var a in (courseData['assignments'] as List)) {
        if (a is Map) {
          assignments.add(CourseAssignment(
            id: 'a_${a['id'] ?? DateTime.now().millisecondsSinceEpoch}',
            title: a['title_en']?.toString() ?? a['title']?.toString() ?? 'Assignment',
            description: a['description_en']?.toString() ?? a['instruction_en']?.toString() ?? a['description']?.toString() ?? '',
            type: a['type']?.toString() ?? 'mood_journal',
          ));
        }
      }
    }

    // Build quiz questions list
    List<QuizQuestion> quizQuestions = [];
    if (courseData['quiz_questions'] is List) {
      int qIdx = 0;
      for (var q in (courseData['quiz_questions'] as List)) {
        if (q is Map) {
          final opts = (q['options'] is List)
              ? (q['options'] as List).map((o) => o.toString()).toList()
              : <String>[];
          quizQuestions.add(QuizQuestion(
            id: parseI(q['id'], qIdx),
            question: q['question_text']?.toString() ?? q['question']?.toString() ?? 'Question',
            options: opts,
            correctAnswerIndex: parseI(q['correct_answer_index'] ?? q['correct_option'], 0),
          ));
          qIdx++;
        }
      }
    }

    return CourseModel(
      id: courseId,
      titleEn: courseTitle,
      titleBn: courseData['title_bn']?.toString() ?? courseTitle,
      descriptionEn: courseDesc,
      descriptionBn: courseData['description_bn']?.toString() ?? courseDesc,
      categorySlug: courseData['category']?.toString() ?? 'GENERAL',
      thumbnail: courseData['thumbnail_url']?.toString().isNotEmpty == true
          ? courseData['thumbnail_url'].toString()
          : 'assets/images/courses_browse_icon.jpg',
      introVideo: 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785525213/Postpartum_Depression_mood_disorder_after_child_birth_in_Bangla_Dr_Mekhala_Sarkar_-_Dr._Mekhala_Sarkar_720p_h264_twt9ei.mp4',
      instructorName: instructorName,
      instructorDesignation: specDegree,
      instructorPhoto: specPhoto,
      specialistName: instructorName,
      specialistDegree: specDegree,
      specialistPhoto: specPhoto,
      duration: '$durationWeeks Weeks',
      studentsCount: enrolledCountStr,
      rating: courseRating,
      difficulty: 'Beginner',
      price: coursePrice,
      isFree: isFree,
      learningOutcomesEn: [
        'Master core strategies for $courseTitle',
        'Practice daily emotional resilience exercises',
      ],
      learningOutcomesBn: [
        'কোর্সের মূল বিষয়বস্তু ও মানসিক প্রশান্তিচর্চা',
      ],
      modules: parsedModules,
      assignments: assignments,
      quizQuestions: quizQuestions,
      certificateAvailable: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkForestBg : AppColors.lightGrayishGreen, // #1A2B2C in Dark, #F0F8F0 in Light
      appBar: AppBar(
        backgroundColor: AppColors.deepForestGreen, // #2E8B57 Deep Forest Green Header
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'My Enrolled Courses',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchEnrolledCourses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildErrorState(false)
              : _rawCourses.isEmpty
                  ? _buildEmptyState(isDark)
                  : RefreshIndicator(
                      onRefresh: _fetchEnrolledCourses,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _rawCourses.length,
                        itemBuilder: (context, index) {
                          final raw = _rawCourses[index];
                          return _buildCourseCard(context, raw, isDark);
                        },
                      ),
                    ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Map<String, dynamic> raw, bool isDark) {
    // Support nested "course" object from enrolled endpoint
    final Map<String, dynamic> courseData = (raw['course'] is Map)
        ? Map<String, dynamic>.from(raw['course'])
        : raw;

    final String title = courseData['title_en']?.toString() ?? courseData['title_bn']?.toString() ?? courseData['title']?.toString() ?? 'Mental Health Course';
    final String description = courseData['description_en']?.toString() ?? courseData['description_bn']?.toString() ?? courseData['description']?.toString() ?? '';

    // Real progress: compute from completed_lessons_count / total_lessons_count
    // Never show 100% if no lessons have been actually completed
    final int completedLessons = (raw['completed_lessons_count'] is num)
        ? (raw['completed_lessons_count'] as num).toInt()
        : 0;
    final int totalLessonsFromProgress = (raw['total_lessons_count'] is num)
        ? (raw['total_lessons_count'] as num).toInt()
        : 0;
    final int totalLessonsFromCourse = (courseData['total_lessons'] is num)
        ? (courseData['total_lessons'] as num).toInt()
        : 0;

    // Count lessons from modules as ground truth
    int totalLessonsFromModules = 0;
    if (courseData['modules'] is List) {
      for (var m in (courseData['modules'] as List)) {
        if (m is Map && m['lessons'] is List) {
          totalLessonsFromModules += (m['lessons'] as List).length;
        }
      }
    }

    final int totalLessons = totalLessonsFromModules > 0
        ? totalLessonsFromModules
        : (totalLessonsFromCourse > 0 ? totalLessonsFromCourse : totalLessonsFromProgress);

    // Only show real progress — if no lessons completed or total=0, show 0%
    int progressPercent;
    if (totalLessons > 0 && completedLessons > 0) {
      progressPercent = ((completedLessons / totalLessons) * 100).round().clamp(0, 100);
    } else if (totalLessons == 0 && completedLessons == 0) {
      // fallback to backend value but cap at 99 unless actually done
      final backendPct = (raw['progress_percentage'] is num)
          ? (raw['progress_percentage'] as num).toInt()
          : 0;
      progressPercent = (raw['is_completed'] == true) ? backendPct : backendPct.clamp(0, 99);
    } else {
      progressPercent = 0;
    }
    final bool isTrulyCompleted = (raw['is_completed'] == true) && progressPercent >= 100;

    final Map<String, dynamic> instDetails = (courseData['instructor_details'] is Map)
        ? Map<String, dynamic>.from(courseData['instructor_details'])
        : {};
    final String instructorName = instDetails['name']?.toString()
        ?? courseData['instructor']?.toString()
        ?? courseData['specialist']?.toString()
        ?? 'Mental Health Specialist';

    // Real distinct instructor photo from backend or distinct gender-matched specialist photo
    final String rawPhoto = (instDetails['avatar_url']?.toString().isNotEmpty == true)
        ? instDetails['avatar_url'].toString()
        : (courseData['specialist_photo']?.toString() ?? '');

    String instructorPhoto = rawPhoto;
    if (instructorPhoto.isEmpty || !instructorPhoto.startsWith('http') || instructorPhoto.contains('doctime.com')) {
      final nameLower = instructorName.toLowerCase();
      if (nameLower.contains('nihal') || nameLower.contains('sarkar') || nameLower.contains('tanvir')) {
        instructorPhoto = 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=200&auto=format&fit=crop&q=80';
      } else {
        instructorPhoto = 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=200&auto=format&fit=crop&q=80';
      }
    }

    // Real thumbnail from backend
    final String thumbnailUrl = courseData['thumbnail_url']?.toString().isNotEmpty == true
        ? courseData['thumbnail_url'].toString()
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          final realCourse = _buildCourseModel(raw);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CourseDetailScreen(course: realCourse)),
          ).then((_) => _fetchEnrolledCourses());
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with real image if available
            Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                image: thumbnailUrl.startsWith('http')
                    ? DecorationImage(image: NetworkImage(thumbnailUrl), fit: BoxFit.cover)
                    : null,
                gradient: thumbnailUrl.startsWith('http') ? null : const LinearGradient(
                  colors: [Color(0xFFC084FC), Color(0xFFA855F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!thumbnailUrl.startsWith('http'))
                    const Icon(Icons.school_rounded, size: 54, color: Colors.white),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isTrulyCompleted ? Colors.green.shade700 : Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isTrulyCompleted ? '🎓 Completed' : '📚 Enrolled',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Instructor with icon badge (no photo)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          instructorName,
                          style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final realCourse = _buildCourseModel(raw);
                        if (isTrulyCompleted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CourseCertificateScreen(course: realCourse)),
                          ).then((_) => _fetchEnrolledCourses());
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CourseDetailScreen(course: realCourse)),
                          ).then((_) => _fetchEnrolledCourses());
                        }
                      },
                      icon: Icon(
                        isTrulyCompleted ? Icons.workspace_premium_rounded : Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        isTrulyCompleted ? 'View Certificate 🎓' : 'Continue Learning',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTrulyCompleted ? Colors.green.shade600 : AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 20),
            Text(
              'Could not load your courses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchEnrolledCourses,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFA855F7).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_rounded, size: 64, color: Color(0xFFA855F7)),
            ),
            const SizedBox(height: 20),
            Text(
              'No Enrolled Courses Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore our mental wellness programs and enroll in courses designed by expert psychologists.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Browse Courses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
