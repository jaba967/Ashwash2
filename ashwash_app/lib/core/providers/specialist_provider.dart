import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_endpoints.dart';
import '../network/api_service.dart';

class CreatedCourseModel {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String duration;
  final int priceBdt;
  final String thumbnailUrl;
  final String instructorName;
  final List<Map<String, String>> lessons;
  bool isPublished;

  CreatedCourseModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.duration,
    required this.priceBdt,
    required this.thumbnailUrl,
    required this.instructorName,
    required this.lessons,
    this.isPublished = true,
  });
}

class SpecialistProfileModel {
  String fullName;
  String gender;
  String phoneNumber;
  String email;
  String specialization;
  String hospitalClinic;
  int experienceYears;
  String qualification;
  String medicalLicenseNumber;
  String? licenseDocumentPath;
  String languages;
  int consultationFee;
  List<String> availableDays;
  List<String> availableTimeSlots;
  String? avatarUrl;
  String? bannerUrl;
  bool isProfileComplete;
  double rating;
  int totalReviews;
  String bio;

  SpecialistProfileModel({
    required this.fullName,
    required this.gender,
    required this.phoneNumber,
    required this.email,
    required this.specialization,
    required this.hospitalClinic,
    required this.experienceYears,
    required this.qualification,
    required this.medicalLicenseNumber,
    this.licenseDocumentPath,
    required this.languages,
    required this.consultationFee,
    required this.availableDays,
    required this.availableTimeSlots,
    this.avatarUrl,
    this.bannerUrl,
    this.isProfileComplete = false,
    this.rating = 4.9,
    this.totalReviews = 48,
    required this.bio,
  });
}

class PatientRecordModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String category;
  final int age;
  final String moodState;
  final int assessmentScore;
  final int courseProgress;
  final int homeworkCompleted;
  final int quizScore;
  final bool certificateIssued;
  final int completedSessions;
  String doctorNotes;

  PatientRecordModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.category,
    required this.age,
    required this.moodState,
    required this.assessmentScore,
    required this.courseProgress,
    required this.homeworkCompleted,
    required this.quizScore,
    required this.certificateIssued,
    required this.completedSessions,
    required this.doctorNotes,
  });
}

class HomeworkSubmissionModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientAvatar;
  final String courseTitle;
  final String assignmentTitle;
  final String submittedAt;
  final String submissionText;
  final String? attachmentUrl;
  String status; // 'pending', 'approved', 'rejected', 'resubmit'
  int? grade;
  String? feedback;

  HomeworkSubmissionModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAvatar,
    required this.courseTitle,
    required this.assignmentTitle,
    required this.submittedAt,
    required this.submissionText,
    this.attachmentUrl,
    this.status = 'pending',
    this.grade,
    this.feedback,
  });
}

class SpecialistAppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientAvatar;
  final String specialistName;
  final String specialistAvatar;
  final String date;
  final String timeSlot;
  final String category;
  String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  String meetingLink;
  String notes;

  SpecialistAppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAvatar,
    this.specialistName = 'Dr. Mekhala Sarkar',
    this.specialistAvatar = '',
    required this.date,
    required this.timeSlot,
    required this.category,
    required this.status,
    required this.meetingLink,
    required this.notes,
  });
}

class SpecialistProvider with ChangeNotifier {
  SpecialistProfileModel _profile = SpecialistProfileModel(
    fullName: 'Dr. Mekhala Sarkar',
    gender: 'female',
    phoneNumber: '+880 1711-982341',
    email: 'dr.mekhala@ashwash.com',
    specialization: 'Clinical Psychologist & Consultant',
    hospitalClinic: 'Ashwash Mental Wellness Center, Dhaka',
    experienceYears: 12,
    qualification: 'FCPS (Psychiatry), M.Phil in Clinical Psychology (BSMMU)',
    medicalLicenseNumber: 'BMDC-REG-98234',
    languages: 'Bengali, English',
    consultationFee: 1500,
    availableDays: ['Sunday', 'Monday', 'Wednesday', 'Thursday'],
    availableTimeSlots: ['10:00 AM - 11:00 AM', '03:00 PM - 04:00 PM', '07:00 PM - 08:00 PM'],
    avatarUrl: 'https://corecdn.doctime.com.bd/persons/578875/profile_photos/Fe6ibomQLhBJuUQFq4cjQGkAnPeWDtUsO8AOMqIn.png',
    bannerUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800&auto=format&fit=crop&q=80',
    isProfileComplete: true,
    rating: 4.9,
    totalReviews: 48,
    bio: 'Dedicated senior consultant psychiatrist specializing in maternal mental health, postpartum depression, and emotional resilience.',
  );

