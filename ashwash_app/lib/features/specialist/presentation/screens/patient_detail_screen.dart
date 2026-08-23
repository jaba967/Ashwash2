import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/providers/specialist_provider.dart';
import '../widgets/specialist_certificate_generator_dialog.dart';

class PatientDetailScreen extends StatefulWidget {
  final PatientRecordModel patient;
  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late TextEditingController _notesCtrl;
  bool _isSavingNotes = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.patient.doctorNotes);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _saveNotes() {
    setState(() => _isSavingNotes = true);
    final specProvider = Provider.of<SpecialistProvider>(context, listen: false);
    specProvider.updateDoctorNotes(widget.patient.id, _notesCtrl.text.trim());
    setState(() => _isSavingNotes = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Doctor Clinical Notes Saved Successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<AppLanguageProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.patient;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          p.name,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundImage: NetworkImage(p.avatarUrl),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(p.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.category,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Clinical Stats Grid
            Text(
              isBn ? 'মানসিক সূচক ও মূল্যায়ন' : 'Mental Metrics & Assessment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _buildInfoTile('Mood State', p.moodState, Icons.emoji_emotions_outlined, Colors.purple, isDark),
                _buildInfoTile('EPDS Scale Score', '${p.assessmentScore} / 30 (Low Risk)', Icons.assessment_outlined, Colors.blue, isDark),
                _buildInfoTile('Course Progress', '${p.courseProgress}% Completed', Icons.trending_up_rounded, AppColors.primary, isDark),
                _buildInfoTile('Quiz Average', '${p.quizScore}% Score', Icons.workspace_premium_outlined, Colors.orange, isDark),
              ],
            ),
            const SizedBox(height: 24),

            // Certificate Action Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.courseProgress >= 80 ? Colors.green.withOpacity(0.15) : Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.courseProgress >= 80 ? Colors.green : Colors.amber),
              ),
              child: Row(
                children: [
                  Icon(
                    p.courseProgress >= 80 ? Icons.verified_rounded : Icons.pending_actions_rounded,
                    color: p.courseProgress >= 80 ? Colors.green : Colors.amber,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.courseProgress >= 80 ? 'Eligible for Certificate' : 'Course in Progress (${p.courseProgress}%)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          p.courseProgress >= 80 ? 'Click to generate verifiable certificate document.' : 'Requires >= 80% completion to issue certificate.',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => SpecialistCertificateGeneratorDialog(patientName: p.name),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isBn ? 'ইস্যু করুন' : 'Issue', style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Doctor Notes & Observations Form
            Text(
              isBn ? 'ডাক্তারের নিজস্ব নোটস ও চিকিৎসা পরিকল্পনা' : 'Doctor Clinical Notes & Observations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write patient observation notes, coping strategies, or session homework instructions...',
                filled: true,
                fillColor: AppColors.glassSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSavingNotes ? null : _saveNotes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: Text(
                  isBn ? 'নোটস সংরক্ষণ করুন' : 'Save Clinical Notes',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.grey.shade800) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 10)),
        ],
      ),
    );
  }
}
