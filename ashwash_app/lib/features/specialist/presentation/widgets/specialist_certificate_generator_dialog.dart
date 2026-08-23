import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SpecialistCertificateGeneratorDialog extends StatefulWidget {
  final String? patientName;
  final String? courseTitle;

  const SpecialistCertificateGeneratorDialog({
    super.key,
    this.patientName,
    this.courseTitle,
  });

  @override
  State<SpecialistCertificateGeneratorDialog> createState() => _SpecialistCertificateGeneratorDialogState();
}

class _SpecialistCertificateGeneratorDialogState extends State<SpecialistCertificateGeneratorDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _courseCtrl;
  bool _isGenerating = false;
  bool _certificateGenerated = false;

  final String _certId = 'ASH-CERT-2026-98214';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.patientName ?? 'Nusrat Sultana');
    _courseCtrl = TextEditingController(text: widget.courseTitle ?? 'Postpartum Depression Recovery Program');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _courseCtrl.dispose();
    super.dispose();
  }

  void _generateCertificate() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _certificateGenerated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      contentPadding: const EdgeInsets.all(24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_membership_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Automated Certificate Generator',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (!_certificateGenerated) ...[
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Patient Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _courseCtrl,
                decoration: InputDecoration(
                  labelText: 'Course Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Computed metrics breakdown
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: const [
                    _MetricRow(label: 'Course Completion', val: '100%'),
                    _MetricRow(label: 'Quiz Score Average', val: '92%'),
                    _MetricRow(label: 'Homework Assignments', val: 'Approved (8/8)'),
                    _MetricRow(label: 'Overall Grade', val: 'A+ (Excellence)'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateCertificate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isGenerating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Auto-Calculate & Generate Certificate',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ] else ...[
              // Generated Certificate Preview Document Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade400, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 12),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'CERTIFICATE OF COMPLETION',
                      style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Color(0xFF78350F), fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text('Ashwash Mental Health & Emotional Wellness Platform', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 14),
                    const Text('This is proudly presented to:', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 4),
                    Text(
                      _nameCtrl.text,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'for successfully completing the official therapeutic course:\n"${_courseCtrl.text}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Date: Aug 1, 2026', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text('Instructor: Dr. Mekhala Sarkar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        // Simulated QR Code Box
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.glassSurface,
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.qr_code_2_rounded, size: 36, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('ID: $_certId', style: const TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Certificate Issued & Sent to Patient ($_certId)')),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      label: const Text('Certificate Issued & Sent', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String val;
  const _MetricRow({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }
}
