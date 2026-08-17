class MoodModel {
  final int id;
  final String mood;
  final String note;
  final String createdAt;

  MoodModel({
    required this.id,
    required this.mood,
    required this.note,
    required this.createdAt,
  });

  factory MoodModel.fromJson(Map<String, dynamic> json) {
    return MoodModel(
      id: json['id'] ?? 0,
      mood: json['mood'] ?? 'happy',
      note: json['note'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
