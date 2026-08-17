class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phone;
  final int totalPoints;
  final int sessionsAttended;
  final int tasksCompleted;
  final String? avatar;
  final String? bio;
  final String? preferredCategory;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role = 'PATIENT',
    this.phone,
    this.totalPoints = 0,
    this.sessionsAttended = 0,
    this.tasksCompleted = 0,
    this.avatar,
    this.bio,
    this.preferredCategory = 'First Time Mother',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? profilePic = json['avatar'] ?? json['profile_picture'];
    if ((profilePic == null || profilePic.isEmpty) && json['preferences'] is Map) {
      profilePic = json['preferences']['profile_picture_base64'];
    }

    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? 'PATIENT',
      phone: json['phone_number'] ?? json['phone'],
      totalPoints: json['total_points'] ?? 0,
      sessionsAttended: json['sessions_attended'] ?? 0,
      tasksCompleted: json['tasks_completed'] ?? 0,
      avatar: profilePic,
      bio: json['bio'],
      preferredCategory: json['category'] ?? json['preferred_category'] ?? 'First Time Mother',
    );
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? phone,
    int? totalPoints,
    int? sessionsAttended,
    int? tasksCompleted,
    String? avatar,
    String? bio,
    String? preferredCategory,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      totalPoints: totalPoints ?? this.totalPoints,
      sessionsAttended: sessionsAttended ?? this.sessionsAttended,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      preferredCategory: preferredCategory ?? this.preferredCategory,
    );
  }
}
