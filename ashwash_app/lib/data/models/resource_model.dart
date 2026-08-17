class ResourceModel {
  final int id;
  final String titleEn;
  final String titleBn;
  final String summaryEn;
  final String summaryBn;
  final String resourceType;
  final int durationMinutes;
  final bool isPremium;

  ResourceModel({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.summaryEn,
    required this.summaryBn,
    required this.resourceType,
    required this.durationMinutes,
    required this.isPremium,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] ?? 0,
      titleEn: json['title_en'] ?? '',
      titleBn: json['title_bn'] ?? '',
      summaryEn: json['summary_en'] ?? '',
      summaryBn: json['summary_bn'] ?? '',
      resourceType: json['resource_type'] ?? 'article',
      durationMinutes: json['duration_minutes'] ?? 10,
      isPremium: json['is_premium'] ?? false,
    );
  }
}
