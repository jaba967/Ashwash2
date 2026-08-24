import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;

  Future<void> _showManageAccountSheet(BuildContext context, bool isBn) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    final usernameCtrl = TextEditingController(text: user?.username ?? '');
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isUploadingImage = false;
    bool isSavingUsername = false;
    bool isChangingPassword = false;
    String? usernameError;
    String? passwordError;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final currentUser = Provider.of<AuthProvider>(context).currentUser;
            final avatarStr = currentUser?.avatar;

            ImageProvider? avatarImage;
            if (avatarStr != null && avatarStr.isNotEmpty) {
              if (avatarStr.startsWith('data:image') || avatarStr.length > 100) {
                try {
                  final cleanBase64 = avatarStr.contains(',') ? avatarStr.split(',').last : avatarStr;
                  avatarImage = MemoryImage(base64Decode(cleanBase64));
                } catch (_) {}
              } else if (avatarStr.startsWith('http')) {
                avatarImage = NetworkImage(avatarStr);
              }
            }

            Future<void> pickAndUploadImage() async {
              try {
                setSheetState(() => isUploadingImage = true);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                  allowMultiple: false,
                  withData: true,
                );

                if (result != null && result.files.isNotEmpty) {
                  final pickedFile = result.files.first;
                  List<int>? bytes = pickedFile.bytes;

                  if (bytes == null && pickedFile.path != null) {
                    bytes = await File(pickedFile.path!).readAsBytes();
                  }

                  if (bytes != null && bytes.isNotEmpty) {
                    final base64String = 'data:image/png;base64,${base64Encode(bytes)}';
                    
                    // INSTANT LOCAL UPDATE
                    await authProvider.updateProfilePicLocally(base64String);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isBn ? 'গ্যালারি থেকে প্রোফাইল ছবি আপডেট হয়েছে!' : 'Profile picture updated from device!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                debugPrint("Image pick error: $e");
              } finally {
                setSheetState(() => isUploadingImage = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Row(
                      children: [
                        const Icon(Icons.manage_accounts_outlined, color: Colors.black, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          isBn ? 'অ্যাকাউন্ট পরিচালনা (Manage Account)' : 'Manage Account',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),

                    // SECTION 1: PROFILE PICTURE SELECTION (INSTANT DEVICE GALLERY UPDATE)
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 3.5),
                                  color: AppColors.primary.withOpacity(0.1),
                                ),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                                  backgroundImage: avatarImage,
                                  child: isUploadingImage
                                      ? const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3)
                                      : (avatarImage == null
                                          ? Text(
                                              (currentUser?.username.isNotEmpty == true ? currentUser!.username[0].toUpperCase() : 'U'),
                                              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                                            )
                                          : null),
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: InkWell(
                                  onTap: isUploadingImage ? null : pickAndUploadImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Colors.black, blurRadius: 4)],
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: isUploadingImage ? null : pickAndUploadImage,
                            child: isUploadingImage
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(
                                    isBn ? 'ছবি যোগ বা পরিবর্তন করুন' : 'Add or Change Photo',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 2: CHANGE USERNAME (INDEPENDENT LOADING STATE)
                    Text(
                      isBn ? 'ইউজারনেম পরিবর্তন করুন' : 'Change Username',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: usernameCtrl,
                            decoration: InputDecoration(
                              labelText: isBn ? 'নতুন ইউজারনেম' : 'New Username',
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSavingUsername
                              ? null
                              : () async {
                                  final newName = usernameCtrl.text.trim();
                                  if (newName.isEmpty) return;

                                  setSheetState(() {
                                    isSavingUsername = true;
                                    usernameError = null;
                                  });

                                  final ok = await authProvider.updateProfile(username: newName);
                                  setSheetState(() => isSavingUsername = false);

                                  if (ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isBn ? 'ইউজারনেম সফলভাবে পরিবর্তন হয়েছে!' : 'Username updated successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    setSheetState(() => usernameError = authProvider.errorMessage);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSavingUsername
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(isBn ? 'সেভ' : 'Save', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if (usernameError != null) ...[
                      const SizedBox(height: 6),
                      Text(usernameError!, style: const TextStyle(color: AppColors.emergency, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(height: 24),
                    const Divider(),

                    // SECTION 3: CHANGE PASSWORD
                    Text(
                      isBn ? 'পাসওয়ার্ড পরিবর্তন করুন' : 'Change Password',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black),
                    ),
                    const SizedBox(height: 12),
                    if (passwordError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.emergency.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          passwordError!,
                          style: const TextStyle(color: AppColors.emergency, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: oldPasswordCtrl,
                      obscureText: obscureOld,
                      decoration: InputDecoration(
                        labelText: isBn ? 'বর্তমান পাসওয়ার্ড' : 'Current Password',
                        prefixIcon: const Icon(Icons.lock_clock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(obscureOld ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setSheetState(() => obscureOld = !obscureOld),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: isBn ? 'নতুন পাসওয়ার্ড' : 'New Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setSheetState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: isBn ? 'নতুন পাসওয়ার্ড নিশ্চিত করুন' : 'Confirm New Password',
                        prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isChangingPassword
                          ? null
                          : () async {
                              final oldPass = oldPasswordCtrl.text.trim();
                              final newPass = newPasswordCtrl.text.trim();
                              final confirmPass = confirmPasswordCtrl.text.trim();

                              if (oldPass.isEmpty || newPass.isEmpty) {
                                setSheetState(() => passwordError = isBn ? 'সকল ঘর পুরন করুন' : 'Please fill all fields');
                                return;
                              }
                              if (newPass.length < 6) {
                                setSheetState(() => passwordError = isBn ? 'কমপক্ষে ৬ অক্ষরের পাসওয়ার্ড দিন' : 'Password must be at least 6 characters');
                                return;
                              }
                              if (newPass != confirmPass) {
                                setSheetState(() => passwordError = isBn ? 'নতুন পাসওয়ার্ড দুটি মিলছে না' : 'New passwords do not match');
                                return;
                              }

                              setSheetState(() {
                                isChangingPassword = true;
                                passwordError = null;
                              });

                              try {
                                final response = await ApiService.post(
                                  ApiEndpoints.changePassword,
                                  {
                                    'old_password': oldPass,
                                    'new_password': newPass,
                                    'confirm_password': confirmPass,
                                  },
                                  requireAuth: true,
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response['detail'] ?? (isBn ? 'পাসওয়ার্ড সফলভাবে পরিবর্তিত হয়েছে!' : 'Password updated successfully!')),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() {
                                  isChangingPassword = false;
                                  passwordError = e.toString().replaceAll('Exception: ', '');
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isChangingPassword
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              isBn ? 'পাসওয়ার্ড আপডেট করুন' : 'Update Password',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPrivacySettingsSheet(BuildContext context, bool isBn) async {
    bool allowAnonymous = true;
    bool shareAnalytics = true;
    bool dataConsent = true;
    bool isLoading = true;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (isLoading) {
              ApiService.get(ApiEndpoints.privacySettings, requireAuth: true).then((data) {
                setSheetState(() {
                  allowAnonymous = data['allow_anonymous_posts'] ?? true;
                  shareAnalytics = data['share_progress_analytics'] ?? true;
                  dataConsent = data['data_usage_consent'] ?? true;
                  isLoading = false;
                });
              }).catchError((_) {
                setSheetState(() => isLoading = false);
              });
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  Row(
                    children: [
                      const Icon(Icons.privacy_tip_outlined, color: Colors.black, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        isBn ? 'গোপনীয়তা সেটিংস' : 'Privacy Settings',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    )
                  else ...[
                    SwitchListTile(
                      title: Text(isBn ? 'কমিউনিটিতে পরিচয় গোপন রাখা' : 'Anonymous Community Posts'),
                      subtitle: Text(isBn ? 'নাম প্রকাশ না করে পোস্টে মন্তব্য ও শেয়ার করা' : 'Share posts without revealing identity'),
                      activeColor: AppColors.primary,
                      value: allowAnonymous,
                      onChanged: (val) => setSheetState(() => allowAnonymous = val),
                    ),
                    SwitchListTile(
                      title: Text(isBn ? 'অ্যানোনিমাস প্রোগ্রেস অ্যানালিটিক্স' : 'Share Progress Analytics'),
                      subtitle: Text(isBn ? 'ব্যক্তিগত সাজেশনের জন্য ডেটা অ্যানালাইসিস' : 'Allow analytics for personalized recommendations'),
                      activeColor: AppColors.primary,
                      value: shareAnalytics,
                      onChanged: (val) => setSheetState(() => shareAnalytics = val),
                    ),
                    SwitchListTile(
                      title: Text(isBn ? 'ডেটা ব্যবহারের সম্মতি' : 'Data Usage Consent'),
                      subtitle: Text(isBn ? 'আপনার ডেটা নিরাপদে সংকেত ও ব্যবহারের অধিকার' : 'Consent to process data securely for mental wellness'),
                      activeColor: AppColors.primary,
                      value: dataConsent,
                      onChanged: (val) => setSheetState(() => dataConsent = val),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheetState(() => isSaving = true);
                              try {
                                await ApiService.post(
                                  ApiEndpoints.privacySettings,
                                  {
                                    'allow_anonymous_posts': allowAnonymous,
                                    'share_progress_analytics': shareAnalytics,
                                    'data_usage_consent': dataConsent,
                                  },
                                  requireAuth: true,
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isBn ? 'গোপনীয়তা সেটিংস সফলভাবে আপডেট হয়েছে!' : 'Privacy settings saved successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    backgroundColor: AppColors.emergency,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              isBn ? 'গোপনীয়তা সেটিংস সেভ করুন' : 'Save Privacy Settings',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<AppLanguageProvider>(context);
    final themeProvider = Provider.of<AppThemeProvider>(context);
    final isBn = langProvider.isBangla;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'সেটিংস' : 'Settings', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ACCOUNT MANAGEMENT
          _buildSectionHeader(isBn ? 'অ্যাকাউন্ট পরিচালনা' : 'ACCOUNT MANAGEMENT'),
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined, color: Colors.black),
            title: Text(isBn ? 'অ্যাকাউন্ট পরিচালনা করুন' : 'Manage Account'),
            subtitle: Text(isBn ? 'ছবি, ইউজারনেম ও পাসওয়ার্ড আপডেট' : 'Profile photo, username & password'),
            onTap: () => _showManageAccountSheet(context, isBn),
          ),
          const SizedBox(height: 20),

          // APPEARANCE & THEME
          _buildSectionHeader(isBn ? 'অ্যাপিয়ারেন্স ও থিম (Appearance & Theme)' : 'APPEARANCE & THEME'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !themeProvider.isDarkMode ? AppColors.deepForestGreen : AppColors.darkForestSurface,
                      foregroundColor: !themeProvider.isDarkMode ? Colors.white : AppColors.lightText,
                      side: BorderSide(color: !themeProvider.isDarkMode ? AppColors.deepForestGreen : AppColors.sageGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => themeProvider.toggleTheme(false),
                    icon: const Icon(Icons.light_mode_outlined, size: 18),
                    label: Text(isBn ? 'লাইট থিম' : 'Light Theme', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.isDarkMode ? AppColors.deepForestGreen : AppColors.cardLight,
                      foregroundColor: themeProvider.isDarkMode ? Colors.white : AppColors.charcoalGray,
                      side: BorderSide(color: themeProvider.isDarkMode ? AppColors.deepForestGreen : AppColors.sageGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => themeProvider.toggleTheme(true),
                    icon: const Icon(Icons.dark_mode_outlined, size: 18),
                    label: Text(isBn ? 'ডার্ক থিম' : 'Dark Theme', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // LANGUAGE
          _buildSectionHeader(isBn ? 'ভাষা' : 'LANGUAGE'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          // NOTIFICATIONS
          _buildSectionHeader(isBn ? 'নোটিফিকেশন' : 'NOTIFICATIONS'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined, color: Colors.black),
            title: Text(isBn ? 'পুশ নোটিফিকেশন' : 'Push Notifications'),
            subtitle: Text(isBn ? 'টাস্ক এবং সেশনের খবর পান' : 'Get notified about tasks and sessions'),
            activeColor: AppColors.primary,
            value: _pushNotifications,
            onChanged: (val) => setState(() => _pushNotifications = val),
          ),
          const SizedBox(height: 20),

          // PRIVACY & SECURITY
          _buildSectionHeader(isBn ? 'গোপনীয়তা ও নিরাপত্তা' : 'PRIVACY & SECURITY'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.black),
            title: Text(isBn ? 'গোপনীয়তা সেটিংস' : 'Privacy Settings'),
            subtitle: Text(isBn ? 'আপনার তথ্য ও ডেটা পরিচালনা করুন' : 'Manage your data and privacy'),
            onTap: () => _showPrivacySettingsSheet(context, isBn),
          ),
          const SizedBox(height: 20),

          // ABOUT
          _buildSectionHeader(isBn ? 'সম্পর্কে' : 'ABOUT'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, color: Colors.black),
            title: const Text('Ashwash v1.0.0'),
            subtitle: const Text('Mental Wellness Support Platform'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1),
      ),
    );
  }
}
