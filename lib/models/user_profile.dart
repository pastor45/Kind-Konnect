class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? photoURL;
  final String? bio;
  final List<String>? skills;
  final List<String>? interests;
  int points;
  List<String> badges;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoURL,
    this.bio,
    this.skills,
    this.interests,
    this.points = 0,
    this.badges = const [],
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'],
      name: data['name'],
      email: data['email'],
      photoURL: data['photoURL'],
      bio: data['bio'],
      skills: List<String>.from(data['skills'] ?? []),
      interests: List<String>.from(data['interests'] ?? []),
      points: data['points'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoURL': photoURL,
      'bio': bio,
      'skills': skills,
      'interests': interests,
      'points': points,
      'badges': badges,
    };
  }
}
