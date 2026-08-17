import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_endpoints.dart';
import '../network/api_service.dart';

class CourseProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _allDatabaseCourses = [];
  Map<String, dynamic>? _selectedCourse;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get catalogCourses => List.unmodifiable(_allDatabaseCourses);
  Map<String, dynamic>? get selectedCourse => _selectedCourse;

  CourseProvider() {
    _loadLocalCache();
  }

  Future<void> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDbStr = prefs.getString('persisted_db_courses_real_v3');
      if (savedDbStr != null) {
        final List<dynamic> decoded = jsonDecode(savedDbStr);
        _allDatabaseCourses = List<Map<String, dynamic>>.from(decoded);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('persisted_db_courses_real_v3', jsonEncode(_allDatabaseCourses));
    } catch (_) {}
  }

  Future<void> addDynamicCourse(Map<String, dynamic> course) async {
    _allDatabaseCourses.insert(0, course);
    await _saveLocalCache();
    notifyListeners();
  }

  Future<void> fetchCoursesByCategory(String categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String url = categoryId.isEmpty || categoryId.toUpperCase() == 'ALL' || categoryId.toUpperCase() == 'BROWSE'
          ? ApiEndpoints.courses
          : '${ApiEndpoints.courses}?category=$categoryId';
      
      final data = await ApiService.get(url, requireAuth: true);
      final List<dynamic> rawList = (data is Map && data.containsKey('results')) ? data['results'] : (data is List ? data : []);
      final apiList = List<Map<String, dynamic>>.from(rawList);

      _allDatabaseCourses = List<Map<String, dynamic>>.from(apiList);
      await _saveLocalCache();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getFilteredCourses(String categoryId, String searchQuery) {
    final cat = categoryId.toUpperCase();
    final q = searchQuery.toLowerCase().trim();

    return _allDatabaseCourses.where((course) {
      // Category filter
      final cCat = (course['category_name'] ?? course['category'] ?? '').toString().toUpperCase();
      bool matchesCategory = true;
      if (cat != 'ALL' && cat != 'BROWSE' && cat.isNotEmpty) {
        if (cat.contains('POSTPARTUM') || cat.contains('MOTHER')) {
          matchesCategory = cCat.contains('POSTPARTUM') || cCat.contains('MOTHER');
        } else if (cat.contains('SINGLE')) {
          matchesCategory = cCat.contains('SINGLE');
        } else if (cat.contains('SPECIAL')) {
          matchesCategory = cCat.contains('SPECIAL');
        } else if (cat.contains('CORPORATE')) {
          matchesCategory = cCat.contains('CORPORATE');
        } else if (cat.contains('STUDENT')) {
          matchesCategory = cCat.contains('STUDENT');
        } else {
          matchesCategory = cCat == cat;
        }
      }

      if (!matchesCategory) return false;

      // Search query filter
      if (q.isEmpty) return true;
      final title = (course['title_en'] ?? course['title_bn'] ?? course['title'] ?? '').toString().toLowerCase();
      final desc = (course['description_en'] ?? course['description_bn'] ?? course['description'] ?? '').toString().toLowerCase();
      final category = cCat.toLowerCase();

      final instDetails = course['instructor_details'] is Map ? course['instructor_details'] as Map : {};
      final instructor = (instDetails['name'] ?? course['instructor'] ?? course['specialist'] ?? '').toString().toLowerCase();

      return title.contains(q) || desc.contains(q) || category.contains(q) || instructor.contains(q);
    }).toList();
  }

  Future<void> fetchCourseDetail(int courseId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.get('${ApiEndpoints.courses}$courseId/', requireAuth: true);
      _selectedCourse = data;
    } catch (e) {
      if (_allDatabaseCourses.isNotEmpty) {
        _selectedCourse = _allDatabaseCourses.firstWhere((c) => c['id'] == courseId, orElse: () => _allDatabaseCourses.first);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> enrollInCourse(int courseId) async {
    try {
      await ApiService.post('${ApiEndpoints.courses}$courseId/enroll/', {}, requireAuth: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return true;
    }
  }

  Future<bool> submitTask(int taskId, String text) async {
    try {
      await ApiService.post(
        '${ApiEndpoints.courses}tasks/$taskId/submit/',
        {'submission_text': text},
        requireAuth: true,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return true;
    }
  }
}
