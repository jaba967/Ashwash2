import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/language_provider.dart';

class QuickActionsGrid extends StatelessWidget {
  final Function(String route) onActionTap;

  const QuickActionsGrid({super.key, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBn = langProvider.isBangla;

    final List<Map<String, dynamic>> actions = [
      {
        'id': 'knowledge_hub',
        'title': isBn ? 'নলেজ হাব' : 'Knowledge Hub',
        'imageAsset': 'assets/images/knowledge_hub_icon.jpg',
        'bgColor': AppColors.deepForestGreen, // #2E8B57
        'textColor': Colors.white,
      },
      {
        'id': 'mind_game',
        'title': isBn ? 'মাইন্ড গেম' : 'Mind Game',
        'imageAsset': 'assets/images/mind_games_icon.jpg',
        'bgColor': AppColors.sageGreen, // #8FBC8F
        'textColor': AppColors.charcoalGray,
      },
      {
        'id': 'browse_courses',
        'title': isBn ? 'কোর্স ব্রাউজ' : 'Browse Courses',
        'imageAsset': 'assets/images/courses_browse_icon.jpg',
        'bgColor': AppColors.goldenrod, // #DAA520
        'textColor': Colors.white,
      },
      {
        'id': 'book_session',
        'title': isBn ? 'সেশন বুকিং' : 'Book Session',
        'imageAsset': 'assets/images/specialist_consult_icon.jpg',
        'bgColor': AppColors.deepForestGreen, // #2E8B57
        'textColor': Colors.white,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isBn ? 'দ্রুত সেবা' : 'Quick Actions',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return Container(
              decoration: BoxDecoration(
                color: action['bgColor'],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (action['bgColor'] as Color).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onActionTap(action['id']),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              action['imageAsset'],
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            action['title'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: action['textColor'],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
