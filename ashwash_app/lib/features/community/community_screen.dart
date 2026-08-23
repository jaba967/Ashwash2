import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedTag = 'All';
  bool _isLoading = true;
  List<Map<String, dynamic>> _posts = [];
  final List<String> _tags = ['All', 'Success Story', 'Question', 'Support'];

  // Global shared community database in device storage
  static List<Map<String, dynamic>> _sharedCommunityDb = [
    {
      'id': 1,
      'author_alias': 'Anonymous Member',
      'is_anonymous': true,
      'tag': 'Support',
      'content': 'গত কয়েকদিন ধরে খুব মানসিক চাপে ভুগছি। রাতে ঠিকমত ঘুম হচ্ছে না। কেউ কি সাহায্য বা শ্বাস-প্রশ্বাসের ভালো টিপস দিতে পারেন?',
      'likes_count': 14,
      'comments_count': 2,
      'is_liked': false,
      'created_at': '১০ মিনিট আগে',
      'comments': [
        {
          'id': 101,
          'author_alias': 'Dr. Sharmin Akter (Specialist)',
          'content': 'ধন্যবাদ শেয়ার করার জন্য। ৪-৭-৮ শ্বাস-প্রশ্বাসের ব্যায়ামটি ঘুমানোর আগে ৩ মিনিট করুন। মানসিক চাপ কমাতে সাহায্য করবে।',
          'created_at': '৫ মিনিট আগে',
        },
        {
          'id': 102,
          'author_alias': 'Dr. Anisur Rahman (Psychiatrist)',
          'content': 'প্রতিদিন রাতে ঘুমানোর ৩০ মিনিট আগে স্ক্রিন টাইম বন্ধ রাখুন এবং হালকা গরম পানি বা ক্যাফেইন-মুক্ত টি খেতে পারেন।',
          'created_at': '২ মিনিট আগে',
        }
      ]
    },
    {
      'id': 2,
      'author_alias': 'Tanvir Hasan',
      'is_anonymous': false,
      'tag': 'Success Story',
      'content': 'আশ্বাস অ্যাপের ৩ সপ্তাহের মাইন্ডফুলনেস কোর্স সম্পন্ন করার পর আমার এংজাইটি অনেক নিয়ন্ত্রণে এসেছে। আলহামদুলিল্লাহ!',
      'likes_count': 28,
      'comments_count': 1,
      'is_liked': true,
      'created_at': '১ ঘণ্টা আগে',
      'comments': [
        {
          'id': 103,
          'author_alias': 'Dr. Farhana Islam (Specialist)',
          'content': 'অভিনন্দন তানভীর! প্র্যাকটিস অব্যাহত রাখুন। আপনার অগ্রগতি সত্যিই প্রশংসনীয়।',
          'created_at': '৩০ মিনিট আগে',
        }
      ]
    },
  ];

  String _formatCreatedAt(dynamic raw) {
    if (raw == null) return 'Recently';
    final str = raw.toString();
    if (str.contains('T')) {
      try {
        final dt = DateTime.parse(str).toLocal();
        final now = DateTime.now();
        final diff = now.difference(dt);
        if (diff.inSeconds < 60) return 'Just now';
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        if (diff.inHours < 24) return '${diff.inHours}h ago';
        return '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {
        return str.split('T')[0];
      }
    }
    return str;
  }

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _savePostsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('persisted_community_posts_v2', jsonEncode(_sharedCommunityDb));
  }

  Future<void> _fetchPosts() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final String url = _selectedTag == 'All'
          ? ApiEndpoints.posts
          : '${ApiEndpoints.posts}?tag=$_selectedTag';
      final List<dynamic> data = await ApiService.getList(url, requireAuth: false);
      final apiPosts = data.map((item) => Map<String, dynamic>.from(item as Map)).toList();

      if (apiPosts.isNotEmpty) {
        _posts = List<Map<String, dynamic>>.from(apiPosts);
        _sharedCommunityDb = List<Map<String, dynamic>>.from(apiPosts);
        await _savePostsToStorage();
      } else {
        _loadStoragePosts();
      }
    } catch (_) {
      _loadStoragePosts();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _loadStoragePosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('persisted_community_posts_v2');
      if (savedStr != null) {
        final List<dynamic> decoded = jsonDecode(savedStr);
        _sharedCommunityDb = List<Map<String, dynamic>>.from(decoded);
        _posts = List.from(_sharedCommunityDb);
        if (_selectedTag != 'All') {
          _posts = _posts.where((p) => p['tag'] == _selectedTag).toList();
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleLike(int postId, int index) async {
    try {
      await ApiService.post(
        '${ApiEndpoints.baseUrl}/community/posts/$postId/like/',
        {},
        requireAuth: true,
      );
    } catch (_) {}

    final idx = _sharedCommunityDb.indexWhere((p) => p['id'] == postId);
    if (idx != -1) {
      final currentLiked = _sharedCommunityDb[idx]['is_liked'] ?? false;
      final currentLikes = _sharedCommunityDb[idx]['likes_count'] ?? 0;
      _sharedCommunityDb[idx]['is_liked'] = !currentLiked;
      _sharedCommunityDb[idx]['likes_count'] = !currentLiked ? currentLikes + 1 : (currentLikes > 0 ? currentLikes - 1 : 0);
      await _savePostsToStorage();
      _fetchPosts();
    }
  }

  void _deletePost(int postId) async {
    try {
      await ApiService.delete('${ApiEndpoints.posts}$postId/', requireAuth: true);
    } catch (_) {}

    _sharedCommunityDb.removeWhere((p) => p['id'] == postId);
    await _savePostsToStorage();
    _fetchPosts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully'), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmDeletePost(BuildContext context, int postId, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBn ? 'পোস্ট মুছে ফেলতে চান?' : 'Delete Post?'),
        content: Text(isBn ? 'আপনি কি নিশ্চিত যে এই পোস্টটি চিরতরে মুছে ফেলতে চান?' : 'Are you sure you want to permanently delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'বাতিল' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deletePost(postId);
            },
            child: Text(isBn ? 'মুছে ফেলুন' : 'Delete', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _editPost(int postId, String newContent, String newTag, bool isAnonymous) async {
    try {
      await ApiService.patch(
        '${ApiEndpoints.posts}$postId/',
        {
          'content': newContent,
          'tag': newTag,
          'is_anonymous': isAnonymous,
        },
        requireAuth: true,
      );
    } catch (_) {}

    final idx = _sharedCommunityDb.indexWhere((p) => p['id'] == postId);
    if (idx != -1) {
      _sharedCommunityDb[idx]['content'] = newContent;
      _sharedCommunityDb[idx]['tag'] = newTag;
      _sharedCommunityDb[idx]['is_anonymous'] = isAnonymous;
      if (isAnonymous) {
        _sharedCommunityDb[idx]['author_alias'] = 'Anonymous Member';
      }
      await _savePostsToStorage();
    }
    _fetchPosts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _reportPost(int postId, String reason) async {
    try {
      await ApiService.post(
        '${ApiEndpoints.posts}$postId/report/',
        {'reason': reason},
        requireAuth: true,
      );
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Our administration team has been notified to review this post.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
        scrolledUnderElevation: 0,
        title: Text(
          isBn ? 'কমিউনিটি ফোরাম' : 'Community Forum',
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final isSpec = auth.currentUser?.role == 'SPECIALIST' || auth.currentUser?.role == 'DOCTOR';
              if (!isSpec) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.primary.withOpacity(0.15),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isBn ? 'ভেরিফাইড স্পেশালিস্ট মোড: আপনার মন্তব্য ডক্টর ব্যাজসহ দেখা যাবে' : 'Verified Specialist Mode: Replying with Official Doctor Badge',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Filter Tags Row
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tags.length,
              itemBuilder: (context, index) {
                final tag = _tags[index];
                final isSelected = _selectedTag == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tag),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedTag = tag;
                        _fetchPosts();
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Posts Feed List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _posts.isEmpty
                    ? Center(
                        child: Text(
                          isBn ? 'কোনো পোস্ট পাওয়া যায়নি' : 'No community posts found',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPosts,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            return _buildPostCard(post, index, isBn, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final isSpec = auth.currentUser?.role == 'SPECIALIST' || auth.currentUser?.role == 'DOCTOR';
          if (isSpec) return const SizedBox.shrink(); // Only Patients can create community posts
          return FloatingActionButton.extended(
            onPressed: () => _showAddPostDialog(context, isBn),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
            label: Text(
              isBn ? 'নতুন পোস্ট' : 'New Post',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index, bool isBn, bool isDark) {
    final bool isAnon = post['is_anonymous'] ?? true;
    final String authorAlias = post['author_alias'] ?? (isAnon ? 'Anonymous Member' : 'User');
    final bool isLiked = post['is_liked'] ?? false;
    final int likesCount = post['likes_count'] ?? 0;
    final List commentsList = post['comments'] ?? [];
    final int rawCommentsCount = post['comments_count'] ?? 0;
    final int commentsCount = rawCommentsCount > commentsList.length ? rawCommentsCount : commentsList.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textSecondaryLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isAnon ? const Color(0xFFF3E8FF) : AppColors.primary.withOpacity(0.15),
                child: Icon(
                  isAnon ? Icons.security_rounded : Icons.person,
                  color: isAnon ? const Color(0xFFA855F7) : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          authorAlias,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                        if (isAnon)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isBn ? 'বেনামী' : 'Anonymous',
                              style: TextStyle(fontSize: 10, color: Colors.purple.shade700, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCreatedAt(post['created_at']),
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              if (post['tag'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    post['tag'].toString(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Post Body Text
          Text(
            post['content'] ?? '',
            style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? Colors.grey.shade200 : const Color(0xFF334155)),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Action Buttons: Like, Specialist Comments, Report
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 22,
                  color: isLiked ? Colors.redAccent : Colors.grey.shade500,
                ),
                onPressed: () => _toggleLike(post['id'] ?? 0, index),
              ),
              Text('$likesCount', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 20),

              // View Specialist Comments Button
              InkWell(
                onTap: () => _showCommentsSheet(context, post, isBn),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 20, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 6),
                      Text(
                        '$commentsCount ${isBn ? "বিশেষজ্ঞদের পরামর্শ" : "Expert Replies"}',
                        style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Post Actions Menu (Edit & Delete for Owner, Report for others)
              Builder(
                builder: (context) {
                  final authUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
                  final bool isOwner = post['is_owner'] == true ||
                      (authUser != null && post['author'] != null && post['author'].toString() == authUser.id.toString()) ||
                      (authUser != null && post['author_username'] != null && post['author_username'] == authUser.username) ||
                      (authUser != null && !isAnon && post['author_alias'] == '${authUser.firstName} ${authUser.lastName}'.trim());

                  return PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondaryLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (val) {
                      final pId = post['id'] is int ? post['id'] : (int.tryParse(post['id'].toString()) ?? 0);
                      if (val == 'edit') {
                        _showEditPostDialog(context, post, isBn);
                      } else if (val == 'delete') {
                        _confirmDeletePost(context, pId, isBn);
                      } else if (val == 'report') {
                        _showReportPostDialog(context, post, isBn);
                      }
                    },
                    itemBuilder: (ctx) {
                      if (isOwner) {
                        return [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(isBn ? 'সম্পাদনা করুন' : 'Edit Post', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Text(isBn ? 'মুছে ফেলুন' : 'Delete Post', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ];
                      } else {
                        return [
                          PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                const Icon(Icons.flag_outlined, color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Text(isBn ? 'রিপোর্ট করুন' : 'Report Post', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ];
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Edit Post Dialog
  void _showEditPostDialog(BuildContext context, Map<String, dynamic> post, bool isBn) {
    final controller = TextEditingController(text: post['content'] ?? '');
    String selectedTag = post['tag'] ?? 'Support';
    bool isAnonymous = post['is_anonymous'] ?? true;
    bool isSubmitting = false;
    final int pId = post['id'] is int ? post['id'] : (int.tryParse(post['id'].toString()) ?? 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 20,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.textSecondaryLight, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isBn ? 'পোস্ট সম্পাদনা করুন' : 'Edit Community Post',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedTag,
                    decoration: InputDecoration(
                      labelText: isBn ? 'ট্যাগ নির্বাচন করুন' : 'Select Category Tag',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Success Story', 'Question', 'Support'].map((t) {
                      return DropdownMenuItem(value: t, child: Text(t));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedTag = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: isBn ? 'আপনার পোস্ট আপডেট করুন...' : 'Update your post content...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.purple.shade100),
                    ),
                    child: SwitchListTile(
                      secondary: Icon(
                        isAnonymous ? Icons.security_rounded : Icons.person_rounded,
                        color: isAnonymous ? const Color(0xFFA855F7) : AppColors.primary,
                      ),
                      title: Text(
                        isBn ? 'পরিচয় গোপন রাখুন (Anonymous)' : 'Post Anonymously',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      activeColor: const Color(0xFFA855F7),
                      value: isAnonymous,
                      onChanged: (val) => setModalState(() => isAnonymous = val),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;
                            setModalState(() => isSubmitting = true);
                            await _editPost(pId, text, selectedTag, isAnonymous);
                            if (mounted) Navigator.pop(context);
                          },
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            isBn ? 'সংরক্ষণ করুন' : 'Save Changes',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Report Post Dialog
  void _showReportPostDialog(BuildContext context, Map<String, dynamic> post, bool isBn) {
    String selectedReason = 'Inappropriate content';
    final customReasonCtrl = TextEditingController();
    bool isSubmitting = false;
    final int pId = post['id'] is int ? post['id'] : (int.tryParse(post['id'].toString()) ?? 0);

    final List<String> reasons = [
      'Inappropriate content',
      'Harassment or Hate speech',
      'Spam or Scam',
      'Self-harm or Crisis concern',
      'Misleading medical info',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Colors.orange, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    isBn ? 'পোস্ট রিপোর্ট করুন' : 'Report Post',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn
                          ? 'এই পোস্টটিতে কি কোনো সমস্যা রয়েছে? অনুগ্রহ করে কারণ উল্লেখ করুন:'
                          : 'Why are you reporting this post? Our moderation team will investigate:',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 14),
                    ...reasons.map((r) {
                      return RadioListTile<String>(
                        value: r,
                        groupValue: selectedReason,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(r, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        activeColor: Colors.orange,
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedReason = val);
                        },
                      );
                    }),
                    if (selectedReason == 'Other') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customReasonCtrl,
                        decoration: InputDecoration(
                          hintText: isBn ? 'বিস্তারিত লিখুন...' : 'Describe the violation...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(isBn ? 'বাতিল' : 'Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          final reasonToSend = selectedReason == 'Other' && customReasonCtrl.text.trim().isNotEmpty
                              ? customReasonCtrl.text.trim()
                              : selectedReason;
                          await _reportPost(pId, reasonToSend);
                          if (mounted) Navigator.pop(ctx);
                        },
                  child: isSubmitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isBn ? 'রিপোর্ট পাঠান' : 'Submit Report', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Create Post Dialog
  void _showAddPostDialog(BuildContext context, bool isBn) {
    final controller = TextEditingController();
    String selectedTag = 'Support';
    bool isAnonymous = true;
    bool isSubmitting = false;

    final authUser = Provider.of<AuthProvider>(context, listen: false).currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 20,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.textSecondaryLight, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isBn ? 'কমিউনিটিতে নতুন পোস্ট করুন' : 'Create Community Post',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedTag,
                    decoration: InputDecoration(
                      labelText: isBn ? 'ট্যাগ নির্বাচন করুন' : 'Select Category Tag',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Success Story', 'Question', 'Support'].map((t) {
                      return DropdownMenuItem(value: t, child: Text(t));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedTag = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: isBn ? 'আপনার অনুভূতি, প্রশ্ন বা অভিজ্ঞতা শেয়ার করুন...' : 'Share your feelings, questions or story...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.purple.shade100),
                    ),
                    child: SwitchListTile(
                      secondary: Icon(
                        isAnonymous ? Icons.security_rounded : Icons.person_rounded,
                        color: isAnonymous ? const Color(0xFFA855F7) : AppColors.primary,
                      ),
                      title: Text(
                        isBn ? 'পরিচয় গোপন রাখুন (Anonymous)' : 'Post Anonymously',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        isAnonymous
                            ? (isBn ? 'পোস্টে আপনার আসল নাম প্রকাশ পাবে না' : 'Your real name will be hidden')
                            : (isBn ? 'পোস্টে আপনার আসল নাম দেখানো হবে' : 'Your account name will be visible'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      activeColor: const Color(0xFFA855F7),
                      value: isAnonymous,
                      onChanged: (val) => setModalState(() => isAnonymous = val),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;

                            setModalState(() => isSubmitting = true);

                            final newPostMap = {
                              'id': DateTime.now().millisecondsSinceEpoch,
                              'author_alias': isAnonymous
                                  ? (isBn ? 'বেনামী ব্যবহারকারী' : 'Anonymous Member')
                                  : (authUser != null && authUser.firstName.isNotEmpty ? '${authUser.firstName} ${authUser.lastName}'.trim() : 'User'),
                              'is_anonymous': isAnonymous,
                              'tag': selectedTag,
                              'content': text,
                              'likes_count': 0,
                              'comments_count': 0,
                              'is_liked': false,
                              'created_at': 'Just now',
                              'comments': [],
                            };

                            try {
                              final res = await ApiService.post(
                                ApiEndpoints.posts,
                                {
                                  'content': text,
                                  'tag': selectedTag,
                                  'is_anonymous': isAnonymous,
                                },
                                requireAuth: true,
                              );
                              if (res is Map && res.containsKey('id')) {
                                newPostMap['id'] = res['id'];
                              }
                            } catch (_) {}

                            _sharedCommunityDb.insert(0, newPostMap);
                            await _savePostsToStorage();

                            if (mounted) {
                              Navigator.pop(context);
                              _fetchPosts();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isBn ? 'পোস্টটি কমিউনিটিতে সফলভাবে প্রকাশিত হয়েছে!' : 'Post published to community!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            isBn ? 'পাবলিশ করুন' : 'Publish Post',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Comments Sheet - Fetched Live from Backend
  void _showCommentsSheet(BuildContext context, Map<String, dynamic> post, bool isBn) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final bool isSpecialist = user != null && (user.role.toUpperCase() == 'SPECIALIST' || user.role.toUpperCase() == 'DOCTOR' || user.role.toUpperCase() == 'ADMIN');

    final commentCtrl = TextEditingController();
    List<dynamic> comments = List.from(post['comments'] ?? []);
    bool isPosting = false;
    bool isFetchingLive = true;

    final int postId = post['id'] is int ? post['id'] : (int.tryParse(post['id'].toString()) ?? 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (isFetchingLive && postId > 0) {
              ApiService.getList('${ApiEndpoints.baseUrl}/community/posts/', requireAuth: false).then((data) {
                if (data.isNotEmpty) {
                  final target = data.firstWhere((p) => p['id'] == postId, orElse: () => null);
                  if (target != null && target['comments'] != null) {
                    setSheetState(() {
                      comments = List.from(target['comments']);
                      isFetchingLive = false;
                    });
                  }
                }
              }).catchError((_) {
                setSheetState(() => isFetchingLive = false);
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.textSecondaryLight, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        isBn ? 'বিশেষজ্ঞদের মতামত ও উত্তর' : 'Specialist Responses',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: comments.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                isBn ? 'এখনো কোনো বিশেষজ্ঞ কমেন্ট করেননি।' : 'No specialist responses yet.',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: comments.length,
                            itemBuilder: (context, idx) {
                              final c = comments[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          c['author_alias'] ?? 'Specialist Doctor',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _formatCreatedAt(c['created_at']),
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      c['content'] ?? '',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.4),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),

                  if (isSpecialist) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentCtrl,
                            decoration: InputDecoration(
                              hintText: isBn ? 'বিশেষজ্ঞ হিসেবে মতামত বা পরামর্শ লিখুন...' : 'Write expert medical guidance...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: isPosting
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send_rounded, color: AppColors.primary),
                          onPressed: isPosting
                              ? null
                              : () async {
                                  final text = commentCtrl.text.trim();
                                  if (text.isEmpty) return;

                                  setSheetState(() => isPosting = true);

                                  final newComment = {
                                    'id': DateTime.now().millisecondsSinceEpoch,
                                    'author_alias': user != null && user.firstName.isNotEmpty
                                        ? 'Dr. ${user.firstName} ${user.lastName} (Specialist)'
                                        : 'Dr. Mekhala Sarkar (Specialist)',
                                    'content': text,
                                    'created_at': 'Just now',
                                  };

                                  try {
                                    final res = await ApiService.post(
                                      '${ApiEndpoints.baseUrl}/community/posts/${post['id']}/comments/',
                                      {
                                        'content': text,
                                      },
                                      requireAuth: true,
                                    );
                                    if (res is Map && res.containsKey('id')) {
                                      newComment['id'] = res['id'];
                                    }
                                  } catch (_) {}

                                  final targetIdx = _sharedCommunityDb.indexWhere((p) => p['id'] == post['id']);
                                  if (targetIdx != -1) {
                                    _sharedCommunityDb[targetIdx]['comments'] = _sharedCommunityDb[targetIdx]['comments'] ?? [];
                                    (_sharedCommunityDb[targetIdx]['comments'] as List).add(newComment);
                                    _sharedCommunityDb[targetIdx]['comments_count'] = ((_sharedCommunityDb[targetIdx]['comments_count'] ?? 0) as int) + 1;
                                    await _savePostsToStorage();
                                  }

                                  setSheetState(() {
                                    if (targetIdx != -1) {
                                      comments = List.from(_sharedCommunityDb[targetIdx]['comments']);
                                    } else {
                                      comments.add(newComment);
                                    }
                                    commentCtrl.clear();
                                    isPosting = false;
                                  });

                                  _fetchPosts();
                                },
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isBn
                                  ? 'সঠিক মানসিক স্বাস্থ্য পরামর্শ নিশ্চিতে শুধুমাত্র সার্টিফাইড বিশেষজ্ঞরা কমেন্ট করতে পারেন। সাধারণ ব্যবহারকারীরা শুধু পরামর্শ পড়তে পারবেন।'
                                  : 'Only verified mental health specialists can respond to ensure professional guidance. Members can read all expert advice above.',
                              style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.3),
                            ),
                          ),
                        ],
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
}
