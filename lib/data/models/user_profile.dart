class UserProfile {
  final String name;
  final String avatarColorHex; // Guardaremos un color si elige avatar default
  final List<String> preferredGenres;
  final bool hasCompletedOnboarding;

  UserProfile({
    required this.name,
    required this.avatarColorHex,
    required this.preferredGenres,
    this.hasCompletedOnboarding = false,
  });

  factory UserProfile.empty() {
    return UserProfile(
      name: '',
      avatarColorHex: '#00FFFF', // Cyan por defecto
      preferredGenres: [],
      hasCompletedOnboarding: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatarColorHex': avatarColorHex,
      'preferredGenres': preferredGenres,
      'hasCompletedOnboarding': hasCompletedOnboarding,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      avatarColorHex: json['avatarColorHex'] as String? ?? '#00FFFF',
      preferredGenres: (json['preferredGenres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
    );
  }

  UserProfile copyWith({
    String? name,
    String? avatarColorHex,
    List<String>? preferredGenres,
    bool? hasCompletedOnboarding,
  }) {
    return UserProfile(
      name: name ?? this.name,
      avatarColorHex: avatarColorHex ?? this.avatarColorHex,
      preferredGenres: preferredGenres ?? this.preferredGenres,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}
