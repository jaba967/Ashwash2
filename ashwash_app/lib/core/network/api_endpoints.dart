import '../config/api_config.dart';

class ApiEndpoints {
  // Base API URL dynamically fetched from ApiConfig
  static String get baseUrl => ApiConfig.baseUrl;

  // Authentication Endpoints
  static String get register => '$baseUrl/auth/register/';
  static String get login => '$baseUrl/auth/login/';
  static String get googleAuth => '$baseUrl/auth/google/';
  static String get facebookAuth => '$baseUrl/auth/facebook/';
  static String get tokenRefresh => '$baseUrl/auth/token/refresh/';
  static String get profile => '$baseUrl/auth/profile/';
  static String get categoryPreference => '$baseUrl/auth/category-preference/';
  static String get categories => '$baseUrl/auth/categories/';
  static String get selectCategory => '$baseUrl/auth/select-category/';
  static String get changePassword => '$baseUrl/auth/change-password/';
  static String get privacySettings => '$baseUrl/auth/privacy-settings/';

  // Dashboard Endpoints
  static String get dashboardOverview => '$baseUrl/dashboard/overview/';
  static String get dashboardSummary => '$baseUrl/dashboard/summary/';
  static String get patientHealthReport => '$baseUrl/dashboard/patient-health-report/';

  // Mood & Progress Endpoints
  static String get moodLogs => '$baseUrl/mood/logs/';
  static String get mentalHealthReport => '$baseUrl/mood/report/';
  static String get moodAnalytics => '$baseUrl/mood/analytics/';

  // Knowledge Hub & Mind Games Endpoints
  static String get hubResources => '$baseUrl/knowledge/resources/';
  static String get resources => '$baseUrl/knowledge/resources/';
  static String get mindGames => '$baseUrl/hub/mind-games/';
  static String get gameScore => '$baseUrl/hub/mind-games/score/';

  // Courses & Assignments Endpoints
  static String get courses => '$baseUrl/courses/';
  static String get enrolledCourses => '$baseUrl/courses/enrolled/';

  // Assessment Endpoints
  static String get questionnaires => '$baseUrl/assessment/questionnaires/';
  static String get submitAssessment => '$baseUrl/assessment/submit/';

  // Appointments & Specialists
  static String get specialists => '$baseUrl/appointments/specialists/';
  static String get bookings => '$baseUrl/appointments/bookings/';

  // Community & Payments
  static String get posts => '$baseUrl/community/posts/';
  static String get payments => '$baseUrl/payments/initiate/';

  // Notifications Endpoints
  static String get notifications => '$baseUrl/notifications/';
  static String get notificationsCount => '$baseUrl/notifications/count/';
  static String get notificationsReadAll => '$baseUrl/notifications/read-all/';
  static String get notificationsDeleteAll => '$baseUrl/notifications/delete-all/';
}