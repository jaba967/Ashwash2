import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/knowledge_hub_provider.dart';
import '../../../../core/providers/language_provider.dart';

class KnowledgeHubScreen extends StatelessWidget {
  const KnowledgeHubScreen({super.key});

  Future<void> _launchMediaUrl(BuildContext context, String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch URL: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hubProvider = Provider.of<KnowledgeHubProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filterTabs = [
      {'key': 'ALL', 'labelEn': 'All', 'labelBn': 'সব'},
      {'key': 'ARTICLE', 'labelEn': 'Articles & PDF Books', 'labelBn': 'নিবন্ধ ও PDF বই'},
      {'key': 'VIDEO', 'labelEn': 'Videos', 'labelBn': 'ভিডিও'},
      {'key': 'AUDIO', 'labelEn': 'Audio', 'labelBn': 'অডিও'},
    ];

    final resources = hubProvider.resources;

    return Scaffold(
      backgroundColor: AppColors.lightGrayishGreen, // #F0F8F0 Light Grayish Green Canvas
      appBar: AppBar(
        backgroundColor: AppColors.deepForestGreen, // #2E8B57 Deep Forest Green Header
        title: Text(isBn ? 'নলেজ হাব' : 'Knowledge Hub', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Banner Title Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.deepForestGreen, // #2E8B57 Deep Forest Green Card
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepForestGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn ? 'নলেজ হাব ও PDF লাইব্রেরি' : 'Knowledge Hub & PDF Library',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  isBn ? 'অডিও, ভিডিও ও বিষয়ভিত্তিক PDF বইসমূহ' : 'Audio, video & PDF psychological books',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.goldenrod, // #DAA520 Goldenrod Subtitle Accent
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Content Filter Pills (All, Articles & Books, Videos, Audio)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              children: filterTabs.map((tab) {
                final isSelected = hubProvider.selectedResourceFilter == tab['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      isBn ? tab['labelBn']! : tab['labelEn']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      hubProvider.setResourceFilter(tab['key']!);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Resources ListView
          Expanded(
            child: hubProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : resources.isEmpty
                    ? Center(
                        child: Text(
                          isBn ? 'কোন রিসোর্স পাওয়া যায়নি' : 'No resources found in this section',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: resources.length,
                        itemBuilder: (context, index) {
                          final item = resources[index];
                          final type = (item['content_type'] ?? 'ARTICLE').toString().toUpperCase();
                          final mediaUrl = item['media_url'] ?? '';
                          final bool isPdf = mediaUrl.toString().toLowerCase().endsWith('.pdf');
                          final bool isPremium = item['is_premium'] ?? false;
                          final String priceText = item['price'] ?? (isPremium ? r'৳50' : 'Free');

                          IconData iconData;
                          Color iconColor;

                          switch (type) {
                            case 'VIDEO':
                              iconData = Icons.videocam_rounded;
                              iconColor = const Color(0xFF0284C7);
                              break;
                            case 'AUDIO':
                              iconData = Icons.headphones_rounded;
                              iconColor = const Color(0xFF8B5CF6);
                              break;
                            default:
                              iconData = isPdf ? Icons.picture_as_pdf_rounded : Icons.article_rounded;
                              iconColor = isPdf ? const Color(0xFFDC2626) : AppColors.primary;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isPremium ? Colors.amber.shade300 : Colors.white,
                                width: isPremium ? 1.5 : 1,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: iconColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(iconData, color: iconColor, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isBn ? (item['title_bn'] ?? item['title']) : (item['title'] ?? ''),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              // Type Tag
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: iconColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  item['content_type_display'] ?? type,
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: iconColor),
                                                ),
                                              ),
                                              const SizedBox(width: 8),

                                              // Free vs Paid Pill Badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: isPremium ? Colors.amber.shade100 : Colors.green.shade100,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isPremium ? Colors.amber.shade400 : Colors.green.shade400,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isPremium ? Icons.lock_rounded : Icons.check_circle_rounded,
                                                      size: 11,
                                                      color: isPremium ? Colors.amber.shade900 : Colors.green.shade900,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      isPremium ? (isBn ? 'পেইড ($priceText)' : 'PAID ($priceText)') : (isBn ? 'ফ্রি' : 'FREE'),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: isPremium ? Colors.amber.shade900 : Colors.green.shade900,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item['description'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Action Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _handleResourceAction(context, item, isBn);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPremium ? Colors.amber.shade700 : AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    ),
                                    icon: Icon(
                                      isPremium
                                          ? Icons.lock_open_rounded
                                          : (type == 'VIDEO'
                                              ? Icons.play_arrow_rounded
                                              : (type == 'AUDIO'
                                                  ? Icons.headphones_rounded
                                                  : (isPdf ? Icons.picture_as_pdf_rounded : Icons.menu_book_rounded))),
                                      color: AppColors.glassSurface,
                                      size: 18,
                                    ),
                                    label: Text(
                                      isPremium
                                          ? (isBn ? 'আনলক করুন ($priceText)' : 'Pay & Unlock ($priceText)')
                                          : (type == 'VIDEO'
                                              ? (isBn ? 'ভিডিওটি প্লে করুন' : 'Play Video')
                                              : (type == 'AUDIO'
                                                  ? (isBn ? 'অডিওটি শুনুন' : 'Play Audio')
                                                  : (isPdf
                                                      ? (isBn ? 'PDF বইটি সরাসরি পড়ুন' : 'Open PDF Book')
                                                      : (isBn ? 'ডকুমেন্ট পড়ুন' : 'Read Document')))),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _handleResourceAction(BuildContext context, Map<String, dynamic> item, bool isBn) {
    final bool isPremium = item['is_premium'] ?? false;
    if (isPremium) {
      _showPaymentDialog(context, item, isBn);
    } else {
      _openResourceDetail(context, item, isBn);
    }
  }

  void _showPaymentDialog(BuildContext context, Map<String, dynamic> item, bool isBn) {
    final String priceText = item['price'] ?? r'৳50';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded, color: Colors.amber, size: 36),
            ),
            const SizedBox(height: 10),
            Text(
              isBn ? 'পেইড কন্টেন্ট আনলক' : 'Unlock Paid Resource',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBn ? (item['title_bn'] ?? item['title']) : item['title'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isBn ? 'মূল্য:' : 'Price:', style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    priceText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFD97706)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isBn ? 'মাত্র ৫০ টাকায় কন্টেন্টটি আনলক করে ব্যবহার করুন।' : 'Complete payment of ৳50 to access this premium resource.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'বাতিল' : 'Cancel', style: const TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<KnowledgeHubProvider>(context, listen: false).unlockResourceLocally(item['id']);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isBn ? 'পেমেন্ট সফল হয়েছে! কন্টেন্ট আনলকড।' : 'Payment Successful! Content Unlocked.'),
                  backgroundColor: Colors.green,
                ),
              );
              _openResourceDetail(context, item, isBn);
            },
            child: Text(isBn ? 'পেমেন্ট করুন (৳৫০)' : 'Pay & Access (৳50)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openResourceDetail(BuildContext context, Map<String, dynamic> item, bool isBn) {
    final type = (item['content_type'] ?? 'ARTICLE').toString().toUpperCase();
    final mediaUrl = item['media_url'] ?? '';
    final contentText = item['content_text'] ?? '';
    final bool hasWebLink = mediaUrl.toString().startsWith('http');
    final bool isPdf = mediaUrl.toString().toLowerCase().endsWith('.pdf');

    // If it is a direct PDF link, launch it directly or show sheet with direct launch button!
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (ctx, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(24.0),
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

                // Title
                Text(
                  isBn ? (item['title_bn'] ?? item['title']) : item['title'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Chip(
                      label: Text(item['content_type_display'] ?? type),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item['duration_display'] ?? '',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // MEDIA / DOCUMENT / PDF PLAYER CARD
                if (type == 'AUDIO') ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.headphones_rounded, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          isBn ? 'অডিও মেডিটেশন প্লেয়ার' : 'Audio Meditation Player',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isBn ? 'ক্লিক করে অডিও প্লে করুন' : 'Tap to play audio stream on your device',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFF6D28D9),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: () => _launchMediaUrl(context, mediaUrl),
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          label: Text(
                            isBn ? 'অডিও প্লে করুন (Play Audio)' : 'Play Audio Stream',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (type == 'VIDEO') ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 54),
                        const SizedBox(height: 12),
                        Text(
                          isBn ? 'এইচডি ভিডিও প্লেয়ার' : 'HD Video Stream Player',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isBn ? 'ক্লিক করে ভিডিওটি প্লে করুন' : 'Tap to watch video stream on your device',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFF0369A1),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: () => _launchMediaUrl(context, mediaUrl),
                          icon: const Icon(Icons.videocam_rounded, size: 24),
                          label: Text(
                            isBn ? 'ভিডিও প্লে করুন (Play Video)' : 'Play Video Stream',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (type == 'ARTICLE' && isPdf) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          isBn ? 'অফিশিয়াল PDF বই রিডার' : 'Official PDF Book Reader',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isBn ? 'সরাসরি PDF ফাইলটি ওপেন করতে নিচের বাটনে চাপ দিন' : 'Tap below to open full PDF document directly',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFF991B1B),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: () => _launchMediaUrl(context, mediaUrl),
                          icon: const Icon(Icons.open_in_new_rounded, size: 24),
                          label: Text(
                            isBn ? 'PDF বইটি ওপেন করুন (Open PDF)' : 'Open PDF File Direct',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (type == 'ARTICLE' && hasWebLink) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF047857)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.language_rounded, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          isBn ? 'WHO অফিশিয়াল ডাইরেক্ট ওয়েব পোর্টাল' : 'WHO Official Direct Web Portal',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isBn ? 'সরাসরি WHO ওয়েবসাইটে গাইডটি পড়তে নিচের বাটনে চাপ দিন' : 'Tap below to read official WHO guidelines directly on site',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFF047857),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: () => _launchMediaUrl(context, mediaUrl),
                          icon: const Icon(Icons.open_in_browser_rounded, size: 24),
                          label: Text(
                            isBn ? 'WHO ওয়েবসাইটে পড়ুন (Open WHO)' : 'Open WHO Web Direct',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const Text(
                  'Overview & Details:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  item['description'] ?? '',
                  style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white),
                ),

                if (contentText.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.menu_book_rounded, color: Colors.black, size: 20),
                            SizedBox(width: 8),
                            Text('Book Chapters & Core Content:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const Divider(height: 20),
                        SelectableText(
                          contentText,
                          style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(isBn ? 'বন্ধ করুন' : 'Close Resource', style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }
}
