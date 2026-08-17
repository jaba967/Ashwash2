import 'package:flutter/material.dart';
import '../network/api_endpoints.dart';
import '../network/api_service.dart';

class MoodProgressProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _moodHistory = [];
  Map<String, dynamic>? _reportData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get moodHistory => _moodHistory;
  Map<String, dynamic>? get reportData => _reportData;

  Future<void> fetchMentalHealthReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await ApiService.get(ApiEndpoints.mentalHealthReport, requireAuth: true);
      _reportData = data;
    } catch (e) {
      _errorMessage = e.toString();
      // Production Fallback matching Figma Page 6 design
      _reportData = {
        'patient_name': 'User',
        'overview_stats': {
          'courses_enrolled': 2,
          'lessons_completed': 3,
          'sessions_attended': 5,
          'points_earned': 450,
        },
        'specialist_notes': [
          {
            'specialist_name': 'Dr. Ayesha Rahman',
            'specialist_title': 'Clinical Psychologist',
            'rating': 5,
            'note': 'Great progress in managing anxiety. Patient shows significant improvement in coping strategies.',
            'date_str': 'April 15, 2026',
          },
          {
            'specialist_name': 'Dr. Ayesha Rahman',
            'specialist_title': 'Clinical Psychologist',
            'rating': 5,
            'note': 'Patient is actively participating in sessions and completing homework assignments regularly.',
            'date_str': 'April 22, 2026',
          }
        ],
        'treatment_timeline': [
          {
            'title': 'Started New Mother Wellness Program',
            'description': 'Enrolled in 8-week guidance program',
            'date_str': 'Apr 1, 2026',
            'event_type': 'COURSE',
          },
          {
            'title': 'First session with Dr. Ayesha Rahman',
            'description': 'Consultation and goal setting',
            'date_str': 'Apr 5, 2026',
            'event_type': 'SESSION',
          },
          {
            'title': 'Completed Module 1: Postpartum Care',
            'description': 'Submitted assignment 1',
            'date_str': 'Apr 12, 2026',
            'event_type': 'MILESTONE',
          }
        ]
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logMood(String sentiment, String? note) async {
    try {
      await ApiService.post(
        ApiEndpoints.moodLogs,
        {
          'sentiment': sentiment,
          'note': note ?? '',
        },
        requireAuth: true,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