  SpecialistProfileModel get profile => _profile;

  final List<CreatedCourseModel> _createdCourses = [
    CreatedCourseModel(
      id: 'c1',
      title: 'Postpartum Depression Recovery Program',
      subtitle: 'Complete guide for new mothers recovering from postpartum anxiety & depression',
      category: 'POSTPARTUM_DEPRESSION',
      duration: '4 Weeks',
      priceBdt: 0,
      thumbnailUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500',
      instructorName: 'Dr. Mekhala Sarkar',
      lessons: [
        {'title': 'Understanding Postpartum Mood Shifts', 'type': 'Video', 'file': 'module1_lesson1.mp4'},
        {'title': 'Guided Breathing for Anxiety Relief', 'type': 'Audio', 'file': 'breathing_session.mp3'},
        {'title': 'Self-Care Habit Tracker & Reflection', 'type': 'Assignment', 'file': 'week2_tracker.pdf'},
      ],
    ),
    CreatedCourseModel(
      id: 'c2',
      title: 'Single Parent Emotional Strength & Resilience',
      subtitle: 'Overcoming burnout and balancing single parenthood',
      category: 'SINGLE_PARENT',
      duration: '6 Weeks',
      priceBdt: 1200,
      thumbnailUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
      instructorName: 'Dr. Mekhala Sarkar',
      lessons: [
        {'title': 'Building Healthy Work-Life Boundaries', 'type': 'Video', 'file': 'boundaries_lesson.mp4'},
        {'title': 'Stress Relief Meditation', 'type': 'Audio', 'file': 'meditation_audio.mp3'},
      ],
    ),
  ];

  List<CreatedCourseModel> get createdCourses {
    final name = _profile.fullName.trim().toLowerCase();
    if (name.isEmpty) return List.unmodifiable(_createdCourses);
    final filtered = _createdCourses.where((c) {
      final inst = c.instructorName.trim().toLowerCase();
      if (inst.isEmpty) return true;
      return inst == name || name.contains(inst) || inst.contains(name);
    }).toList();
    return List.unmodifiable(filtered);
  }

  List<SpecialistAppointmentModel> _patientBookedSessions = [];
  List<SpecialistAppointmentModel> get patientBookedSessions =>
      List.unmodifiable(_patientBookedSessions);

  SpecialistProvider() {
    _loadCoursesFromStorage();
    _loadAppointmentsFromStorage();
    fetchPatientBookedSessionsFromBackend();
  }

  Future<void> _loadAppointmentsFromStorage([String? email]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = email ?? prefs.getString('saved_user_email') ?? '';
      if (userEmail.isNotEmpty) {
        final savedStr = prefs.getString('persisted_patient_booked_sessions_v4_${userEmail.toLowerCase()}');
        if (savedStr != null) {
          final List<dynamic> decoded = jsonDecode(savedStr);
          _patientBookedSessions = decoded.map((a) => SpecialistAppointmentModel(
            id: a['id'].toString(),
            patientId: a['patientId'] ?? 'pat_new',
            patientName: a['patientName'] ?? 'Patient User',
            patientAvatar: a['patientAvatar'] ?? '',
            specialistName: a['specialistName'] ?? 'Dr. Mekhala Sarkar',
            specialistAvatar: a['specialistAvatar'] ?? '',
            date: a['date'] ?? 'Today',
            timeSlot: a['timeSlot'] ?? '10:00 AM - 11:00 AM',
            category: a['category'] ?? 'Mental Wellness',
            status: a['status'] ?? 'confirmed',
            meetingLink: a['meetingLink'] ?? 'https://meet.google.com/ash-wash-wellness',
            notes: a['notes'] ?? 'Booked session',
          )).toList();
          notifyListeners();
          return;
        }
      }
      _patientBookedSessions = [];
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveAppointmentsToStorage([String? email]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = email ?? prefs.getString('saved_user_email') ?? '';
      if (userEmail.isNotEmpty) {
        final jsonList = _patientBookedSessions.map((a) => {
          'id': a.id,
          'patientId': a.patientId,
          'patientName': a.patientName,
          'patientAvatar': a.patientAvatar,
          'specialistName': a.specialistName,
          'specialistAvatar': a.specialistAvatar,
          'date': a.date,
          'timeSlot': a.timeSlot,
          'category': a.category,
          'status': a.status,
          'meetingLink': a.meetingLink,
          'notes': a.notes,
        }).toList();
        await prefs.setString('persisted_patient_booked_sessions_v4_${userEmail.toLowerCase()}', jsonEncode(jsonList));
      }
    } catch (_) {}
  }

