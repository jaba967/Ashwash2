import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/providers/specialist_provider.dart';
import 'patient_detail_screen.dart';

class SpecialistPatientManagementScreen extends StatefulWidget {
  const SpecialistPatientManagementScreen({super.key});

  @override
  State<SpecialistPatientManagementScreen> createState() => _SpecialistPatientManagementScreenState();
}

class _SpecialistPatientManagementScreenState extends State<SpecialistPatientManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'ALL';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<AppLanguageProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final specProvider = Provider.of<SpecialistProvider>(context);

    final allPatients = specProvider.patients;
    final filtered = allPatients.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchCtrl.text.toLowerCase());
      final matchesCat = _selectedCategory == 'ALL' || p.category.toUpperCase().contains(_selectedCategory);
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isBn ? 'রোগী ডিরেক্টরি ও হিস্ট্রি' : 'Patient Directory & Chart',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: isBn ? 'রোগীর নাম বা ক্যাটাগরি দিয়ে খুঁজুন...' : 'Search patient by name or category...',
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.black),
                filled: true,
                fillColor: AppColors.glassSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? Colors.white : Colors.white),
                ),
              ),
            ),
          ),

          // Patients Feed
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      isBn ? 'কোনো রোগী পাওয়া যায়নি' : 'No patients found',
                      style: TextStyle(color: isDark ? Colors.white : Colors.white),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final patient = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.glassSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.white : Colors.white),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundImage: NetworkImage(patient.avatarUrl),
                          ),
                          title: Row(
                            children: [
                              Text(
                                patient.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('(${patient.age}y)', style: const TextStyle(fontSize: 12, color: Colors.white)),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${patient.category} • Mood: ${patient.moodState}',
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.white),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildMiniBadge('Course: ${patient.courseProgress}%', AppColors.primary),
                                  const SizedBox(width: 6),
                                  _buildMiniBadge('HW: ${patient.homeworkCompleted}', Colors.orange),
                                  const SizedBox(width: 6),
                                  _buildMiniBadge('Sessions: ${patient.completedSessions}', Colors.teal),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatientDetailScreen(patient: patient),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
