import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/network/api_service.dart';
import '../../core/network/api_endpoints.dart';
import 'my_enrolled_courses_screen.dart';
import 'my_patient_sessions_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _fetchRealtimeReportData();
  }

  Future<void> _fetchRealtimeReportData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get(ApiEndpoints.patientHealthReport, requireAuth: true);
      if (res is Map<String, dynamic> && mounted) {
        setState(() {
          _reportData = res;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Report fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadPdfReport(bool isBn) async {
    if (_reportData == null) {
      await _fetchRealtimeReportData();
      if (_reportData == null) return;
    }
    setState(() => _isGeneratingPdf = true);

    try {
      final doc = pw.Document();
      final header = _reportData!['report_header'] ?? {};
      final courseSum = _reportData!['course_summary'] ?? {};
      final lessonSum = _reportData!['lesson_homework_progress'] ?? {};
      final sessions = List<Map<String, dynamic>>.from(_reportData!['specialist_sessions'] ?? []);
      final performances = List<Map<String, dynamic>>.from(_reportData!['course_performance'] ?? []);
      final feedbacks = List<Map<String, dynamic>>.from(_reportData!['homework_feedback'] ?? []);
      final overall = _reportData!['overall_performance'] ?? {};

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.purple900,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ASHWASH MENTAL WELLNESS PLATFORM',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.amber300, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'PATIENT CLINICAL HEALTH REPORT',
                      style: pw.TextStyle(fontSize: 18, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Patient Header Info
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.purple200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Patient Name: ${header['patient_name'] ?? 'Patient'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text('Patient ID: ${header['patient_id'] ?? '#ASH-PAT-001'}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Generated: ${header['generated_at'] ?? 'Today'}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                        pw.Text('Overall Progress: ${courseSum['overall_course_progress'] ?? 0}%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.purple900)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Section 1: Course Summary
              pw.Text('1. COURSE SUMMARY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.purple900)),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.purple50, borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text('Total Enrolled: ${courseSum['total_enrolled'] ?? 0}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Completed: ${courseSum['completed_courses'] ?? 0}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    pw.Text('Ongoing: ${courseSum['ongoing_courses'] ?? 0}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                    pw.Text('Overall Progress: ${courseSum['overall_course_progress'] ?? 0}%', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Section 2: Lesson & Homework Progress
              pw.Text('2. LESSON & HOMEWORK PROGRESS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.purple900)),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text('Total Lessons: ${lessonSum['total_lessons'] ?? 0}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Completed: ${lessonSum['completed_lessons'] ?? 0}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    pw.Text('Remaining: ${lessonSum['remaining_lessons'] ?? 0}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Homework Submitted: ${lessonSum['homework_submitted'] ?? 0}/${lessonSum['homework_assigned'] ?? 0}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Reviewed: ${lessonSum['homework_reviewed'] ?? 0}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Section 3: Specialist Session History Table
              pw.Text('3. SPECIALIST & CONSULTATION SESSION HISTORY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.purple900)),
              pw.SizedBox(height: 6),
              if (sessions.isEmpty)
                pw.Text('No specialist sessions attended yet.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))
              else
                pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.purple900),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  headers: ['Specialist Name', 'Specialization', 'Sessions', 'Last Session', 'Care Status'],
                  data: sessions.map((s) => [
                    s['specialist_name'] ?? 'Specialist',
                    s['specialization'] ?? 'Clinical Specialist',
                    '${s['sessions_count'] ?? 0}',
                    s['last_session_date'] ?? 'N/A',
                    s['status'] ?? 'Active',
                  ]).toList(),
                ),
              pw.SizedBox(height: 14),

              // Section 4: Course Performance Table
              pw.Text('4. INDIVIDUAL COURSE PERFORMANCE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.purple900)),
              pw.SizedBox(height: 6),
              if (performances.isEmpty)
                pw.Text('No courses enrolled yet.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))
              else
                pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.purple800),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  headers: ['Course Title', 'Instructor', 'Progress %', 'Lessons Done', 'Homework', 'Status', 'Certificate'],
                  data: performances.map((p) => [
                    p['course_name'] ?? 'Course',
                    p['instructor'] ?? 'Instructor',
                    '${p['progress_percentage'] ?? 0}%',
                    p['completed_lessons'] ?? '0/0',
                    p['homework_completed'] ?? '0',
                    p['final_status'] ?? 'Ongoing',
                    p['certificate_status'] ?? 'Locked',
                  ]).toList(),
                ),
              pw.SizedBox(height: 14),

              // Section 5: Homework Feedback
              pw.Text('5. SPECIALIST FEEDBACK & EVALUATION NOTES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.purple900)),
              pw.SizedBox(height: 6),
              if (feedbacks.isEmpty)
                pw.Text('No specialist feedback notes recorded yet.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))
              else
                ...feedbacks.map((f) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(4), border: pw.Border.all(color: PdfColors.grey300)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${f['lesson_title']} (${f['submitted_at']}) - Specialist: ${f['specialist_name']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.purple900)),
                      pw.SizedBox(height: 2),
                      pw.Text('"${f['feedback']}"', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                )).toList(),
              pw.SizedBox(height: 14),

              // Section 6: Overall Summary
              pw.Text('6. OVERALL WELLNESS PERFORMANCE METRICS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.purple900)),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.amber50, borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: PdfColors.amber300)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text('Course Completion: ${overall['course_completion_pct'] ?? 0}%', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Lesson Progress: ${overall['lesson_completion_pct'] ?? 0}%', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Homework Progress: ${overall['homework_completion_pct'] ?? 0}%', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Total Sessions: ${overall['specialist_sessions'] ?? 0}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'Ashwash_Clinical_Health_Report_${header['patient_id'] ?? 'PAT'}.pdf',
      );
    } catch (e) {
      debugPrint('PDF print error: $e');
    }

    if (mounted) setState(() => _isGeneratingPdf = false);
  }

  void _viewFullReportModal(BuildContext context, bool isBn) async {
    if (_reportData == null) {
      await _fetchRealtimeReportData();
      if (_reportData == null) return;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final header = _reportData!['report_header'] ?? {};
    final courseSum = _reportData!['course_summary'] ?? {};
    final lessonSum = _reportData!['lesson_homework_progress'] ?? {};
    final sessions = List<Map<String, dynamic>>.from(_reportData!['specialist_sessions'] ?? []);
    final performances = List<Map<String, dynamic>>.from(_reportData!['course_performance'] ?? []);
    final feedbacks = List<Map<String, dynamic>>.from(_reportData!['homework_feedback'] ?? []);
    final overall = _reportData!['overall_performance'] ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isBn ? 'ক্লিনিক্যাল স্বাস্থ্য রিপোর্ট' : 'Clinical Health Report',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Patient: ${header['patient_name'] ?? 'Patient'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${header['patient_id'] ?? '#ASH-PAT-001'} • ${header['generated_at'] ?? 'Today'}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 1: Course Summary
                    _buildSectionHeader('1. Course Summary', isDark),
                    _buildMetricCard(
                      'Enrolled: ${courseSum['total_enrolled'] ?? 0} | Completed: ${courseSum['completed_courses'] ?? 0} | Ongoing: ${courseSum['ongoing_courses'] ?? 0}',
                      'Overall Course Progress: ${courseSum['overall_course_progress'] ?? 0}%',
                      AppColors.primary,
                      isDark,
                    ),

                    // Section 2: Lesson Progress
                    _buildSectionHeader('2. Lesson & Homework Progress', isDark),
                    _buildMetricCard(
                      'Lessons Done: ${lessonSum['completed_lessons'] ?? 0}/${lessonSum['total_lessons'] ?? 0}',
                      'Homework Submitted: ${lessonSum['homework_submitted'] ?? 0} | Reviewed: ${lessonSum['homework_reviewed'] ?? 0}',
                      Colors.green,
                      isDark,
                    ),

                    // Section 3: Specialist Sessions
                    _buildSectionHeader('3. Specialist Session History', isDark),
                    if (sessions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('No specialist sessions attended yet.', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
                      )
                    else
                      ...sessions.map((s) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['specialist_name'] ?? 'Specialist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                                Text(s['specialization'] ?? 'Specialist Doctor', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${s['sessions_count'] ?? 0} Sessions', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                                Text(s['last_session_date'] ?? 'N/A', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      )).toList(),

                    // Section 4: Course Performance
                    _buildSectionHeader('4. Course Performance', isDark),
                    if (performances.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('No courses enrolled yet.', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
                      )
                    else
                      ...performances.map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p['course_name'] ?? 'Course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                                  Text('Instructor: ${p['instructor']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                              child: Text('${p['progress_percentage']}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      )).toList(),

                    // Section 5: Homework Feedback
                    _buildSectionHeader('5. Homework & Specialist Feedback', isDark),
                    if (feedbacks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('No specialist feedback notes recorded yet.', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
                      )
                    else
                      ...feedbacks.map((f) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${f['lesson_title']} • ${f['submitted_at']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                            const SizedBox(height: 4),
                            Text('Feedback: "${f['feedback']}"', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
                            const SizedBox(height: 2),
                            Text('- ${f['specialist_name']}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )).toList(),

                    // Section 6: Overall Summary
                    _buildSectionHeader('6. Overall Performance Summary', isDark),
                    _buildMetricCard(
                      'Course Completion: ${overall['course_completion_pct'] ?? 0}% | Lesson Progress: ${overall['lesson_completion_pct'] ?? 0}%',
                      'Homework Progress: ${overall['homework_completion_pct'] ?? 0}% | Total Sessions: ${overall['specialist_sessions'] ?? 0}',
                      Colors.amber.shade800,
                      isDark,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String line1, String line2, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(line1, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          const SizedBox(height: 2),
          Text(line2, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final courseSum = _reportData?['course_summary'] ?? {};
    final overall = _reportData?['overall_performance'] ?? {};
    final timeline = List<Map<String, dynamic>>.from(_reportData?['treatment_timeline'] ?? []);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isBn ? 'মানসিক স্বাস্থ্য রিপোর্ট' : 'Mental Health Report',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRealtimeReportData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            isBn ? 'আপনার ক্লিনিক্যাল স্বাস্থ্য রিপোর্ট' : 'Clinical Health Record',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isBn ? 'কোর্স প্রোগ্রেস ও সেশন তথ্য থেকে তৈরি' : 'Realtime Clinical Performance & Progress Report',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: _isGeneratingPdf ? null : () => _downloadPdfReport(isBn),
                                  icon: _isGeneratingPdf
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.download_rounded, size: 20),
                                  label: Text(
                                    isBn ? 'ডাউনলোড' : 'Download PDF',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white, width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => _viewFullReportModal(context, isBn),
                                  icon: const Icon(Icons.visibility_rounded, color: Colors.white, size: 20),
                                  label: Text(
                                    isBn ? 'রিপোর্ট দেখুন' : 'View Report',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Overview Section (3 REALTIME CLICKABLE TILES)
                    Text(
                      isBn ? 'সংক্ষিপ্ত সারমর্ম' : 'Overview',
                      style: AppTypography.heading2(context),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOverviewTile(
                            '${courseSum['total_enrolled'] ?? 0}',
                            isBn ? 'কোর্সে এনরোলড' : 'Courses Enrolled',
                            Icons.menu_book_rounded,
                            isDark,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyEnrolledCoursesScreen()));
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildOverviewTile(
                            '${overall['specialist_sessions'] ?? 0}',
                            isBn ? 'সেশনে অংশগ্রহণ' : 'Sessions Attended',
                            Icons.calendar_today_rounded,
                            isDark,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPatientSessionsScreen()));
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildOverviewTile(
                            '${courseSum['overall_course_progress'] ?? 0}%',
                            isBn ? 'সার্বিক অগ্রগতি' : 'Overall Progress',
                            Icons.military_tech_rounded,
                            isDark,
                            onTap: () {
                              _viewFullReportModal(context, isBn);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Treatment Timeline (REAL DATABASE DATA ONLY)
                    Text(
                      isBn ? 'চিকিৎসার টাইমলাইন' : 'Treatment Timeline',
                      style: AppTypography.heading2(context),
                    ),
                    const SizedBox(height: 12),
                    if (timeline.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          isBn ? 'এখনো কোনো টাইমলাইন কার্যকলাপ নেই।' : 'No treatment timeline activities recorded yet.',
                          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
                        ),
                      ),
                    ] else ...[
                      ...timeline.map((t) => _buildTimelineItem(t['date'] ?? 'Recent', t['title'] ?? 'Activity Completed', isDark)).toList(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewTile(String count, String label, IconData icon, bool isDark, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: Colors.grey.shade800) : Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String date, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
