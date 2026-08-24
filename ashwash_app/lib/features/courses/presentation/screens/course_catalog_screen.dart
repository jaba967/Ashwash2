import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/course_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../data/models/category_model.dart';
import 'course_detail_screen.dart';
import '../../../../core/services/api_service.dart';
import '../../../../data/models/course_model.dart';

class CourseCatalogScreen extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;

  const CourseCatalogScreen({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
  });

  @override
  State<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<CourseProvider>(context, listen: false).fetchCoursesByCategory(widget.categoryId);
    });
  }

  Color _getCategoryColor() {
    switch (widget.categoryId) {
      case 'POSTPARTUM_DEPRESSION':
      case 'FIRST_TIME_MOTHER':
        return AppColors.categoryMother;
      case 'SINGLE_PARENT':
        return AppColors.categorySingleParent;
      case 'PARENT_OF_SPECIAL_CHILD':
        return AppColors.categorySpecialChild;
      case 'CORPORATE_EMPLOYEE':
        return AppColors.categoryCorporate;
      case 'UNIVERSITY_STUDENT':
        return AppColors.categoryStudent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _getCategoryColor();

    final filteredCourses = courseProvider.getFilteredCourses(widget.categoryId, _searchQuery);

    return Scaffold(
      backgroundColor: AppColors.lightMint, // #98E8DE Soft Light Mint Page Background
      appBar: AppBar(
        backgroundColor: AppColors.primary, // #4E1F6E Deep Purple Header
        elevation: 0,
        title: Text(widget.categoryTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: courseProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar for Patient Course Search
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: isBn ? 'কোর্সের নাম বা শিক্ষক দিয়ে খুঁজুন...' : 'Search course by title or instructor...',
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.black),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Colors.white),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: isDark ? Colors.white : Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: isDark ? Colors.white : Colors.white),
                        ),
                      ),
                    ),
                  ),

                  // "Available Courses" Section Header
                  Text(
                    isBn ? 'উপলব্ধ কোর্সসমূহ' : 'Available Courses',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  if (filteredCourses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: Colors.white),
                            const SizedBox(height: 8),
                            Text(
                              isBn ? 'কোনো কোর্স পাওয়া যায়নি' : 'No courses found',
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Courses List Cards
                  ...filteredCourses.map((course) {
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

                    final double coursePrice = parseDbl(course['price']);
                    final double courseRating = parseDbl(course['average_rating'], 0.0);
                    final String enrolledCountStr = course['enrolled_count']?.toString() ?? '0';
                    final int courseId = parseI(course['id'], DateTime.now().millisecondsSinceEpoch % 100000);
                    final int durationWeeks = parseI(course['duration_weeks'], 4);
                    final int totalTasks = parseI(course['total_tasks'], 10);

                    final bool isFree = course['is_free'] == true || coursePrice == 0.0;
                    final String priceText = isFree ? 'Free' : '৳$coursePrice';

                    final titleText = course['title_en'] ?? course['title_bn'] ?? course['title'] ?? 'Mental Health Course';
                    final descText = course['description_en'] ?? course['description_bn'] ?? course['description'] ?? '';

                    final Map<String, dynamic> instDetails = (course['instructor_details'] is Map) 
                        ? Map<String, dynamic>.from(course['instructor_details']) 
                        : {};
                    final String instructorName = instDetails['name']?.toString() 
                        ?? course['instructor']?.toString() 
                        ?? course['specialist']?.toString() 
                        ?? 'Mental Health Specialist';

                    void openCourseDetail() {
                      String specDegree = instDetails['qualification']?.toString() 
                          ?? course['specialist_degree']?.toString() 
                          ?? 'Psychiatry & Behavioral Specialist';

                      String specPhoto = (instDetails['avatar_url']?.toString().isNotEmpty == true)
                          ? instDetails['avatar_url'].toString()
                          : (course['specialist_photo']?.toString() ?? 'https://corecdn.doctime.com.bd/persons/578875/profile_photos/Fe6ibomQLhBJuUQFq4cjQGkAnPeWDtUsO8AOMqIn.png');

                      String courseTitle = titleText.toString();
                      String courseDesc = descText.toString();

                      // Extract real modules / lessons from database
                      List<CourseModule> parsedModules = [];
                      if (course['modules'] is List && (course['modules'] as List).isNotEmpty) {
                        for (var m in (course['modules'] as List)) {
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
                                    description: lessonMap['instruction_en']?.toString() ?? lessonMap['content_en']?.toString() ?? 'Uploaded Specialist Lesson: $lTitle',
                                    homeworkQuestions: hasHomework ? (lessonMap['homework_questions'] as List) : legacyQs,
                                  );
                                }).toList(),
                              ),
                            );
                          }
                        }
                      }

                      if (parsedModules.isEmpty && course['lessons'] is List && (course['lessons'] as List).isNotEmpty) {
                        parsedModules.add(
                          CourseModule(
                            id: 'spec_m1_$courseId',
                            title: 'Module 1 – $courseTitle',
                            lessons: (course['lessons'] as List).map<CourseLesson>((l) {
                              final lessonMap = l is Map ? l : {};
                              final lTitle = lessonMap['title']?.toString() ?? 'Lesson Content';
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
                                description: lessonMap['instruction_en']?.toString() ?? lessonMap['content_en']?.toString() ?? 'Uploaded Specialist Lesson: $lTitle',
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
                                description: 'Introductory video for $courseTitle.',
                              ),
                            ],
                          ),
                        );
                      }

                      final dynamicCourse = CourseModel(
                        id: courseId,
                        titleEn: courseTitle,
                        titleBn: courseTitle,
                        descriptionEn: courseDesc,
                        descriptionBn: courseDesc,
                        categorySlug: course['category']?.toString() ?? 'GENERAL',
                        thumbnail: course['thumbnail_url']?.toString().isNotEmpty == true
                            ? course['thumbnail_url'].toString()
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
                          'কোর্সের মূল বিষয়বস্তু ও মানসিক প্রশান্তিচর্চা',
                        ],
                        modules: parsedModules,
                        assignments: [],
                        quizQuestions: [],
                        certificateAvailable: true,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CourseDetailScreen(course: dynamicCourse)),
                      );
                    }

                    return InkWell(
                      onTap: openCourseDetail,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail Placeholder Container (Matching Figma image box)
                            Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.15),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              child: Center(
                                child: Icon(Icons.school_rounded, size: 54, color: categoryColor),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titleText.toString(),
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_rounded, size: 14, color: Colors.black),
                                      const SizedBox(width: 4),
                                      Text(
                                        instructorName,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    descText.toString(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Metadata Row matching Figma: Duration, Tasks, Format
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildMetaItem(Icons.access_time_rounded, '$durationWeeks weeks'),
                                      _buildMetaItem(Icons.assignment_outlined, '$totalTasks tasks'),
                                      _buildMetaItem(Icons.devices_rounded, course['format'] ?? 'Both'),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Price & View Button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        priceText,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isFree ? AppColors.success : categoryColor,
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: openCourseDetail,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: categoryColor,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                        ),
                                        child: const Text('View Course', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // "Our Specialists" Preview Section (Matching Figma Page 3)
                  Text(
                    isBn ? 'আমাদের বিশেষজ্ঞরা' : 'Our Specialists',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: const Text('D', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Dr. Ayesha Rahman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('Clinical Psychologist', style: TextStyle(fontSize: 13, color: Colors.white)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  const Text('4.9', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(width: 10),
                                  Icon(Icons.history_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text('12 years', style: TextStyle(fontSize: 12, color: Colors.white)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Navigating to Specialist Booking...')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Book Session', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
