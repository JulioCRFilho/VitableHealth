class UserProfile {
  final String id;
  final String name;
  final String email;
  final String planId;
  final String status;
  final String? profilePictureUrl;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.planId,
    required this.status,
    this.profilePictureUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      planId: map['plan_id'] ?? '',
      status: map['status'] ?? 'active',
      profilePictureUrl: map['profile_picture_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'plan_id': planId,
      'status': status,
      'profile_picture_url': profilePictureUrl,
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? planId,
    String? status,
    String? profilePictureUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}
