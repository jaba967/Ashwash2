import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/services/api_service.dart';
import '../../data/models/course_model.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'কোর্সসমূহ' : 'Course Plans', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (context, snapshot) {
          List<CourseModel> courseList = [];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            courseList = snapshot.data!.docs.map<CourseModel>((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return CourseModel(
                id: doc.id.hashCode,
                titleEn: data['titleEn'] ?? 'Mental Health & Wellness',
                titleBn: data['titleBn'] ?? 'মানসিক স্বাস্থ্য ও সুস্থতা',
                descriptionEn: data['descriptionEn'] ?? 'Comprehensive course for daily mental resilience.',
                descriptionBn: data['descriptionBn'] ?? 'দৈনন্দিন মানসিক শক্তি অর্জনের জন্য পূর্ণাঙ্গ কোর্স।',
                duration: '${data['durationWeeks'] ?? 6} Weeks',
                price: (data['price'] ?? 0.0).toDouble(),
                isFree: data['isFree'] ?? true,
                rating: (data['rating'] ?? 4.9).toDouble(),
              );
            }).toList();
          } else {
            courseList = ApiService().getMockCourses();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: courseList.length,
            itemBuilder: (context, index) {
              final c = courseList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.school_rounded, size: 50, color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(isBn ? c.titleBn : c.titleEn, style: AppTypography.heading3(context)),
                    const SizedBox(height: 4),
                    Text(isBn ? c.descriptionBn : c.descriptionEn, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${c.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 12),
                        Text('${c.durationWeeks} weeks', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(course: c)));
                          },
                          child: Text(isBn ? 'কোর্স শুরু করুন' : 'Open Course', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
