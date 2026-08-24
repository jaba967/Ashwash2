import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/dashboard_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../courses/presentation/screens/course_detail_screen.dart';
import '../../../../data/models/course_model.dart';

class MyCoursesList extends StatelessWidget {
  final VoidCallback onViewAll;

  const MyCoursesList({super.key, required this.onViewAll});

  /// Extracts the course title from both flat and backend-enrolled-wrapper formats.
  String _getCourseTitle(Map<String, dynamic> course) {
    // Backend enrolled: { id, course: { id, title_en, ... }, enrolled_at, ... }
    final inner = course['course'];
    if (inner is Map) {
      return inner['title_en']?.toString() ??
          inner['title_bn']?.toString() ??
          inner['title']?.toString() ??
          'Course';
    }
    return course['title_en']?.toString() ??
        course['title_bn']?.toString() ??
        course['title']?.toString() ??
        'Course';
  }

  /// Extracts the course description from both flat and backend-enrolled-wrapper formats.
  String _getCourseDescription(Map<String, dynamic> course) {
    final inner = course['course'];
    if (inner is Map) {
      return inner['description_en']?.toString() ??
          inner['description_bn']?.toString() ??
          inner['description']?.toString() ??
          '';
    }
    return course['description_en']?.toString() ??
        course['description_bn']?.toString() ??
        course['description']?.toString() ??
        '';
  }

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
      relatedCourseIds: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBn = langProvider.isBangla;
    final courses = dashboardProvider.enrolledCourses;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isBn ? 'আমার কোর্সসমূহ' : 'My Courses',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent, // #45A9A9 Teal CTA
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (dashboardProvider.isLoading && courses.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (courses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.paleGreen, // #E0EEE0 Pale Green Surface
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.sageGreen.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.school_outlined, size: 48, color: AppColors.deepForestGreen),
                const SizedBox(height: 12),
                Text(
                  isBn ? 'আপনি এখনো কোনো কোর্সে এনরোল করেননি।' : 'You are not enrolled in any courses yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.charcoalGray, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];

              return GestureDetector(
                onTap: () {
                  final target = _buildCourseModel(course);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CourseDetailScreen(course: target)),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkForestSurface : AppColors.paleGreen, // #2C3E3F in Dark, #E0EEE0 in Light
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.sageGreen.withOpacity(0.4) : AppColors.deepForestGreen.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.2) : const Color(0x06000000),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCourseTitle(course),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.lightText : AppColors.charcoalGray,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getCourseDescription(course),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.sageGreen : AppColors.charcoalGray,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.goldenrod, // #DAA520 Distinct Goldenrod Badge
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isBn ? '📚 এনরোলড' : '📚 Enrolled',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Row(
                            children: const [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary, // #4E1F6E Deep Purple
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
