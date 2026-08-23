import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/services/api_service.dart';
import '../../data/models/category_model.dart';
import '../navigation/presentation/screens/main_navigation_screen.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({Key? key}) : super(key: key);

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  CategoryModel? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;
    final apiService = ApiService();
    final categories = apiService.getMockCategories();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedCategory == null
              ? (isBn ? 'আপনার বিভাগ নির্বাচন করুন' : 'Select Your Category')
              : (isBn ? _selectedCategory!.titleBn : _selectedCategory!.titleEn),
        ),
        leading: _selectedCategory != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => setState(() => _selectedCategory = null),
              )
            : null,
      ),
      body: _selectedCategory == null
          ? _buildCategoryList(categories, isBn)
          : _buildCategoryDetail(_selectedCategory!, isBn),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories, bool isBn) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          isBn ? 'আপনার বিভাগ নির্বাচন করুন' : 'Select Your Category',
          style: AppTypography.heading1(context),
        ),
        const SizedBox(height: 6),
        Text(
          isBn
              ? 'ব্যক্তিগতকৃত কোর্স এবং সহায়তা পেতে আপনার বিভাগ বেছে নিন'
              : 'Choose your category to get personalized courses and support',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 24),
        ...categories.map((cat) => _buildCategoryCard(cat, isBn)).toList(),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            );
          },
          child: Text(
            isBn ? 'এখনই নয় (Skip for now)' : 'Skip for now',
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(CategoryModel cat, bool isBn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cat.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cat.color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 26),
        ),
        title: Text(
          isBn ? cat.titleBn : cat.titleEn,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            isBn ? cat.descriptionBn : cat.descriptionEn,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        onTap: () {
          setState(() {
            _selectedCategory = cat;
          });
        },
      ),
    );
  }

  Widget _buildCategoryDetail(CategoryModel cat, bool isBn) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cat.color,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn ? cat.titleBn : cat.titleEn,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isBn ? cat.descriptionBn : cat.descriptionEn,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: cat.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                    );
                  },
                  child: Text(
                    isBn ? 'এই বিভাগটি বাছাই করুন' : 'Select This Category',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Available Courses Section
          Text(isBn ? 'উপলব্ধ কোর্সসমূহ' : 'Available Courses', style: AppTypography.heading2(context)),
          const SizedBox(height: 12),
          Container(
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
                    color: cat.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.menu_book_rounded, size: 50, color: cat.color),
                ),
                const SizedBox(height: 12),
                Text('New Mother Wellness Program', style: AppTypography.heading3(context)),
                const SizedBox(height: 4),
                const Text('Comprehensive support covering postpartum care & bonding.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text('8 weeks', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.task_alt, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text('12 tasks', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    const Text('Free', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Our Specialists
          Text(isBn ? 'আমাদের বিশেষজ্ঞগণ' : 'Our Specialists', style: AppTypography.heading2(context)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: const Text('D', style: TextStyle(fontSize: 22, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Dr. Ayesha Rahman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Clinical Psychologist', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      SizedBox(height: 4),
                      Text('⭐ 4.9 • 12 years exp', style: TextStyle(fontSize: 12, color: AppColors.warning)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                    );
                  },
                  child: Text(isBn ? 'বুকিং' : 'Book Session', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
