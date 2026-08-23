import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/specialist_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'specialist_dashboard_screen.dart';

class CompleteSpecialistProfileScreen extends StatefulWidget {
  const CompleteSpecialistProfileScreen({super.key});

  @override
  State<CompleteSpecialistProfileScreen> createState() => _CompleteSpecialistProfileScreenState();
}

class _CompleteSpecialistProfileScreenState extends State<CompleteSpecialistProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _specializationCtrl;
  late TextEditingController _hospitalCtrl;
  late TextEditingController _experienceCtrl;
  late TextEditingController _qualificationCtrl;
  late TextEditingController _licenseNumberCtrl;
  late TextEditingController _languagesCtrl;
  late TextEditingController _feeCtrl;
  late TextEditingController _bioCtrl;

  String _gender = 'female';
  final List<String> _allDays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  late List<String> _selectedDays;
  late List<String> _selectedTimeSlots;

  bool _isSaving = false;
  bool _pushNotifications = true;
  String? _uploadedLicenseDoc;

  @override
  void initState() {
    super.initState();
    final spec = Provider.of<SpecialistProvider>(context, listen: false).profile;
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    _fullNameCtrl = TextEditingController(text: user != null && user.firstName.isNotEmpty ? '${user.firstName} ${user.lastName}'.trim() : spec.fullName);
    _phoneCtrl = TextEditingController(text: (user?.phone != null && user!.phone!.isNotEmpty) ? user.phone! : spec.phoneNumber);
    _emailCtrl = TextEditingController(text: user?.email.isNotEmpty == true ? user!.email : spec.email);
    _specializationCtrl = TextEditingController(text: spec.specialization);
    _hospitalCtrl = TextEditingController(text: spec.hospitalClinic);
    _experienceCtrl = TextEditingController(text: spec.experienceYears.toString());
    _qualificationCtrl = TextEditingController(text: spec.qualification);
    _licenseNumberCtrl = TextEditingController(text: spec.medicalLicenseNumber);
    _languagesCtrl = TextEditingController(text: spec.languages);
    _feeCtrl = TextEditingController(text: spec.consultationFee.toString());
    _bioCtrl = TextEditingController(text: spec.bio);
    _gender = spec.gender;
    _selectedDays = List.from(spec.availableDays);
    _selectedTimeSlots = List.from(spec.availableTimeSlots);
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _specializationCtrl.dispose();
    _hospitalCtrl.dispose();
    _experienceCtrl.dispose();
    _qualificationCtrl.dispose();
    _licenseNumberCtrl.dispose();
    _languagesCtrl.dispose();
    _feeCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 available working day.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final specProvider = Provider.of<SpecialistProvider>(context, listen: false);
    final spec = specProvider.profile;
    final updated = SpecialistProfileModel(
      fullName: _fullNameCtrl.text.trim(),
      gender: _gender,
      phoneNumber: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      specialization: _specializationCtrl.text.trim(),
      hospitalClinic: _hospitalCtrl.text.trim(),
      experienceYears: int.tryParse(_experienceCtrl.text) ?? 5,
      qualification: _qualificationCtrl.text.trim(),
      medicalLicenseNumber: _licenseNumberCtrl.text.trim(),
      licenseDocumentPath: _uploadedLicenseDoc ?? 'license_document.pdf',
      languages: _languagesCtrl.text.trim(),
      consultationFee: int.tryParse(_feeCtrl.text) ?? 1500,
      availableDays: _selectedDays,
      availableTimeSlots: _selectedTimeSlots,
      avatarUrl: spec.avatarUrl,
      bannerUrl: spec.bannerUrl,
      isProfileComplete: true,
      bio: _bioCtrl.text.trim(),
    );

    specProvider.updateProfile(updated);
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Specialist Settings Saved Successfully!')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SpecialistDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<AppLanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = authProvider.currentUser;

    final String doctorName = user != null && user.firstName.isNotEmpty
        ? '${user.firstName} ${user.lastName}'.trim()
        : _fullNameCtrl.text;
    final String initial = doctorName.isNotEmpty ? doctorName.substring(0, 1).toUpperCase() : 'D';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isBn ? 'সেটিংস ও প্রোফাইল' : 'Settings & Profile',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header Card Matching Patient Profile Card Design
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  border: Border(
                    bottom: BorderSide(color: isDark ? Colors.white : Colors.white),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        initial,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                doctorName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, color: Colors.blue, size: 18),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _specializationCtrl.text.isEmpty ? 'Clinical Psychologist' : _specializationCtrl.text,
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _emailCtrl.text.isEmpty ? 'doctor@ashwash.com' : _emailCtrl.text,
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: APPEARANCE
                    _buildSectionHeader(isBn ? 'অ্যাপিয়ারেন্স (APPEARANCE)' : 'APPEARANCE'),
                    SwitchListTile(
                      secondary: const Icon(Icons.wb_sunny_outlined, color: Colors.black),
                      title: Text(isBn ? 'ডার্ক মোড' : 'Dark Mode'),
                      subtitle: Text(themeProvider.isDarkMode ? 'Dark mode active' : 'Light mode active'),
                      activeColor: AppColors.primary,
                      value: themeProvider.isDarkMode,
                      onChanged: (val) => themeProvider.toggleTheme(),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 2: LANGUAGE
                    _buildSectionHeader(isBn ? 'ভাষা (LANGUAGE)' : 'LANGUAGE'),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !isBn ? AppColors.primary : Colors.white,
                                foregroundColor: !isBn ? Colors.white : Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => langProvider.setLanguage('en'),
                              child: const Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isBn ? AppColors.primary : Colors.white,
                                foregroundColor: isBn ? Colors.white : Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => langProvider.setLanguage('bn'),
                              child: const Text('বাংলা', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 3: NOTIFICATIONS
                    _buildSectionHeader(isBn ? 'নোটিফিকেশন (NOTIFICATIONS)' : 'NOTIFICATIONS'),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active_outlined, color: Colors.black),
                      title: Text(isBn ? 'পুশ নোটিফিকেশন' : 'Push Notifications'),
                      subtitle: Text(isBn ? 'রোগীদের অ্যাপয়েন্টমেন্ট ও মেসেজের আপডেট পান' : 'Get notified about patient sessions'),
                      activeColor: AppColors.primary,
                      value: _pushNotifications,
                      onChanged: (val) => setState(() => _pushNotifications = val),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 4: DOCTOR PROFILE & CLINICAL DETAILS
                    _buildSectionHeader(isBn ? 'ডাক্তার প্রফেশনাল প্রোফাইল' : 'SPECIALIST PROFILE & CLINIC'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.glassSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white : Colors.white),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _fullNameCtrl,
                            decoration: _inputDecoration('Full Name', Icons.person_outline, isDark),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter full name' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _specializationCtrl,
                            decoration: _inputDecoration('Specialization Area', Icons.medical_services_outlined, isDark),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _hospitalCtrl,
                            decoration: _inputDecoration('Hospital / Clinic Center', Icons.location_city_outlined, isDark),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _feeCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Fee (BDT)', Icons.payments_outlined, isDark),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _experienceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Experience (Yrs)', Icons.workspace_premium_outlined, isDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _licenseNumberCtrl,
                            decoration: _inputDecoration('BMDC License / Registration No.', Icons.verified_user_outlined, isDark),
                          ),
                          const SizedBox(height: 14),

                          // Working Days Selector
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Available Working Days:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: _allDays.map((day) {
                              final isSelected = _selectedDays.contains(day);
                              return FilterChip(
                                label: Text(day, style: const TextStyle(fontSize: 11)),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      _selectedDays.add(day);
                                    } else {
                                      _selectedDays.remove(day);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SAVE SETTINGS BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isBn ? 'সেটিংস সেভ করুন' : 'Save Settings',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // LOGOUT BUTTON (Matching Patient Profile Logout Button)
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: Colors.red),
                      title: Text(
                        isBn ? 'লগআউট করুন' : 'Log Out',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      onTap: () async {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        await authProvider.logout();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.black, size: 20),
      filled: true,
      fillColor: isDark ? AppColors.darkSurface : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white : Colors.white),
      ),
    );
  }
}
