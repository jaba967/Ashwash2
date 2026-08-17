class PostModel {
  final int id;
  final String authorAlias;
  final String content;
  final String tag;
  final bool isAnonymous;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final String createdAt;

  PostModel({
    required this.id,
    required this.authorAlias,
    required this.content,
    required this.tag,
    required this.isAnonymous,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? 0,
      authorAlias: json['author_alias'] ?? 'Anonymous',
      content: json['content'] ?? '',
      tag: json['tag'] ?? 'Support',
      isAnonymous: json['is_anonymous'] ?? true,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}
