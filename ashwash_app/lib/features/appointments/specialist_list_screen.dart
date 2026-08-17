import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/network/api_service.dart' as app_api;
import '../../core/providers/specialist_provider.dart';
import '../../core/services/api_service.dart' as mock_api;
import '../../data/models/specialist_model.dart';
import 'booking_screen.dart';

class SpecialistListScreen extends StatefulWidget {
  const SpecialistListScreen({Key? key}) : super(key: key);

  @override
  State<SpecialistListScreen> createState() => _SpecialistListScreenState();
}

class _SpecialistListScreenState extends State<SpecialistListScreen> {
  String _selectedTab = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  List<SpecialistModel> _fetchedLiveSpecialists = [];
  bool _isLoadingLive = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveSpecialists();
  }

  Future<void> _fetchLiveSpecialists() async {
    try {
      final List<dynamic> list = await app_api.ApiService.getList('dashboard/admin-specialists/');
      if (list.isNotEmpty) {
        final List<SpecialistModel> parsed = [];
        for (var item in list) {
          if (item is Map) {
            final id = item['id'] is int ? item['id'] : int.tryParse(item['id'].toString()) ?? 999;
            final fullName = item['full_name']?.toString().trim() ?? item['name']?.toString().trim();
            final username = item['user_username']?.toString().trim();
            final name = (fullName != null && fullName.isNotEmpty)
                ? fullName
                : ((username != null && username.isNotEmpty) ? 'Dr. $username' : 'Specialist Doctor');
            final spec = item['specialization']?.toString() ?? 'Counseling Specialist';
            final qual = item['qualification']?.toString() ?? 'MSc in Clinical Psychology';
            final fee = item['consultation_fee_bdt'] is int
                ? item['consultation_fee_bdt']
                : (int.tryParse(item['consultation_fee_bdt']?.toString() ?? '') ?? 1500);
            final img = item['profile_picture']?.toString() ?? item['image_url']?.toString() ?? '';

            parsed.add(
              SpecialistModel(
                id: id,
                name: name,
                degree: qual,
                specialization: spec,
                workingPlace: item['hospital_clinic']?.toString() ?? 'Ashwash Mental Wellness Center',
                imageUrl: img.isNotEmpty ? img : '',
                titleEn: spec,
                titleBn: 'ক্যাউন্সেলিং বিশেষজ্ঞ',
                bioEn: 'Registered Counseling & Clinical Specialist at Ashwash Platform.',
                bioBn: 'আশবাস মানসিক স্বাস্থ্য প্ল্যাটফর্মের নিবন্ধিত বিশেষজ্ঞ কাউন্সিলর।',
                experienceYears: item['experience_years'] is int ? item['experience_years'] : 8,
                rating: 4.9,
                feeBdt: fee,
                locationType: 'Dhaka',
                isAvailable: true,
                isOnline: true,
              ),
            );
          }
        }

        if (parsed.isNotEmpty && mounted) {
          setState(() {
            _fetchedLiveSpecialists = parsed;
            _isLoadingLive = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingLive = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final specProvider = Provider.of<SpecialistProvider>(context);

    final List<SpecialistModel> allSpecialists = [];

    if (_fetchedLiveSpecialists.isNotEmpty) {
      allSpecialists.addAll(_fetchedLiveSpecialists);
    } else {
      allSpecialists.addAll(mock_api.ApiService().getMockSpecialists());
    }

    final regSpec = specProvider.profile;
    if (regSpec.fullName.isNotEmpty) {
      final exists = allSpecialists.any((s) => s.name.toLowerCase().contains(regSpec.fullName.toLowerCase()));
      if (!exists) {
        allSpecialists.insert(
          0,
          SpecialistModel(
            id: 999,
            name: regSpec.fullName,
            degree: regSpec.qualification,
            specialization: regSpec.specialization,
            workingPlace: regSpec.hospitalClinic,
            imageUrl: regSpec.avatarUrl ?? '',
            titleEn: regSpec.specialization,
            titleBn: 'মানসিক স্বাস্থ্য বিশেষজ্ঞ',
            bioEn: regSpec.bio,
            bioBn: regSpec.bio,
            experienceYears: regSpec.experienceYears,
            rating: regSpec.rating,
            feeBdt: regSpec.consultationFee,
            locationType: 'Dhaka',
            isAvailable: true,
            isOnline: true,
          ),
        );
      }
    }

    final filteredSpecialists = allSpecialists.where((spec) {
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          spec.name.toLowerCase().contains(q) ||
          spec.titleEn.toLowerCase().contains(q) ||
          spec.titleBn.toLowerCase().contains(q) ||
          spec.specialization.toLowerCase().contains(q) ||
          spec.workingPlace.toLowerCase().contains(q) ||
          spec.degree.toLowerCase().contains(q);

      if (!matchesSearch) return false;
      if (q.isNotEmpty) return true;

      if (_selectedTab == 'Psychologists') {
        return spec.specialization.toLowerCase().contains('psychologist') ||
            spec.specialization.toLowerCase().contains('counseling') ||
            spec.name.toLowerCase().contains('jaba') ||
            spec.name.toLowerCase().contains('dr.');
      } else if (_selectedTab == 'Therapists') {
        return spec.specialization.toLowerCase().contains('therapist') ||
            spec.specialization.toLowerCase().contains('consultant') ||
            spec.specialization.toLowerCase().contains('counseling') ||
            spec.specialization.toLowerCase().contains('specialist');
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(isBn ? 'বিশেষজ্ঞ সেশন বুকিং' : 'Book Specialist Session', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: isBn ? 'ডাক্তারের নাম বা রোগ অনুযায়ী খুঁজুন...' : 'Search doctor by name (e.g. jaba acharjee)...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
              ),
            ),
          ),

          // Filter Pills
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: ['All', 'Psychologists', 'Therapists'].map((tab) {
                final isSelected = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tab),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedTab = tab);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Specialist Card List
          Expanded(
            child: _isLoadingLive
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : (filteredSpecialists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 54, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text(
                              isBn ? 'কোনো বিশেষজ্ঞ পাওয়া যায়নি' : 'No specialist found',
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredSpecialists.length,
                        itemBuilder: (context, index) {
                          final spec = filteredSpecialists[index];
                          return _buildSpecialistCard(spec, isBn, isDark);
                        },
                      )),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistCard(SpecialistModel spec, bool isBn, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Image / Base64 / Fallback
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildDoctorAvatarImage(spec),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            spec.name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.circle, color: Colors.green, size: 8),
                              const SizedBox(width: 4),
                              Text(
                                isBn ? 'অনলাইন' : 'Available',
                                style: const TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Degree
                    if (spec.degree.isNotEmpty)
                      Text(
                        spec.degree,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    const SizedBox(height: 2),

                    // Working place
                    if (spec.workingPlace.isNotEmpty)
                      Text(
                        spec.workingPlace,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Rating, Experience, Fee & Book Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${spec.experienceYears} ${isBn ? "বছর অভিজ্ঞতা" : "yrs exp"}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '৳${spec.feeBdt} / ${isBn ? "সেশন" : "Session"}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingScreen(specialist: spec),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16),
                label: Text(
                  isBn ? 'সেশন বুক করুন' : 'Book Session',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorAvatarImage(SpecialistModel spec) {
    return _buildAvatarFallback(spec);
  }

  Widget _buildAvatarFallback(SpecialistModel spec) {
    String initial = 'S';
    if (spec.name.isNotEmpty) {
      String cleanName = spec.name.replaceAll(RegExp(r'^Dr\.\s*', caseSensitive: false), '').trim();
      final parts = cleanName.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        initial = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (cleanName.isNotEmpty) {
        initial = cleanName[0].toUpperCase();
      }
    }
    
    return Container(
      width: 64,
      height: 64,
      color: AppColors.primary.withOpacity(0.15),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.2),
        ),
      ),
    );
  }
}
