/// User profile data model
class AppUser {
  final String username;
  final String displayName;
  final String phone;
  String language;
  String state;
  final String loginTime;

  AppUser({
    required this.username,
    required this.displayName,
    this.phone = '',
    this.language = 'en',
    this.state = '',
    required this.loginTime,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    username: json['username'] ?? '',
    displayName: json['display_name'] ?? json['displayName'] ?? '',
    phone: json['phone'] ?? '',
    language: json['language'] ?? 'en',
    state: json['state'] ?? '',
    loginTime: json['login_time'] ?? json['loginTime'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'username': username,
    'display_name': displayName,
    'phone': phone,
    'language': language,
    'state': state,
    'login_time': loginTime,
  };
}
