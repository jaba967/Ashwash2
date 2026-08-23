import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/providers/specialist_provider.dart';

class SpecialistHomeworkReviewScreen extends StatelessWidget {
  const SpecialistHomeworkReviewScreen({super.key});

  void _showReviewModal(BuildContext context, HomeworkSubmissionModel item, bool isBn, bool isDark) {
    final feedbackCtrl = TextEditingController(text: item.feedback ?? '');
    int selectedGrade = item.grade ?? 90;
    String reviewStatus = 'approved';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isBn ? 'হোমওয়ার্ক মূল্যায়ন ও ফিডব্যাক' : 'Homework Evaluation & Feedback',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Submission content box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.patientName} • ${item.assignmentTitle}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.submissionText,
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grade Slider
                  Text(
                    isBn ? 'প্রাপ্ত নম্বর: $selectedGrade / ১০০' : 'Score: $selectedGrade / 100',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Slider(
                    value: selectedGrade.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: AppColors.primary,
                    label: '$selectedGrade',
                    onChanged: (val) {
                      setModalState(() => selectedGrade = val.toInt());
                    },
                  ),
                  const SizedBox(height: 12),

                  // Status choice
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text(isBn ? 'অনুমোদিত' : 'Approve'),
                        selected: reviewStatus == 'approved',
                        selectedColor: Colors.green,
                        onSelected: (_) => setModalState(() => reviewStatus = 'approved'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(isBn ? 'পুনরায় দিন' : 'Request Resubmission'),
                        selected: reviewStatus == 'resubmit',
                        selectedColor: Colors.orange,
                        onSelected: (_) => setModalState(() => reviewStatus = 'resubmit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Doctor Feedback Text Area
                  TextField(
                    controller: feedbackCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Write feedback for patient (e.g. Excellent reflection on self-care habits!)...',
                      filled: true,
                      fillColor: AppColors.glassSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: isDark ? Colors.white : Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final specProvider = Provider.of<SpecialistProvider>(context, listen: false);
                        specProvider.reviewHomework(
                          item.id,
                          status: reviewStatus,
                          grade: selectedGrade,
                          feedback: feedbackCtrl.text.trim(),
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Homework Reviewed & Patient Notified!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        isBn ? 'জমা জমা পর্যালোচনা শেষ করুন' : 'Submit Review & Notify Patient',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<AppLanguageProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final specProvider = Provider.of<SpecialistProvider>(context);
    final hwList = specProvider.pendingHomeworkSubmissions;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isBn ? 'পেন্ডিং হোমওয়ার্ক পর্যালোচনা' : 'Pending Homework Reviews',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: hwList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.success),
                  const SizedBox(height: 12),
                  Text(
                    isBn ? 'সকল হোমওয়ার্ক মূল্যায়ন সম্পন্ন হয়েছে!' : 'All homework submissions evaluated!',
                    style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.white),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: hwList.length,
              itemBuilder: (context, index) {
                final item = hwList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white : Colors.white),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: NetworkImage(item.patientAvatar),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.patientName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  'Submitted: ${item.submittedAt}',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.assignmentTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.submissionText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showReviewModal(context, item, isBn, isDark),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.rate_review_rounded, color: Colors.white, size: 18),
                          label: Text(
                            isBn ? 'রিভিউ করুন ও মার্কস দিন' : 'Review & Grade Submission',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
