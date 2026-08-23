import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/course_model.dart';

class QuizDialog extends StatefulWidget {
  final List<QuizQuestion> quizQuestions;
  final Function(double score, bool passed) onQuizCompleted;

  const QuizDialog({
    Key? key,
    required this.quizQuestions,
    required this.onQuizCompleted,
  }) : super(key: key);

  @override
  State<QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<QuizDialog> {
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  bool _isSubmitted = false;
  int _score = 0;

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quizQuestions.length - 1) {
      setState(() => _currentQuestionIndex++);
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }

  void _submitQuiz() {
    int correctCount = 0;
    for (int i = 0; i < widget.quizQuestions.length; i++) {
      if (_selectedAnswers[i] == widget.quizQuestions[i].correctAnswerIndex) {
        correctCount++;
      }
    }
    final double percentage = (correctCount / widget.quizQuestions.length) * 100;
    final bool passed = percentage >= 70.0;

    setState(() {
      _score = correctCount;
      _isSubmitted = true;
    });

    widget.onQuizCompleted(percentage, passed);
  }

  void _retakeQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
      _isSubmitted = false;
      _score = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quizQuestions.isEmpty) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.quiz_rounded, size: 48, color: Colors.black),
              SizedBox(height: 12),
              Text('No quiz questions available for this course.'),
            ],
          ),
        ),
      );
    }

    final currentQuestion = widget.quizQuestions[_currentQuestionIndex];
    final double percentage = (_score / widget.quizQuestions.length) * 100;
    final bool passed = percentage >= 70.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: _isSubmitted
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    passed ? Icons.emoji_events_rounded : Icons.cancel_outlined,
                    size: 64,
                    color: passed ? Colors.amber : AppColors.emergency,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    passed ? 'Congratulations! 🎉' : 'Quiz Not Passed',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Score: $_score / ${widget.quizQuestions.length} (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: passed ? Colors.green : AppColors.emergency,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    passed
                        ? 'Passing score is 70%. You passed the course quiz!'
                        : 'Passing score is 70%. Please review course materials and retake.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (!passed)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _retakeQuiz,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Retake Quiz'),
                          ),
                        ),
                      if (!passed) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentQuestionIndex + 1} of ${widget.quizQuestions.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / widget.quizQuestions.length,
                      backgroundColor: Colors.white,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      currentQuestion.question,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                    const SizedBox(height: 16),

                    ...List.generate(currentQuestion.options.length, (optIdx) {
                      final isSelected = _selectedAnswers[_currentQuestionIndex] == optIdx;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedAnswers[_currentQuestionIndex] = optIdx;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.white,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isSelected ? AppColors.primary : Colors.white,
                                  child: Text(
                                    String.fromCharCode(65 + optIdx),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    currentQuestion.options[optIdx],
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? AppColors.primary : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                          child: const Text('Previous'),
                        ),
                        if (_currentQuestionIndex < widget.quizQuestions.length - 1)
                          ElevatedButton(
                            onPressed: _selectedAnswers.containsKey(_currentQuestionIndex) ? _nextQuestion : null,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: const Text('Next Question', style: TextStyle(color: Colors.white)),
                          )
                        else
                          ElevatedButton(
                            onPressed: _selectedAnswers.length == widget.quizQuestions.length ? _submitQuiz : null,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Submit Quiz ✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