  void clearPatientData() {
    _patientBookedSessions = [];
    notifyListeners();
    // Immediately re-fetch from backend for the current user
    fetchPatientBookedSessionsFromBackend();
  }

  /// Fetches the authenticated patient's booked sessions from the backend
  /// and persists them to user-scoped SharedPreferences.
  Future<void> fetchPatientBookedSessionsFromBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('saved_user_email') ?? '';

      final data = await ApiService.get(ApiEndpoints.bookings, requireAuth: true);

      List<dynamic> rawList = [];
      if (data is List) {
        rawList = data;
      } else if (data is Map && data['results'] is List) {
        rawList = data['results'] as List;
      } else if (data is Map && data['bookings'] is List) {
        rawList = data['bookings'] as List;
      }

      if (rawList.isNotEmpty) {
        final backendItems = rawList.map((a) {
          final Map<String, dynamic> item = Map<String, dynamic>.from(a);
          return SpecialistAppointmentModel(
            id: (item['id'] ?? item['booking_id'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
            patientId: (item['patient'] ?? item['patient_id'] ?? 'pat_unknown').toString(),
            patientName: item['patient_name'] ?? item['patient']?['name'] ?? 'Patient',
            patientAvatar: item['patient_avatar'] ?? item['patient']?['avatar'] ?? '',
            specialistName: item['specialist_name'] ?? item['specialist']?['name'] ?? item['specialist']?['full_name'] ?? 'Specialist',
            specialistAvatar: item['specialist_avatar'] ?? item['specialist']?['avatar'] ?? '',
            date: item['date'] ?? item['booking_date'] ?? item['scheduled_date'] ?? 'N/A',
            timeSlot: item['time_slot'] ?? item['time'] ?? item['scheduled_time'] ?? 'N/A',
            category: item['category'] ?? item['service_type'] ?? 'Mental Wellness',
            status: item['status'] ?? 'confirmed',
            meetingLink: item['meeting_link'] ?? item['video_link'] ?? 'https://meet.google.com/ash-wash-wellness',
            notes: item['notes'] ?? item['patient_notes'] ?? '',
          );
        }).toList();

        final Map<String, SpecialistAppointmentModel> mergedMap = {};
        for (var localApp in _patientBookedSessions) {
          mergedMap[localApp.id] = localApp;
        }
        for (var bApp in backendItems) {
          mergedMap[bApp.id] = bApp;
        }
        _patientBookedSessions = mergedMap.values.toList();
      } else {
        if (_patientBookedSessions.isEmpty && userEmail.isNotEmpty) {
          await _loadAppointmentsFromStorage(userEmail);
        }
      }

      // Persist merged sessions to user-scoped storage
      if (userEmail.isNotEmpty && _patientBookedSessions.isNotEmpty) {
        final jsonList = _patientBookedSessions.map((a) => {
          'id': a.id,
          'patientId': a.patientId,
          'patientName': a.patientName,
          'patientAvatar': a.patientAvatar,
          'specialistName': a.specialistName,
          'specialistAvatar': a.specialistAvatar,
          'date': a.date,
          'timeSlot': a.timeSlot,
          'category': a.category,
          'status': a.status,
          'meetingLink': a.meetingLink,
          'notes': a.notes,
        }).toList();
        await prefs.setString(
          'persisted_patient_booked_sessions_v4_${userEmail.toLowerCase()}',
          jsonEncode(jsonList),
        );
      }

      notifyListeners();
    } catch (_) {
      // Keep existing _patientBookedSessions on network failure
    }
  }

