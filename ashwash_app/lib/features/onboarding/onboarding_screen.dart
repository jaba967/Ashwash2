import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_language_provider.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.menu_book_rounded,
      'iconBg': AppColors.primary,
      'titleEn': 'Guided Mental Health Courses',
      'titleBn': 'নির্দেশিত মানসিক স্বাস্থ্য কোর্স',
      'descEn': 'Structured learning paths with assignments and progress tracking',
      'descBn': 'অ্যাসাইনমেন্ট ও অগ্রগতি ট্র্যাকের সুবিধা সহ বিশেষ কোর্সসমূহ',
    },
    {
      'icon': Icons.groups_rounded,
      'iconBg': AppColors.success,
      'titleEn': 'Community Support',
      'titleBn': 'কমিউনিটি সহায়তা',
      'descEn': 'Connect with others, share experiences in a safe space',
      'descBn': 'নিরাপদ পরিবেশে নিজের অভিজ্ঞতা শেয়ার করুন ও অন্যদের সাথে যুক্ত থাকুন',
    },
    {
      'icon': Icons.medical_services_rounded,
      'iconBg': AppColors.categoryPink,
      'titleEn': 'Expert Consultation',
      'titleBn': 'বিশেষজ্ঞ পরামর্শ',
      'descEn': 'Access to local and international mental health professionals',
      'descBn': 'দেশি ও আন্তর্জাতিক মানসিক স্বাস্থ্য বিশেষজ্ঞদের সরাসরি পরামর্শ নিন',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<AppLanguageProvider>(context);
    final isBn = langProvider.isBangla;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar Language Switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => langProvider.setLanguage('en'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: !isBn ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'English',
                            style: TextStyle(
                              color: !isBn ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => langProvider.setLanguage('bn'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isBn ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'বাংলা',
                            style: TextStyle(
                              color: isBn ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: item['iconBg'],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'],
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          isBn ? item['titleBn'] : item['titleEn'],
                          textAlign: TextAlign.center,
                          style: AppTypography.heading1(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isBn ? item['descBn'] : item['descEn'],
                          textAlign: TextAlign.center,
                          style: AppTypography.body(context, fontSize: 15, color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),

            // Bottom Buttons: Skip & Next / Get Started
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      isBn ? 'এড়িয়ে যান' : 'Skip',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    ),
                    onPressed: () {
                      if (_currentIndex == _pages.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentIndex == _pages.length - 1
                              ? (isBn ? 'শুরু করুন' : 'Get Started')
                              : (isBn ? 'পরবর্তী' : 'Next'),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
