import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_endpoints.dart';
import '../network/api_service.dart';

class DashboardProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  String _userName = 'User';
  String _userCategory = 'First Time Mother';
  int _selectedMoodIndex = -1; // -1 means none selected today yet

  int _courseProgressPercent = 0;
  int _sessionsAttended = 0;
  int _tasksCompleted = 0;
  int _pointsEarned = 0;

  List<Map<String, dynamic>> _enrolledCourses = [];
  bool _hasUnreadNotifications = true;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get userName => _userName;
  String get userCategory => _userCategory;
  int get selectedMoodIndex => _selectedMoodIndex;

  int get courseProgressPercent => _courseProgressPercent;
  int get sessionsAttended => _sessionsAttended;
  int get tasksCompleted => _tasksCompleted;
  int get pointsEarned => _pointsEarned;

  List<Map<String, dynamic>> get enrolledCourses => _enrolledCourses;
  bool get hasUnreadNotifications => _hasUnreadNotifications;

  final List<Map<String, dynamic>> moodOptions = [
    {'emoji': '😡', 'label': 'Distressed', 'color': const Color(0xFFEF4444)},
    {'emoji': '🙁', 'label': 'Sad', 'color': const Color(0xFFF97316)},
    {'emoji': '😐', 'label': 'Neutral', 'color': const Color(0xFFF59E0B)},
    {'emoji': '🙂', 'label': 'Happy', 'color': const Color(0xFF10B981)},
    {'emoji': '😄', 'label': 'Super Happy', 'color': const Color(0xFF8B5CF6)},
  ];

  DashboardProvider() {
    _loadLocalEnrolledCourses();
    fetchDashboardData();
  }

  Future<void> _loadLocalEnrolledCourses([String? email]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = email ?? prefs.getString('saved_user_email') ?? '';
      if (userEmail.isNotEmpty) {
        final savedStr = prefs.getString('persisted_enrolled_courses_v3_${userEmail.toLowerCase()}');
        if (savedStr != null) {
          final List<dynamic> decoded = jsonDecode(savedStr);
          _enrolledCourses = List<Map<String, dynamic>>.from(decoded);
          notifyListeners();
          return;
        }
      }
      _enrolledCourses = [];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // ── 1. Fetch enrolled courses INDEPENDENTLY ──────────────────────────────
    // This must succeed even if the dashboard overview times out.
    try {
      final enrolledData = await ApiService.get(ApiEndpoints.enrolledCourses, requireAuth: true);
      if (enrolledData is List) {
        _enrolledCourses = List<Map<String, dynamic>>.from(enrolledData);
      } else if (enrolledData is Map && enrolledData['results'] is List) {
        _enrolledCourses = List<Map<String, dynamic>>.from(enrolledData['results'] as List);
      } else if (enrolledData is Map && enrolledData['enrolled_courses'] is List) {
        _enrolledCourses = List<Map<String, dynamic>>.from(enrolledData['enrolled_courses'] as List);
      }
      // Save to user-scoped local storage immediately
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_user_email') ?? '';
      if (savedEmail.isNotEmpty && _enrolledCourses.isNotEmpty) {
        await prefs.setString(
          'persisted_enrolled_courses_v3_${savedEmail.toLowerCase()}',
          jsonEncode(_enrolledCourses),
        );
      }
      notifyListeners(); // show courses immediately, don't wait for overview
    } catch (_) {
      // Courses fetch failed — keep whatever is already in _enrolledCourses
    }

    // ── 2. Fetch dashboard overview (metrics, username, etc.) ─────────────────
    try {
      final data = await ApiService.get(ApiEndpoints.dashboardOverview, requireAuth: true);
      _userName = data['user_name'] ?? _userName;
      _userCategory = data['category'] ?? _userCategory;
      _hasUnreadNotifications = data['has_unread_notifications'] ?? true;

      if (data['metrics'] != null) {
        _courseProgressPercent = data['metrics']['overall_course_progress'] ?? 0;
        _sessionsAttended = data['metrics']['sessions_attended'] ?? 0;
        _tasksCompleted = data['metrics']['tasks_completed'] ?? 0;
        _pointsEarned = data['metrics']['points_earned'] ?? 0;
      }

      // If overview also has enrolled_courses and our list is still empty, use it
      if (_enrolledCourses.isEmpty && data['enrolled_courses'] is List) {
        _enrolledCourses = List<Map<String, dynamic>>.from(data['enrolled_courses'] as List);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> clearUserData() async {
    _enrolledCourses = [];
    _userName = 'User';
    _courseProgressPercent = 0;
    _sessionsAttended = 0;
    _tasksCompleted = 0;
    _pointsEarned = 0;
    notifyListeners();
    // After clearing, immediately re-fetch from backend for the current user
    fetchDashboardData();
  }

  bool isCourseEnrolled(dynamic courseId, String courseTitle) {
    return _enrolledCourses.any((c) {
      final cId = (c['course'] is Map) ? c['course']['id'] : c['id'];
      final cTitle = (c['course'] is Map) ? (c['course']['title_en'] ?? c['course']['title']) : c['title'];
      return (cId != null && cId.toString() == courseId.toString()) ||
             (cTitle != null && cTitle.toString().trim().toLowerCase() == courseTitle.trim().toLowerCase());
    });
  }

  Future<void> enrollCourse(Map<String, dynamic> courseData) async {
    final courseId = courseData['id'];
    final courseIdStr = courseId.toString().replaceAll(RegExp(r'[^0-9]'), '');
    
    // Call backend enrollment API endpoint
    try {
      final endpoint = '${ApiEndpoints.courses}$courseIdStr/enroll/';
      await ApiService.post(endpoint, {
        'course_id': courseId,
        'course_title': courseData['title'],
      }, requireAuth: true);
    } catch (_) {}

    if (!isCourseEnrolled(courseId, courseData['title'] ?? '')) {
      _enrolledCourses.insert(0, courseData);
      notifyListeners();
    }
    // Refresh dashboard data to sync stats & enrollment list from backend
    await fetchDashboardData();
  }

  void selectMood(int index) {
    _selectedMoodIndex = index;
    notifyListeners();
  }
}