  void addAppointment(SpecialistAppointmentModel appointment) {
    _patientBookedSessions.insert(0, appointment);
    _saveAppointmentsToStorage();
    notifyListeners();
  }

  Future<void> _loadCoursesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('persisted_specialist_created_courses_v2');
      if (savedStr != null) {
        final List<dynamic> decoded = jsonDecode(savedStr);
        final loaded = decoded.map((c) => CreatedCourseModel(
          id: c['id'].toString(),
          title: c['title'] ?? '',
          subtitle: c['subtitle'] ?? '',
          category: c['category'] ?? 'POSTPARTUM_DEPRESSION',
          duration: c['duration'] ?? '4 Weeks',
          priceBdt: c['priceBdt'] ?? 0,
          thumbnailUrl: c['thumbnailUrl'] ?? 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500',
          instructorName: c['instructorName'] ?? _profile.fullName,
          lessons: List<Map<String, String>>.from((c['lessons'] as List? ?? []).map((l) => Map<String, String>.from(l))),
        )).toList();
        
        for (var c in loaded) {
          if (!_createdCourses.any((item) => item.id == c.id)) {
            _createdCourses.insert(0, c);
          }
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveCoursesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _createdCourses.map((c) => {
        'id': c.id,
        'title': c.title,
        'subtitle': c.subtitle,
        'category': c.category,
        'duration': c.duration,
        'priceBdt': c.priceBdt,
        'thumbnailUrl': c.thumbnailUrl,
        'instructorName': c.instructorName,
        'lessons': c.lessons,
      }).toList();
      await prefs.setString('persisted_specialist_created_courses_v2', jsonEncode(jsonList));
    } catch (_) {}
  }

  void addCourse(CreatedCourseModel course) {
    _createdCourses.insert(0, course);
    _saveCoursesToStorage();
    notifyListeners();
  }

  void updateCourse(CreatedCourseModel updatedCourse) {
    final idx = _createdCourses.indexWhere((c) => c.id == updatedCourse.id);
    if (idx != -1) {
      _createdCourses[idx] = updatedCourse;
      _saveCoursesToStorage();
      notifyListeners();
    }
  }

  Future<void> deleteCourse(String courseId) async {
    _createdCourses.removeWhere((c) => c.id == courseId);
    _saveCoursesToStorage();
    notifyListeners();
    try {
      await ApiService.delete('/api/courses/$courseId/', requireAuth: true);
    } catch (_) {}
  }

  final List<SpecialistAppointmentModel> _appointments = [
    SpecialistAppointmentModel(
      id: 'app_1',
      patientId: 'pat_1',
      patientName: 'Nusrat Sultana',
      patientAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      date: 'Today',
      timeSlot: '10:30 AM - 11:30 AM',
      category: 'Postpartum Depression',
      status: 'confirmed',
      meetingLink: 'https://meet.google.com/ash-wash-wellness-101',
      notes: 'Follow up on Week 3 mood reflection journal.',
    ),
    SpecialistAppointmentModel(
      id: 'app_2',
      patientId: 'pat_2',
      patientName: 'Sadia Rahman',
      patientAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      date: 'Today',
      timeSlot: '03:00 PM - 04:00 PM',
      category: 'Single Parent Care',
      status: 'pending',
      meetingLink: 'https://meet.google.com/ash-wash-wellness-102',
      notes: 'Initial intake consultation for stress management.',
    ),
    SpecialistAppointmentModel(
      id: 'app_3',
      patientId: 'pat_3',
      patientName: 'Meherun Nesa',
      patientAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      date: 'Tomorrow',
      timeSlot: '05:00 PM - 06:00 PM',
      category: 'Corporate Burnout',
      status: 'confirmed',
      meetingLink: 'https://meet.google.com/ash-wash-wellness-103',
      notes: 'Workplace anxiety assessment.',
    ),
  ];

