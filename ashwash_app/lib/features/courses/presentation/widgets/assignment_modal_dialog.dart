import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/course_model.dart';

class AssignmentModalDialog extends StatefulWidget {
  final CourseAssignment assignment;
  final VoidCallback onSubmitted;

  const AssignmentModalDialog({
    Key? key,
    required this.assignment,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  State<AssignmentModalDialog> createState() => _AssignmentModalDialogState();
}

class _AssignmentModalDialogState extends State<AssignmentModalDialog> {
  // Mood Journal state
  int _selectedDay = 1;
  int _moodIndex = 1;
  String _sleepQuality = 'Good';
  bool _ateMeals = true;
  String _babyTime = 'Yes';
  final _journalCtrl = TextEditingController();

  // Sleep Tracker state
  final List<Map<String, dynamic>> _sleepLogs = List.generate(
    7,
    (index) => {
      'day': 'Day ${index + 1}',
      'bedTime': '10:30 PM',
      'wakeTime': '06:30 AM',
      'hours': '8 hrs',
      'rating': 4,
    },
  );
  bool _refreshed = true;

  // Gratitude state
  final _g1Ctrl = TextEditingController();
  final _g2Ctrl = TextEditingController();
  final _g3Ctrl = TextEditingController();
  String _gratitudeImpact = 'Better';
  final _gratitudeReflectCtrl = TextEditingController();

  // Self care checklist state
  final List<bool> _checklist = List.filled(10, false);
  final List<String> _checklistItems = [
    'Drank enough water 💧',
    'Ate healthy meals 🥗',
    'Took prescribed medicine 💊',
    'Rested at least 30 minutes 🛌',
    'Talked with a loved one 📞',
    'Went outside for fresh air 🌿',
    'Practiced breathing exercise 🧘‍♀️',
    'Took a short walk 🚶‍♀️',
    'Listened to relaxation audio 🎧',
    'Smiled today 😊',
  ];
  final _bestActivityCtrl = TextEditingController();

  // Bonding state
  final List<bool> _bondingChecklist = List.filled(8, false);
  final List<String> _bondingItems = [
    'Skin-to-skin contact',
    'Eye contact',
    'Singing to baby',
    'Reading a story',
    'Gentle massage',
    'Talking to baby',
    'Playing together',
    'Feeding with attention',
  ];
  String _bondingDuration = '30–60 minutes';
  int _connectionRating = 5;
  final _bondingReflectCtrl = TextEditingController();

  // Final Reflection state
  final _finalReflectionCtrl = TextEditingController();

  @override
  void dispose() {
    _journalCtrl.dispose();
    _g1Ctrl.dispose();
    _g2Ctrl.dispose();
    _g3Ctrl.dispose();
    _gratitudeReflectCtrl.dispose();
    _bestActivityCtrl.dispose();
    _bondingReflectCtrl.dispose();
    _finalReflectionCtrl.dispose();
    super.dispose();
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  void _submit() {
    final type = widget.assignment.type;

    if (type == 'mood_journal') {
      final words = _countWords(_journalCtrl.text);
      if (words < 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please write at least 30 words in your mood journal. (Current: $words words)'),
            backgroundColor: AppColors.emergency,
          ),
        );
        return;
      }
    } else if (type == 'gratitude_journal') {
      if (_g1Ctrl.text.trim().isEmpty || _g2Ctrl.text.trim().isEmpty || _g3Ctrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill out all 3 gratitude items before submitting.'),
            backgroundColor: AppColors.emergency,
          ),
        );
        return;
      }
      final words = _countWords(_gratitudeReflectCtrl.text);
      if (words < 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please write at least 50 words for your reflection. (Current: $words words)'),
            backgroundColor: AppColors.emergency,
          ),
        );
        return;
      }
    } else if (type == 'self_care_checklist') {
      final checkedCount = _checklist.where((item) => item).length;
      if (checkedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check off at least 1 self-care task completed today.'),
            backgroundColor: AppColors.emergency,
          ),
        );
        return;
      }
    } else if (type == 'bonding_activity') {
      final checkedCount = _bondingChecklist.where((item) => item).length;
      if (checkedCount < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please check off at least 1 bonding activity completed.'),
            backgroundColor: AppColors.emergency,
          ),
        );
        return;
      }
      final words = _countWords(_bondingReflectCtrl.text);
      if (words < 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please write at least 50 words for your bonding reflection. (Current: $words words)'),
            backgroundColor: AppColors.emergency,
          ),
        );
        return;
      }
    } else if (type == 'final_reflection') {
      final words = _countWords(_finalReflectionCtrl.text);
      if (words < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please write at least 300 words for your final reflection. (Current: $words words)'),
            backgroundColor: AppColors.emergency,
          ),
        );
        return;
      }
    }

    widget.onSubmitted();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assignment submitted successfully! Progress updated. 🎉'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                assignment.description,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              const Divider(height: 24),

              // 1. Mood Journal Form
              if (assignment.type == 'mood_journal') ...[
                Row(
                  children: [
                    const Text('Select Day: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<int>(
                      value: _selectedDay,
                      items: List.generate(
                        7,
                        (index) => DropdownMenuItem(value: index + 1, child: Text('Day ${index + 1}')),
                      ),
                      onChanged: (val) => setState(() => _selectedDay = val ?? 1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('😊 How are you feeling today?', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(5, (idx) {
                    final emojis = ['😃', '🙂', '😐', '😔', '😢'];
                    final labels = ['Very Happy', 'Good', 'Okay', 'Sad', 'Very Sad'];
                    return ChoiceChip(
                      label: Text('${emojis[idx]} ${labels[idx]}'),
                      selected: _moodIndex == idx,
                      onSelected: (val) => setState(() => _moodIndex = idx),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                const Text('😴 How did you sleep last night?', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: ['Excellent', 'Good', 'Fair', 'Poor'].map((q) {
                    return ChoiceChip(
                      label: Text(q),
                      selected: _sleepQuality == q,
                      onSelected: (val) => setState(() => _sleepQuality = q),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('🍽 Did you eat regular meals today? ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Switch(value: _ateMeals, onChanged: (val) => setState(() => _ateMeals = val)),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('✍ Write about your feelings today (Min 30 words):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _journalCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts, challenges, or small wins...',
                    hintStyle: TextStyle(color: Colors.white, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 4),
                Text('Word count: ${_countWords(_journalCtrl.text)} / 30 words', style: TextStyle(color: Colors.white, fontSize: 12)),
              ]

              // 2. Sleep Tracker Form
              else if (assignment.type == 'sleep_tracker') ...[
                const Text('📊 Weekly Sleep Log:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(_sleepLogs.length, (idx) {
                  final log = _sleepLogs[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(log['day'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${log['bedTime']} - ${log['wakeTime']} (${log['hours']})'),
                        Row(
                          children: List.generate(
                            5,
                            (starIdx) => Icon(
                              starIdx < (log['rating'] as int) ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Did you wake up feeling refreshed? ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Switch(value: _refreshed, onChanged: (val) => setState(() => _refreshed = val)),
                  ],
                ),
              ]

              // 3. Daily Gratitude Journal
              else if (assignment.type == 'gratitude_journal') ...[
                const Text('✨ 3 Things You are Grateful for Today:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: _g1Ctrl, decoration: const InputDecoration(labelText: '1. I am grateful for...', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: _g2Ctrl, decoration: const InputDecoration(labelText: '2. I am grateful for...', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: _g3Ctrl, decoration: const InputDecoration(labelText: '3. I am grateful for...', border: OutlineInputBorder())),
                const SizedBox(height: 14),
                const Text('How did writing gratitude make you feel?', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: ['Better', 'Same', 'Worse'].map((f) {
                    return ChoiceChip(
                      label: Text(f),
                      selected: _gratitudeImpact == f,
                      onSelected: (val) => setState(() => _gratitudeImpact = f),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text('Reflection (Minimum 50 words):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _gratitudeReflectCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Write a reflection on how positive thinking impacted your day...', border: OutlineInputBorder()),
                ),
              ]

              // 4. Self-Care Checklist
              else if (assignment.type == 'self_care_checklist') ...[
                const Text('✅ Check everything you completed today:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(_checklistItems.length, (idx) {
                  return CheckboxListTile(
                    title: Text(_checklistItems[idx]),
                    value: _checklist[idx],
                    onChanged: (val) => setState(() => _checklist[idx] = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                }),
                const SizedBox(height: 10),
                const Text('Which activity helped you the most?', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(controller: _bestActivityCtrl, decoration: const InputDecoration(hintText: 'e.g., The 30 minute rest and short walk', border: OutlineInputBorder())),
              ]

              // 5. Mother-Baby Bonding Activity
              else if (assignment.type == 'bonding_activity') ...[
                const Text('👶 Complete at least 3 bonding activities today:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(_bondingItems.length, (idx) {
                  return CheckboxListTile(
                    title: Text(_bondingItems[idx]),
                    value: _bondingChecklist[idx],
                    onChanged: (val) => setState(() => _bondingChecklist[idx] = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                }),
                const SizedBox(height: 12),
                const Text('How long did you spend with your baby today?', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 6,
                  children: ['< 15 minutes', '15–30 minutes', '30–60 minutes', '> 1 hour'].map((dur) {
                    return ChoiceChip(
                      label: Text(dur),
                      selected: _bondingDuration == dur,
                      onSelected: (val) => setState(() => _bondingDuration = dur),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('How connected did you feel? (1-5 Stars)', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: List.generate(
                    5,
                    (starIdx) => IconButton(
                      icon: Icon(starIdx < _connectionRating ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 28),
                      onPressed: () => setState(() => _connectionRating = starIdx + 1),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Reflection (Minimum 50 words):', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: _bondingReflectCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Describe how your baby reacted and how you felt...', border: OutlineInputBorder()),
                ),
              ]

              // 6. Final Recovery Reflection (300 Words)
              else if (assignment.type == 'final_reflection') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🎯 Write a 300-word Recovery Reflection covering:\n• What did you learn?\n• What changes did you notice in yourself?\n• Which lesson helped most?\n• What habits will you continue?\n• Message to another new mother experiencing PPD.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _finalReflectionCtrl,
                  maxLines: 8,
                  onChanged: (val) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Write your 300-word final recovery story...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Word count: ${_countWords(_finalReflectionCtrl.text)} / 300 words',
                  style: TextStyle(
                    color: _countWords(_finalReflectionCtrl.text) >= 300 ? Colors.green : AppColors.emergency,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Submit Assignment ✓',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
