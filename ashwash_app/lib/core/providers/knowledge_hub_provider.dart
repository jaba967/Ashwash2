import 'package:flutter/material.dart';
import '../network/api_endpoints.dart';
import '../network/api_service.dart';

class KnowledgeHubProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  String _selectedResourceFilter = 'ALL'; // ALL, ARTICLE, VIDEO, AUDIO
  String _selectedGameDifficulty = 'ALL'; // ALL, EASY, MEDIUM, HARD

  List<Map<String, dynamic>> _resources = [];
  List<Map<String, dynamic>> _mindGames = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedResourceFilter => _selectedResourceFilter;
  String get selectedGameDifficulty => _selectedGameDifficulty;

  List<Map<String, dynamic>> get resources {
    if (_selectedResourceFilter == 'ALL') {
      return _resources;
    }
    return _resources
        .where((r) => (r['content_type'] ?? '').toString().toUpperCase() == _selectedResourceFilter)
        .toList();
  }

  List<Map<String, dynamic>> get mindGames => _mindGames;

  KnowledgeHubProvider() {
    fetchResources();
    fetchMindGames();
  }

  Future<void> fetchResources({String? typeFilter}) async {
    _isLoading = true;
    if (typeFilter != null) _selectedResourceFilter = typeFilter;
    notifyListeners();

    try {
      final filterParam = _selectedResourceFilter != 'ALL' ? '?type=${_selectedResourceFilter.toLowerCase()}' : '';
      final data = await ApiService.get('${ApiEndpoints.resources}$filterParam', requireAuth: false);
      List<Map<String, dynamic>> rawList = [];
      if (data is List) {
        rawList = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['results'] != null) {
        rawList = List<Map<String, dynamic>>.from(data['results']);
      }
      if (rawList.isNotEmpty) {
        final formattedBackendItems = rawList.map((item) {
          final resType = (item['resource_type'] ?? item['content_type'] ?? 'ARTICLE').toString().toUpperCase();
          final mediaUrl = item['effective_media_url'] ?? item['media_url'] ?? item['media_file'] ?? '';
          return {
            'id': item['id'],
            'title': item['title_en'] ?? item['title'] ?? 'Knowledge Resource',
            'title_bn': item['title_bn'] ?? item['title_en'] ?? 'নলেজ রিসোর্স',
            'description': item['summary_bn'] ?? item['summary_en'] ?? item['description'] ?? '',
            'content_type': resType,
            'content_type_display': resType == 'AUDIO' ? 'Audio' : (resType == 'VIDEO' ? 'Video' : (resType == 'PDF' ? 'PDF Book' : 'Article')),
            'media_url': mediaUrl,
            'duration_display': item['duration_minutes'] != null ? '${item['duration_minutes']} min' : (item['duration_display'] ?? '10 min'),
            'is_premium': item['is_premium'] ?? false,
            'price': (item['is_premium'] ?? false) ? r'৳50' : 'Free',
            'content_text': item['content_bn'] ?? item['content_en'] ?? '',
          };
        }).toList();
        
        final prodItems = _getProductionResources();
        // Place Admin uploaded items first
        _resources = [...formattedBackendItems, ...prodItems];
      } else {
        _resources = _getProductionResources();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _resources = _getProductionResources();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _getProductionResources() {
    return [
      // 1. FREE AUDIO 1
      {
        'id': 101,
        'title': 'Mixkit Time Out Relaxation & Breathing Track',
        'title_bn': 'টাইম-আউট রিলেক্সেশন ও শ্বাসের অডিও',
        'description': 'Calming acoustic audio designed for 10-minute stress relief and deep breathing practice.',
        'content_type': 'AUDIO',
        'content_type_display': 'Audio',
        'media_url': 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493228/mixkit-time-out-92_cxu9hq.mp3',
        'duration_display': '3:45 min',
        'is_premium': false,
        'price': 'Free',
      },
      // 2. FREE AUDIO 2
      {
        'id': 102,
        'title': 'Leberch Deep Meditation & Calm Music',
        'title_bn': 'গভীর মেডিটেশন ও প্রশান্তিদায়ক অডিও ট্র্যাক',
        'description': 'Deep meditative waves helping lower heart rate, ease anxiety, and promote restful sleep.',
        'content_type': 'AUDIO',
        'content_type_display': 'Audio',
        'media_url': 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493206/leberch-meditation-509071_vjnfiw.mp3',
        'duration_display': '5:12 min',
        'is_premium': false,
        'price': 'Free',
      },
      // 3. FREE AUDIO 3
      {
        'id': 103,
        'title': 'Monume Ambient Wellness Meditation Track',
        'title_bn': 'মাইন্ডফুলনেস ও মানসিক স্থৈর্যবর্ধক অডিও',
        'description': 'Soothing background meditation track for daily focus, work breaks, and emotional grounding.',
        'content_type': 'AUDIO',
        'content_type_display': 'Audio',
        'media_url': 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493145/monume-meditation-meditation-music-570695_nxg03k.mp3',
        'duration_display': '4:30 min',
        'is_premium': false,
        'price': 'Free',
      },
      // 4. PAID AUDIO (Price max ৳50)
      {
        'id': 104,
        'title': 'Verclub Masterclass Guided Meditation (Paid)',
        'title_bn': 'ভারক্লাব প্রিমিয়াম গাইডেড মেডিটেশন (পেইড)',
        'description': 'Exclusive clinical-grade guided audio session for anxiety disorder relief and deep mental rejuvenation.',
        'content_type': 'AUDIO',
        'content_type_display': 'Audio (Paid)',
        'media_url': 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493086/verclub_music-meditation-music-550885_vcek1p.mp3',
        'duration_display': '15:00 min',
        'is_premium': true,
        'price': r'৳50',
      },

      // 5. FREE VIDEO 1
      {
        'id': 201,
        'title': 'Mindful Nature Meditation & Breathing Visualizer',
        'title_bn': 'প্রকৃতির সান্নিধ্যে ভিজ্যুয়াল মেডিটেশন',
        'description': 'HD relaxing visual video with natural landscapes for visual mindfulness and anxiety reduction.',
        'content_type': 'VIDEO',
        'content_type_display': 'Video',
        'media_url': 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493355/istockphoto-1253263447-640_adpp_is_n8i3m0.mp4',
        'duration_display': '2:15 min',
        'is_premium': false,
        'price': 'Free',
      },
      // 6. FREE VIDEO 2
      {
        'id': 202,
        'title': 'Tranquil Forest & Water Stream Relaxation Video',
        'title_bn': 'শান্ত বনভূমি ও জলপ্রপাতের মানসিক রিলেক্সেশন ভিজ্যুয়াল',
        'description': 'UHD 4K nature video stream to de-stress eyes and mind during long working hours.',
        'content_type': 'VIDEO',
        'content_type_display': 'Video',
        'media_url': 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493620/6941384-uhd_4096_2160_25fps_asotry.mp4',
        'duration_display': '6:40 min',
        'is_premium': false,
        'price': 'Free',
      },
      // 7. PAID VIDEO (Price max ৳50)
      {
        'id': 203,
        'title': 'Specialist Therapy Session Video Class (Paid)',
        'title_bn': 'বিশেষজ্ঞ চিকিৎসকের সাইকোথেরাপি সেশন (পেইড)',
        'description': 'Exclusive 4K video masterclass by licensed clinical psychologists on managing severe panic & stress.',
        'content_type': 'VIDEO',
        'content_type_display': 'Video (Paid)',
        'media_url': 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785494530/244839_medium_oib2g0.mp4',
        'duration_display': '25:00 min',
        'is_premium': true,
        'price': r'৳50',
      },

      // 8. FREE PDF BOOK 1 (Student Stress Booklet)
      {
        'id': 301,
        'title': 'Stress – A Short Guide for Students',
        'title_bn': 'শিক্ষার্থীদের মানসিক চাপ নিয়ন্ত্রণ গাইড (PDF)',
        'author': 'University of Edinburgh',
        'description': 'Official Student Stress Guide PDF by University of Edinburgh Student Counselling Service detailing breathing, relaxation, and positive thinking.',
        'content_type': 'ARTICLE',
        'content_type_display': 'PDF Book',
        'media_url': 'https://www.docs.sasg.ed.ac.uk/StudentCounselling/SCSbooklets/SCSstressbooklet.pdf',
        'content_text': '''STRESS - A Short Guide for Students (Official PDF Document)

Direct Download / View PDF: https://www.docs.sasg.ed.ac.uk/StudentCounselling/SCSbooklets/SCSstressbooklet.pdf

Publisher: The University of Edinburgh Student Counselling Service

Core Strategies & Techniques:
1. Becoming Aware of Stress (Physical & Emotional Signs).
2. Calming Breath Technique (Ribcage expansion & slow exhales).
3. The Stop! Technique (Instant facial & shoulder tension release).
4. Progressive Muscular Relaxation (Muscle group tension-release cycles).
5. Positive Thinking & Action (Reframing catastrophic thoughts).''',
        'duration_display': 'PDF Book',
        'is_premium': false,
        'price': 'Free',
      },

      // 9. FREE PDF BOOK 2 (Think Straight)
      {
        'id': 302,
        'title': 'THINK STRAIGHT: Change Your Thoughts, Change Your Life',
        'title_bn': 'থিংক স্ট্রেইট: চিন্তাভাবনা পরিমার্জন ও মানসিক প্রশান্তি (PDF)',
        'author': 'Darius Foroux',
        'description': 'Full PDF Book of THINK STRAIGHT by Darius Foroux on practical thinking, filtering useless thoughts, and mastering inner calm.',
        'content_type': 'ARTICLE',
        'content_type_display': 'PDF Book',
        'media_url': 'https://crpf.gov.in/writereaddata/images/pdf/Think_Straight.pdf',
        'content_text': '''THINK STRAIGHT - Change Your Thoughts, Change Your Life (Full PDF Book)

Direct Download / View PDF: https://crpf.gov.in/writereaddata/images/pdf/Think_Straight.pdf

Author: Darius Foroux

Key Principles:
1. Control What You Think ("If you can change your mind, you can change your life").
2. From Chaos to Clarity (Filtering useless thoughts and focus on constructive actions).
3. Inside Your Control vs Outside Your Control (Focus energy on desires, words, and actions).
4. Inner Calm (Observing thoughts without judgment).
5. Action > Thinking (Daily routines to execute goals).''',
        'duration_display': 'PDF Book',
        'is_premium': false,
        'price': 'Free',
      },

      // 10. FREE PDF BOOK 3 (Mental Health Care Guidebook)
      {
        'id': 303,
        'title': 'Mental Health Care in Resource-Limited Settings',
        'title_bn': 'সীমিত সম্পদের এলাকায় মানসিক স্বাস্থ্যসেবা ম্যানুয়াল (PDF)',
        'author': 'Pamela Smith, MD',
        'description': 'Full PDF Guidebook by Pamela Smith, MD for healthcare providers on clinical mental health care, depression, bipolar disorder, and PTSD management.',
        'content_type': 'ARTICLE',
        'content_type_display': 'PDF Book',
        'media_url': 'https://www.globalfamilydoctor.com/site/DefaultSite/filesystem/documents/resources/MHGuidebook-EBookDownload.pdf',
        'content_text': '''MENTAL HEALTH CARE in Settings Where Mental Health Resources Are Limited (Full PDF)

Direct Download / View PDF: https://www.globalfamilydoctor.com/site/DefaultSite/filesystem/documents/resources/MHGuidebook-EBookDownload.pdf

Author: Pamela Smith, MD

Table of Contents & Core Interventions:
PART I: Mental Health Worldwide & Global Burden.
PART II: Capacity Building & Primary Care Integration.
PART III: Clinical Interventions for Psychosis, Major Depression, Anxiety, OCD, PTSD, and Child Mental Health.''',
        'duration_display': 'PDF Book',
        'is_premium': false,
        'price': 'Free',
      },

      // 11. FREE WHO OFFICIAL DIRECT WEB RESOURCE
      {
        'id': 304,
        'title': 'WHO Official Mental Health & Clinical Guidelines',
        'title_bn': 'বিশ্ব স্বাস্থ্য সংস্থার (WHO) অফিশিয়াল মানসিক স্বাস্থ্য পোর্টাল',
        'author': 'World Health Organization',
        'description': 'Direct official link to World Health Organization (WHO) web portal for clinical guidelines, stress management, and evidence-based mental health resources.',
        'content_type': 'ARTICLE',
        'content_type_display': 'Article (WHO Official Web)',
        'media_url': 'https://www.who.int/health-topics/mental-health',
        'content_text': '''World Health Organization (WHO) Official Mental Health Direct Portal:

Official WHO Website Link: https://www.who.int/health-topics/mental-health

WHO Core Mental Health Directives:
- Evidence-based psychological first aid for individuals and disaster-affected communities.
- Clinical guidelines on depression, stress management, and self-care interventions.
- Global mental health policy standards and human rights advocacy.''',
        'duration_display': 'WHO Web Direct',
        'is_premium': false,
        'price': 'Free',
      },
    ];
  }

  Future<void> fetchMindGames({String? difficultyFilter}) async {
    if (difficultyFilter != null) _selectedGameDifficulty = difficultyFilter;
    notifyListeners();

    try {
      final param = _selectedGameDifficulty != 'ALL' ? '?difficulty=$_selectedGameDifficulty' : '';
      final data = await ApiService.get('${ApiEndpoints.mindGames}$param', requireAuth: true);
      _mindGames = List<Map<String, dynamic>>.from(data['results'] ?? data);
    } catch (e) {
      _mindGames = [
        {
          'id': 1,
          'title': 'Memory Match',
          'description': 'Match pairs of cards to improve memory and concentration skills.',
          'difficulty': 'EASY',
          'duration_mins': 10,
        },
      ];
    } finally {
      notifyListeners();
    }
  }

  void setResourceFilter(String filter) {
    _selectedResourceFilter = filter;
    notifyListeners();
  }

  void setGameDifficulty(String difficulty) {
    _selectedGameDifficulty = difficulty;
    fetchMindGames();
  }

  void unlockResourceLocally(int id) {
    for (var r in _resources) {
      if (r['id'] == id) {
        r['is_premium'] = false;
        r['price'] = 'Unlocked';
      }
    }
    notifyListeners();
  }
}