  List<SpecialistAppointmentModel> get appointments => List.unmodifiable(_appointments);

  final List<PatientRecordModel> _patients = [
    PatientRecordModel(
      id: 'pat_1',
      name: 'Nusrat Sultana',
      email: 'nusrat.sultana@gmail.com',
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      category: 'Postpartum Depression',
      age: 28,
      moodState: '😊 Calm & Positive',
      assessmentScore: 14, // EPDS Scale (Low Risk)
      courseProgress: 45,
      homeworkCompleted: 4,
      quizScore: 85,
      certificateIssued: false,
      completedSessions: 5,
      doctorNotes: 'Patient shows great reduction in postpartum anxiety. Recommended to complete Module 3.',
    ),
    PatientRecordModel(
      id: 'pat_2',
      name: 'Sadia Rahman',
      email: 'sadia.rahman@gmail.com',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      category: 'Single Parent Care',
      age: 32,
      moodState: '😐 Neutral',
      assessmentScore: 24,
      courseProgress: 20,
      homeworkCompleted: 2,
      quizScore: 70,
      certificateIssued: false,
      completedSessions: 3,
      doctorNotes: 'Experiencing workplace burnout. Practice daily micro-relaxation techniques.',
    ),
    PatientRecordModel(
      id: 'pat_3',
      name: 'Meherun Nesa',
      email: 'meherun.nesa@gmail.com',
      avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      category: 'Corporate Employee',
      age: 26,
      moodState: '😃 Very Happy',
      assessmentScore: 8,
      courseProgress: 100,
      homeworkCompleted: 8,
      quizScore: 95,
      certificateIssued: true,
      completedSessions: 8,
      doctorNotes: 'Course successfully completed! High emotional resilience achieved.',
    ),
  ];

  List<PatientRecordModel> get patients => List.unmodifiable(_patients);

  final List<HomeworkSubmissionModel> _homeworkSubmissions = [
    HomeworkSubmissionModel(
      id: 'hw_1',
      patientId: 'pat_1',
      patientName: 'Nusrat Sultana',
      patientAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      courseTitle: 'Postpartum Depression Recovery Program',
      assignmentTitle: 'Week 2 Self-Care Habit Tracker & Reflection',
      submittedAt: '10 mins ago',
      submissionText: 'I completed all 3 daily habits this week and practiced breathing exercises whenever feeling overwhelmed. My sleep has improved significantly.',
      status: 'pending',
    ),
    HomeworkSubmissionModel(
      id: 'hw_2',
      patientId: 'pat_2',
      patientName: 'Sadia Rahman',
      patientAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      courseTitle: 'Single Parent Emotional Strength',
      assignmentTitle: 'Work-Life Balance & Boundary Journal',
      submittedAt: '1 hour ago',
      submissionText: 'I set a firm boundary with overtime work on Wednesday and spent 2 hours un-interrupted with my son.',
      status: 'pending',
    ),
  ];

  List<HomeworkSubmissionModel> get pendingHomeworkSubmissions =>
      _homeworkSubmissions.where((h) => h.status == 'pending').toList();

  void updateProfile(SpecialistProfileModel updatedProfile) {
    _profile = updatedProfile;
    _profile.isProfileComplete = true;
    notifyListeners();
  }

  void updateAppointmentStatus(String id, String newStatus) {
    final idx = _appointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _appointments[idx].status = newStatus;
      notifyListeners();
    }
  }

  void reviewHomework(String id, {required String status, required int grade, required String feedback}) {
    final idx = _homeworkSubmissions.indexWhere((h) => h.id == id);
    if (idx != -1) {
      _homeworkSubmissions[idx].status = status;
      _homeworkSubmissions[idx].grade = grade;
      _homeworkSubmissions[idx].feedback = feedback;
      notifyListeners();
    }
  }

  void updateDoctorNotes(String patientId, String notes) {
    final idx = _patients.indexWhere((p) => p.id == patientId);
    if (idx != -1) {
      _patients[idx].doctorNotes = notes;
      notifyListeners();
    }
  }

  String generateMeetingLink() {
    final randId = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return 'https://meet.google.com/ash-wash-session-$randId';
  }
}
