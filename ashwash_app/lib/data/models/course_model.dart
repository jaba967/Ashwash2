class CourseLesson {
  final String id;
  final String title;
  final String duration;
  final String type; // 'video', 'audio', 'pdf', 'article', 'exercise'
  final String contentUrl;
  final String description;
  final List<dynamic> homeworkQuestions;
  bool isCompleted;

  CourseLesson({
    required this.id,
    required this.title,
    required this.duration,
    required this.type,
    required this.contentUrl,
    this.description = '',
    this.homeworkQuestions = const [],
    this.isCompleted = false,
  });
}

class CourseModule {
  final String id;
  final String title;
  final String description;
  final List<CourseLesson> lessons;

  CourseModule({
    required this.id,
    required this.title,
    this.description = '',
    required this.lessons,
  });
}

class CourseAssignment {
  final String id;
  final String title;
  final String description;
  final String type; // 'mood_journal', 'sleep_tracker', 'gratitude_journal', 'self_care_checklist', 'bonding_activity', 'final_reflection'
  bool isCompleted;

  CourseAssignment({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.isCompleted = false,
  });
}

class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class CourseModel {
  final int id;
  final String titleEn;
  final String titleBn;
  final String subtitleEn;
  final String subtitleBn;
  final String categorySlug;
  final String thumbnail;
  final String introVideo;
  final String instructorName;
  final String instructorDesignation;
  final String instructorPhoto;
  final String instructorExperience;
  final double instructorRating;
  final String specialistName;
  final String specialistDegree;
  final String specialistPhoto;
  final String duration;
  final String studentsCount;
  final double rating;
  final String difficulty;
  final double price;
  final bool isFree;
  final String descriptionEn;
  final String descriptionBn;
  final List<String> learningOutcomesEn;
  final List<String> learningOutcomesBn;
  final List<CourseModule> modules;
  final List<CourseAssignment> assignments;
  final List<QuizQuestion> quizQuestions;
  final bool certificateAvailable;
  final List<int> relatedCourseIds;

  CourseModel({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    this.subtitleEn = '',
    this.subtitleBn = '',
    this.categorySlug = 'postpartum-depression',
    this.thumbnail = 'assets/images/courses_browse_icon.jpg',
    this.introVideo = 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785525213/Postpartum_Depression_mood_disorder_after_child_birth_in_Bangla_Dr_Mekhala_Sarkar_-_Dr._Mekhala_Sarkar_720p_h264_twt9ei.mp4',
    this.instructorName = 'Dr. Fatima Rahman',
    this.instructorDesignation = 'Senior Maternal Mental Health Specialist',
    this.instructorPhoto = 'https://corecdn.doctime.com.bd/persons/11799872/profile_photos/dbdgNP0694EIZiZn6oXONLB59vDvgsXFNyVYikD7.png',
    this.instructorExperience = '8+ Years',
    this.instructorRating = 4.9,
    this.specialistName = 'Dr. Ayesha Sultana',
    this.specialistDegree = 'FCPS (Psychiatry)',
    this.specialistPhoto = 'https://corecdn.doctime.com.bd/persons/578875/profile_photos/Fe6ibomQLhBJuUQFq4cjQGkAnPeWDtUsO8AOMqIn.png',
    this.duration = '6 Weeks',
    this.studentsCount = '2480+',
    this.rating = 4.9,
    this.difficulty = 'Beginner',
    this.price = 0.0,
    this.isFree = true,
    required this.descriptionEn,
    required this.descriptionBn,
    this.learningOutcomesEn = const [],
    this.learningOutcomesBn = const [],
    this.modules = const [],
    this.assignments = const [],
    this.quizQuestions = const [],
    this.certificateAvailable = true,
    this.relatedCourseIds = const [],
  });

  int get durationWeeks {
    final parts = duration.split(' ');
    if (parts.isNotEmpty) {
      return int.tryParse(parts.first) ?? 6;
    }
    return 6;
  }
}
