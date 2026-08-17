import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_service.dart';
import '../../../../data/models/course_model.dart';

class CourseCertificateScreen extends StatefulWidget {
  final CourseModel course;

  const CourseCertificateScreen({
    Key? key,
    required this.course,
  }) : super(key: key);

  @override
  State<CourseCertificateScreen> createState() => _CourseCertificateScreenState();
}

class _CourseCertificateScreenState extends State<CourseCertificateScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _certData;

  @override
  void initState() {
    super.initState();
    _fetchCertificate();
  }

  Future<void> _fetchCertificate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String courseIdStr = widget.course.id.toString().replaceAll(RegExp(r'[^0-9]'), '');
      final res = await ApiService.get(
        '${ApiEndpoints.courses}$courseIdStr/certificate/',
        requireAuth: true,
      );

      if (res is Map<String, dynamic>) {
        setState(() {
          _certData = res;
          _isLoading = false;
        });
      } else {
        throw Exception('Invalid certificate data format');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAndDownloadPdf() async {
    if (_certData == null) return;

    final certId = _certData!['certificate_id'] ?? 'ASH-CERT-OFFICIAL';
    final patientName = _certData!['patient_name'] ?? 'Valued Patient';
    final courseTitle = _certData!['course_title_en'] ?? widget.course.titleEn;
    final specName = _certData!['specialist_name'] ?? 'Dr. Sarah Rahman';
    final specTitle = _certData!['specialist_title'] ?? 'Senior Clinical Psychologist';
    final specClinic = _certData!['specialist_clinic'] ?? 'Ashwash Mental Wellness Center';
    final recommendation = _certData!['specialist_recommendation'] ?? '';
    final isRecSubmitted = _certData!['recommendation_status'] == 'submitted';
    final issuedAt = _certData!['issued_at'] != null 
        ? DateTime.tryParse(_certData!['issued_at'])?.toLocal().toString().split(' ')[0] ?? 'Today'
        : 'Today';

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.purple900, width: 8),
              borderRadius: pw.BorderRadius.circular(16),
              color: PdfColors.white,
            ),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.amber800, width: 2),
                borderRadius: pw.BorderRadius.circular(12),
                color: PdfColors.white,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Top Gold Medal Seal & Header Banner
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.amber700,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Text(
                          ' A ',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'ASHWASH MENTAL WELLNESS PLATFORM',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.5,
                          color: PdfColors.purple900,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'OFFICIAL CERTIFICATE OF COURSE COMPLETION',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1,
                      color: PdfColors.amber900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColors.amber600, thickness: 1.5),
                  pw.SizedBox(height: 10),

                  pw.Text(
                    'THIS CERTIFICATE IS PROUDLY PRESENTED TO',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700, letterSpacing: 1),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    patientName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.purple900,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'FOR SUCCESSFUL AND DEDICATED COMPLETION OF THE',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800, letterSpacing: 0.5),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    courseTitle.toUpperCase(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // Evaluation Box
                  if (isRecSubmitted && recommendation.isNotEmpty)
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.amber50,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: PdfColors.amber400, width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'SPECIALIST PERFORMANCE EVALUATION & RECOMMENDATION',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.purple900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '"$recommendation"',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey900),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'GRADE: ${(_certData!['performance_ranking'] ?? 'OUTSTANDING').toUpperCase()}',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                          ),
                        ],
                      ),
                    ),

                  pw.Spacer(),

                  // Footer Row: Left Meta, Center Stamp, Right Cursive Doctor Signature
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Left Meta
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'CERTIFICATE ID: $certId',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'DATE ISSUED: $issuedAt',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                          ),
                        ],
                      ),

                      // Center Stamp Box
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.purple900, width: 1.5),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'ASHWASH PLATFORM',
                              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900),
                            ),
                            pw.Text(
                              'OFFICIALLY APPROVED',
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.amber800),
                            ),
                          ],
                        ),
                      ),

                      // Right Doctor Cursive Signature
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          // Handwritten Cursive Signature text above line
                          pw.Text(
                            specName,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontStyle: pw.FontStyle.italic,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.purple900,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Container(
                            width: 150,
                            child: pw.Divider(color: PdfColors.grey900, thickness: 1.2),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'DR. ${specName.toUpperCase()}',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                          ),
                          pw.Text(
                            '$specTitle | $specClinic',
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: '${certId}_${patientName.replaceAll(' ', '_')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Completion Certificate'),
        actions: [
          if (_certData != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share / Download Certificate PDF',
              onPressed: _generateAndDownloadPdf,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading official course certificate...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 64, color: AppColors.emergency),
                        const SizedBox(height: 16),
                        Text(
                          'Certificate Locked',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back to Course Details'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Certificate Card Wrapper
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Colors.amber, width: 2),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.surface,
                                theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Top Gold Badge Icon
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 48,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Header Text
                              Text(
                                'ASHWASH MENTAL WELLNESS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Certificate of Completion',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Divider(indent: 40, endIndent: 40),
                              const SizedBox(height: 12),

                              const Text(
                                'This official certificate is proudly presented to',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _certData!['patient_name'] ?? 'Valued Patient',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),

                              Text(
                                'for successfully completing 100% of all lessons, recovery tasks, and assignments in the course:',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _certData!['course_title_en'] ?? widget.course.titleEn,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Specialist Recommendation Section
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _certData!['recommendation_status'] == 'submitted'
                                      ? Colors.green.withOpacity(0.08)
                                      : Colors.amber.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _certData!['recommendation_status'] == 'submitted'
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.amber.withOpacity(0.4),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _certData!['recommendation_status'] == 'submitted'
                                              ? Icons.recommend_rounded
                                              : Icons.pending_actions_rounded,
                                          color: _certData!['recommendation_status'] == 'submitted'
                                              ? Colors.green
                                              : Colors.amber.shade800,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Specialist Recommendation & Evaluation',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: _certData!['recommendation_status'] == 'submitted'
                                                  ? Colors.green.shade700
                                                  : Colors.amber.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (_certData!['recommendation_status'] == 'submitted' &&
                                        (_certData!['specialist_recommendation'] ?? '').isNotEmpty) ...[
                                      Text(
                                        _certData!['specialist_recommendation'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Grade: ${_certData!['performance_ranking'] ?? 'Outstanding'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ] else ...[
                                      const Text(
                                        '⏳ Your specialist has been notified to submit your personalized performance recommendation. Check back shortly!',
                                        style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Instructor & Certificate Meta Footer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Certificate ID', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text(
                                        _certData!['certificate_id'] ?? 'ASH-CERT-000',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('Date Issued', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text(
                                        _certData!['issued_at'] != null 
                                            ? DateTime.tryParse(_certData!['issued_at'])?.toLocal().toString().split(' ')[0] ?? 'Today'
                                            : 'Today',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Cursive Handwritten Specialist Signature
                                      Text(
                                        _certData!['specialist_name'] ?? 'Dr. Jaba Acharjee',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Container(
                                        width: 140,
                                        height: 1,
                                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                      ),
                                      Text(
                                        'DR. ${(_certData!['specialist_name'] ?? 'JABA ACHARJEE').toUpperCase()}',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                      ),
                                      Text(
                                        '${_certData!['specialist_title'] ?? 'Clinical Psychologist'}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Download PDF Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _generateAndDownloadPdf,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text(
                            'Download Certificate as PDF',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}
