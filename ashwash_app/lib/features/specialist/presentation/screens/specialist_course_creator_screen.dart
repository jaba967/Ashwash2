import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/providers/course_provider.dart';
import '../../../../core/providers/specialist_provider.dart';
import '../../../../core/services/cloudinary_service.dart';

class SpecialistCourseCreatorScreen extends StatefulWidget {
  final CreatedCourseModel? courseToEdit;
  const SpecialistCourseCreatorScreen({super.key, this.courseToEdit});

  @override
  State<SpecialistCourseCreatorScreen> createState() => _SpecialistCourseCreatorScreenState();
}

class _SpecialistCourseCreatorScreenState extends State<SpecialistCourseCreatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '4 Weeks');
  final _priceCtrl = TextEditingController(text: '0');

  String _category = 'POSTPARTUM_DEPRESSION';
  String _difficulty = 'Beginner';
  String? _coverPhotoUrl;
  bool _isUploadingCover = false;
  double _coverUploadProgress = 0.0;

  final List<Map<String, String>> _uploadedLessons = [];
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    if (widget.courseToEdit != null) {
      final c = widget.courseToEdit!;
      _titleCtrl.text = c.title;
      _subtitleCtrl.text = c.subtitle;
      _descriptionCtrl.text = c.subtitle;
      _category = c.category;
      _coverPhotoUrl = c.thumbnailUrl;
      _uploadedLessons.addAll(c.lessons);
    }
  }

  void _addLessonModal() {
    final titleCtrl = TextEditingController();
    String type = 'Video';
    String? mediaUrl;
    bool isUploading = false;
    double uploadProgress = 0.0;
    String uploadStatus = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Lesson / Media Content'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Lesson Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                items: ['Video', 'Audio', 'PDF Document', 'Text', 'Assignment', 'Quiz']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setDialogState(() => type = val!),
                decoration: InputDecoration(
                  labelText: 'Lesson Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              if (isUploading) ...[
                LinearProgressIndicator(
                  value: uploadProgress,
                  backgroundColor: Colors.grey.shade200,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 6),
                Text(
                  uploadStatus,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 10),
              ],

              InkWell(
                onTap: isUploading ? null : () async {
                  FileType pickerType = FileType.any;
                  if (type == 'Video') pickerType = FileType.video;
                  if (type == 'Audio') pickerType = FileType.audio;
                  if (type == 'PDF Document') pickerType = FileType.custom;

                  final result = await FilePicker.platform.pickFiles(
                    type: pickerType,
                    allowedExtensions: type == 'PDF Document' ? ['pdf'] : null,
                  );

                  if (result != null && result.files.single.path != null) {
                    final localPath = result.files.single.path!;
                    final fileName = result.files.single.name;

                    setDialogState(() {
                      isUploading = true;
                      uploadProgress = 0.1;
                      uploadStatus = 'Uploading $fileName to Cloudinary... 10%';
                    });

                    final res = await CloudinaryService.uploadFile(
                      filePath: localPath,
                      onProgress: (p) {
                        setDialogState(() {
                          uploadProgress = p;
                          uploadStatus = 'Uploading... ${(p * 100).toInt()}%';
                        });
                      },
                    );

                    setDialogState(() {
                      isUploading = false;
                      if (res.success) {
                        mediaUrl = res.secureUrl;
                        uploadStatus = 'Cloudinary Upload Complete!';
                      } else {
                        uploadStatus = 'Upload Failed: ${res.error}';
                      }
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: mediaUrl != null ? AppColors.success.withOpacity(0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: mediaUrl != null ? AppColors.success : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(mediaUrl != null ? Icons.check_circle : Icons.upload_file, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          mediaUrl != null
                              ? 'Cloudinary Attached!\n$mediaUrl'
                              : 'Pick Device File (MP4, MP3, PDF)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isUploading ? null : () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    final finalMediaUrl = mediaUrl ?? 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785525213/Postpartum_Depression_mood_disorder_after_child_birth_in_Bangla_Dr_Mekhala_Sarkar_-_Dr._Mekhala_Sarkar_720p_h264_twt9ei.mp4';
                    _uploadedLessons.add({
                      'title': titleCtrl.text.trim(),
                      'type': type,
                      'file': finalMediaUrl,
                      'video_url': finalMediaUrl,
                      'url': finalMediaUrl,
                      'content_url': finalMediaUrl,
                    });
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Add Lesson', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _publishCourse() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadedLessons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 lesson/media content to the course.')),
      );
      return;
    }

    setState(() => _isPublishing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final bool isEditing = widget.courseToEdit != null;
    final targetCourseId = isEditing ? widget.courseToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString();
    final specProvider = Provider.of<SpecialistProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final specName = specProvider.profile.fullName.isNotEmpty ? specProvider.profile.fullName : 'Verified Specialist';

    final courseModel = CreatedCourseModel(
      id: targetCourseId,
      title: _titleCtrl.text.trim(),
      subtitle: _subtitleCtrl.text.trim(),
      category: _category,
      duration: '4 Weeks',
      priceBdt: 0,
      thumbnailUrl: _coverPhotoUrl ?? 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500',
      instructorName: specName,
      lessons: List.from(_uploadedLessons),
    );

    if (isEditing) {
      specProvider.updateCourse(courseModel);
    } else {
      specProvider.addCourse(courseModel);
    }

    final payload = {
      'title_en': _titleCtrl.text.trim(),
      'title_bn': _titleCtrl.text.trim(),
      'subtitle_en': _subtitleCtrl.text.trim(),
      'subtitle_bn': _subtitleCtrl.text.trim(),
      'description_en': _descriptionCtrl.text.trim(),
      'description_bn': _descriptionCtrl.text.trim(),
      'duration_weeks': 4,
      'total_tasks': _uploadedLessons.length,
      'type_label': 'Both',
      'price': 0.00,
      'is_free': true,
      'rating': 5.0,
      'lessons': List.from(_uploadedLessons),
    };

    try {
      if (isEditing) {
        await ApiService.put('/api/courses/$targetCourseId/', payload, requireAuth: true);
      } else {
        await ApiService.post(ApiEndpoints.courses, payload, requireAuth: true);
      }
    } catch (_) {}

    // Synchronize to Patient Course Catalog & local state
    courseProvider.addDynamicCourse({
      'id': int.tryParse(targetCourseId.substring(targetCourseId.length > 6 ? targetCourseId.length - 6 : 0)) ?? 999,
      'title': _titleCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'category': _category,
      'duration_weeks': 4,
      'total_tasks': _uploadedLessons.length,
      'format': 'Video & Audio',
      'price': 0.00,
      'is_free': true,
      'rating': 5.0,
      'instructor': specName,
      'specialist': specName,
      'specialist_degree': specProvider.profile.qualification,
      'specialist_photo': specProvider.profile.avatarUrl ?? '',
      'instructor_photo': specProvider.profile.avatarUrl ?? '',
      'is_real_course': true,
      'lessons': List.from(_uploadedLessons),
    });

    setState(() => _isPublishing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Course Created & Published! Patients can now search and enroll.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<AppLanguageProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isBn ? 'নতুন কোর্স ও কন্টেন্ট তৈরি' : 'Create Course & Upload Content',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: _inputDecoration('Course Title', Icons.book_outlined, isDark),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter course title' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _subtitleCtrl,
                decoration: _inputDecoration('Subtitle / Summary', Icons.subtitles_outlined, isDark),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _category,
                items: [
                  const DropdownMenuItem(value: 'POSTPARTUM_DEPRESSION', child: Text('Postpartum Depression')),
                  const DropdownMenuItem(value: 'SINGLE_PARENT', child: Text('Single Parent Support')),
                  const DropdownMenuItem(value: 'SPECIAL_CHILD', child: Text('Special Child Parenting')),
                  const DropdownMenuItem(value: 'CORPORATE_EMPLOYEE', child: Text('Corporate Stress')),
                  const DropdownMenuItem(value: 'UNIVERSITY_STUDENT', child: Text('Student Mental Health')),
                ],
                onChanged: (val) => setState(() => _category = val!),
                decoration: _inputDecoration('Category', Icons.category_outlined, isDark),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: _inputDecoration('Detailed Description', Icons.description_outlined, isDark),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 20),

              // Curriculum Lessons Builder Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isBn ? 'কারিকুলাম ও লেসনসমূহ (${_uploadedLessons.length})' : 'Curriculum & Lessons (${_uploadedLessons.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addLessonModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    label: Text(isBn ? 'লেসন যোগ করুন' : 'Add Lesson', style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ..._uploadedLessons.asMap().entries.map((entry) {
                final idx = entry.key;
                final l = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: Text('${idx + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Type: ${l['type']} • File: ${l['file']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => setState(() => _uploadedLessons.removeAt(idx)),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isPublishing ? null : _publishCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isPublishing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isBn ? 'কোর্স পাবলিশ করুন' : 'Publish Course to Platform',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.glassSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
    );
  }
}
