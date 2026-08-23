import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/course_model.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/api_endpoints.dart';

class LessonPlayerDialog extends StatefulWidget {
  final CourseLesson lesson;
  final VoidCallback onCompleted;

  const LessonPlayerDialog({
    Key? key,
    required this.lesson,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<LessonPlayerDialog> createState() => _LessonPlayerDialogState();
}

class _LessonPlayerDialogState extends State<LessonPlayerDialog> {
  bool _isPlaying = false;
  bool _isMarkingComplete = false;
  double _audioProgress = 0.3;

  /// Calls backend to mark this lesson complete → triggers progress update
  /// and specialist notification/certificate creation when all lessons done.
  Future<void> _markLessonCompleteOnBackend() async {
    if (_isMarkingComplete) return;
    setState(() => _isMarkingComplete = true);
    try {
      final lessonIdStr = widget.lesson.id.replaceAll(RegExp(r'[^0-9]'), '');
      final lessonId = int.tryParse(lessonIdStr);
      if (lessonId != null && lessonId > 0) {
        await ApiService.post(
          '${ApiEndpoints.courses}lessons/$lessonId/complete/',
          {},
          requireAuth: true,
        );
      }
    } catch (_) {}
    // Call Flutter onCompleted callback regardless of network result
    widget.onCompleted();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson marked as completed! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _launchUrl(String urlString, {bool isPdf = false}) async {
    if (urlString.isEmpty) return;
    
    // For PDFs, use Google Docs viewer if it's a direct PDF link to bypass browser download loops
    String finalUrl = urlString;
    if (isPdf && urlString.toLowerCase().endsWith('.pdf')) {
      finalUrl = 'https://docs.google.com/viewer?url=$urlString';
    }

    try {
      final Uri uri = Uri.parse(finalUrl);
      // Try external application first (e.g., native browser or PDF app)
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        // Fallback to in-app browser view
        final Uri uri = Uri.parse(finalUrl);
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open media: $finalUrl')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (lesson.type == 'video') ...[
                      GestureDetector(
                        onTap: () => _launchUrl(lesson.contentUrl),
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.play_circle_fill_rounded,
                                size: 64,
                                color: Colors.black,
                              ),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    lesson.duration,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () => _launchUrl(lesson.contentUrl),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Play Full Video (HD Stream)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _isMarkingComplete ? null : _markLessonCompleteOnBackend,
                        icon: _isMarkingComplete
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_rounded),
                        label: Text(_isMarkingComplete ? 'Saving...' : 'Mark Lesson as Completed ✓'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ] else if (lesson.type == 'audio') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.graphic_eq_rounded, size: 48, color: Colors.black),
                            const SizedBox(height: 12),
                            Slider(
                              value: _audioProgress,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _audioProgress = val),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('04:12', style: TextStyle(fontSize: 12, color: Colors.white)),
                                Text(lesson.duration, style: const TextStyle(fontSize: 12, color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            IconButton(
                              iconSize: 52,
                              icon: Icon(
                                _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                setState(() => _isPlaying = !_isPlaying);
                                _launchUrl(lesson.contentUrl);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _isMarkingComplete ? null : _markLessonCompleteOnBackend,
                        icon: _isMarkingComplete
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_rounded),
                        label: Text(_isMarkingComplete ? 'Saving...' : 'Mark Lesson as Completed ✓'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ] else if (lesson.type == 'pdf') ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, size: 54, color: Colors.amber),
                            const SizedBox(height: 12),
                            Text(
                              lesson.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _launchUrl(lesson.contentUrl, isPdf: true),
                              icon: const Icon(Icons.file_download_rounded),
                              label: const Text('Open / Download PDF Guide'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _isMarkingComplete ? null : _markLessonCompleteOnBackend,
                              icon: _isMarkingComplete
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.check_circle_rounded),
                              label: Text(_isMarkingComplete ? 'Saving...' : 'Mark Lesson as Completed ✓'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (lesson.type == 'task') ...[
                      HomeworkTaskWidget(
                        lesson: lesson,
                        onCompleted: widget.onCompleted,
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          lesson.description.isNotEmpty
                              ? lesson.description
                              : 'Read through the course materials carefully to complete this lesson task.',
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isMarkingComplete ? null : _markLessonCompleteOnBackend,
                        icon: _isMarkingComplete
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_rounded),
                        label: Text(_isMarkingComplete ? 'Saving...' : 'Mark Lesson as Completed ✓'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeworkTaskWidget extends StatefulWidget {
  final CourseLesson lesson;
  final VoidCallback onCompleted;

  const HomeworkTaskWidget({
    Key? key,
    required this.lesson,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<HomeworkTaskWidget> createState() => _HomeworkTaskWidgetState();
}

class _HomeworkTaskWidgetState extends State<HomeworkTaskWidget> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _existingSubmission;
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, String> _answers = {};

  @override
  void initState() {
    super.initState();
    _fetchSubmission();
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchSubmission() async {
    // Attempt to load existing submission
    try {
      
      final res = await ApiService.get('${ApiEndpoints.courses}homework/mine/', requireAuth: true);
      if (res is List) {
        // Find submission for this lesson
        final String lessonIdStr = widget.lesson.id.replaceAll(RegExp(r'[^0-9]'), '');
        for (var sub in res) {
           if (sub['lesson'].toString() == lessonIdStr || sub['lesson_details']?['id'].toString() == lessonIdStr) {
              _existingSubmission = sub;
              break;
           }
        }
      }
    } catch (e) {
      debugPrint('Error fetching submission: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitHomework() async {
    final questions = widget.lesson.homeworkQuestions;
    List<Map<String, dynamic>> submitAnswers = [];
    
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final isRequired = q['is_required'] ?? false;
      final qType = q['answer_type'] ?? 'short';

      // For yes_no and rating types, answers are stored in _answers map (not controllers)
      // For text types (short/long), answers are in _controllers
      String ans;
      if (qType == 'yes_no' || qType == 'rating') {
        ans = _answers[i] ?? '';
      } else {
        ans = _controllers[i]?.text.trim() ?? '';
      }

      if (isRequired && ans.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please answer question ${i + 1} (Required)'), backgroundColor: Colors.red),
        );
        return;
      }

      submitAnswers.add({
        'question': q['id'],
        'answer_text': ans,
      });
    }
    
    setState(() => _isSubmitting = true);
    try {
      final String lessonIdStr = widget.lesson.id.replaceAll('l_', '');
      
      final res = await ApiService.post(
        '${ApiEndpoints.courses}homework/submit/',
        {
          'lesson': int.tryParse(lessonIdStr) ?? 0,
          'answers': submitAnswers,
        },
        requireAuth: true,
      );
      
      if (res is Map && res.containsKey('id')) {
        // Also mark lesson complete on backend to update course progress
        try {
          final lessonIdForComplete = int.tryParse(lessonIdStr.replaceAll(RegExp(r'[^0-9]'), ''));
          if (lessonIdForComplete != null && lessonIdForComplete > 0) {
            await ApiService.post(
              '${ApiEndpoints.courses}lessons/$lessonIdForComplete/complete/',
              {},
              requireAuth: true,
            );
          }
        } catch (_) {}

        widget.onCompleted();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Homework submitted successfully! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Submission failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit homework'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_existingSubmission != null) {
      return _buildExistingSubmissionView();
    }

    final questions = widget.lesson.homeworkQuestions;
    if (questions.isEmpty) {
      return SingleChildScrollView(child: _buildLegacyTaskView());
    }

    return SingleChildScrollView(child: _buildFormView(questions));
  }

  Widget _buildExistingSubmissionView() {
    final status = _existingSubmission!['status'] ?? 'submitted';
    final feedback = _existingSubmission!['specialist_feedback'];
    final ansList = _existingSubmission!['answers'] as List? ?? [];
    final questions = widget.lesson.homeworkQuestions;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: status == 'reviewed' ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: status == 'reviewed' ? Colors.green : Colors.orange),
          ),
          child: Row(
            children: [
              Icon(
                status == 'reviewed' ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                color: status == 'reviewed' ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status == 'reviewed' ? 'Reviewed by Specialist' : 'Submitted (Pending Review)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: status == 'reviewed' ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                ),
              )
            ],
          ),
        ),
        if (feedback != null && feedback.toString().isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.comment_rounded, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Specialist Feedback', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(feedback, style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text('Your Answers:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...ansList.map((a) {
          final questionId = a['question'];
          String questionText = a['question_details']?['question_text'] ?? a['question_text'] ?? 'Question';
          
          if (questionText == 'Question' && questionId != null) {
            final qMatch = questions.firstWhere(
              (q) => q['id'] == questionId, 
              orElse: () => {'question_text': 'Question'}
            );
            questionText = qMatch['question_text'] ?? 'Question';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  questionText,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  a['answer_text'] ?? 'No answer',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    ),
    );
  }

  Widget _buildLegacyTaskView() {
    // For legacy string assignments, we fallback to a single controller
    if (!_controllers.containsKey(0)) _controllers[0] = TextEditingController();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: const Text('Assignment Question:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            widget.lesson.description.isNotEmpty ? widget.lesson.description : 'Please complete the assigned task.',
            style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Your Answer:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        TextField(
          controller: _controllers[0],
          maxLines: 4,
          style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: _inputDeco('Type your answer here...'),
        ),
        const SizedBox(height: 20),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildFormView(List<dynamic> questions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...questions.asMap().entries.map((entry) {
          final idx = entry.key;
          final q = entry.value;
          final isRequired = q['is_required'] ?? false;
          final qType = q['answer_type'] ?? 'short';
          
          if (!_controllers.containsKey(idx)) _controllers[idx] = TextEditingController();

          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Q${idx + 1}. ${q['question_text'] ?? ''}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                    children: [
                      if (isRequired)
                        const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (qType == 'short' || qType == 'long')
                  TextField(
                    controller: _controllers[idx],
                    maxLines: qType == 'long' ? 4 : 1,
                    style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: _inputDeco('Your answer...'),
                  )
                else if (qType == 'yes_no')
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Yes'),
                          value: 'Yes',
                          groupValue: _answers[idx],
                          onChanged: (val) => setState(() => _answers[idx] = val!),
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('No'),
                          value: 'No',
                          groupValue: _answers[idx],
                          onChanged: (val) => setState(() => _answers[idx] = val!),
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                        ),
                      ),
                    ],
                  )
                else if (qType == 'rating')
                  Slider(
                    value: double.tryParse(_answers[idx] ?? '5') ?? 5,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _answers[idx] ?? '5',
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _answers[idx] = val.toInt().toString()),
                  ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        _buildSubmitButton(),
      ],
    );
  }
  
  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _isSubmitting ? null : _submitHomework,
      icon: _isSubmitting 
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.send_rounded),
      label: Text(_isSubmitting ? 'Submitting...' : 'Submit Homework', style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
