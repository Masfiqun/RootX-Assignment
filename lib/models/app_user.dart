class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
      };

  static AppUser fromMap(String uid, Map<String, dynamic>? data) {
    final d = data ?? {};
    return AppUser(
      uid: uid,
      email: d['email'],
      displayName: d['displayName'],
      photoUrl: d['photoUrl'],
    );
  }
}