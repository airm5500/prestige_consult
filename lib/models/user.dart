class User {
  final String userId;
  final String login;
  final String firstName;
  final String lastName;
  final String officineName;

  User({
    required this.userId,
    required this.login,
    required this.firstName,
    required this.lastName,
    required this.officineName,
  });

  // 'factory constructor' pour créer une instance de User depuis un JSON (Map)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['str_USER_ID'] ?? '',
      login: json['str_LOGIN'] ?? '',
      firstName: json['str_FIRST_NAME'] ?? '',
      lastName: json['str_LAST_NAME'] ?? '',
      officineName: json['OFFICINE'] ?? 'N/A',
    );
  }

  // Getter pour le nom complet de l'utilisateur
  String get fullName => '$firstName $lastName';
}