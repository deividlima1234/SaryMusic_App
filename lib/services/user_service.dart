import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_profile.dart';

final userServiceProvider = Provider((ref) => UserService());
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier(ref.read(userServiceProvider));
});

class UserService {
  static const _key = 'user_profile';

  Future<UserProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) {
      return UserProfile.empty();
    }
    try {
      return UserProfile.fromJson(jsonDecode(data));
    } catch (_) {
      return UserProfile.empty();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final UserService _service;

  UserProfileNotifier(this._service) : super(UserProfile.empty()) {
    _load();
  }

  Future<void> _load() async {
    state = await _service.getProfile();
  }

  Future<void> saveProfile(UserProfile newProfile) async {
    await _service.saveProfile(newProfile);
    state = newProfile;
  }

  Future<void> completeOnboarding(
      String name, String avatarColorHex, List<String> genres) async {
    final profile = UserProfile(
      name: name,
      avatarColorHex: avatarColorHex,
      preferredGenres: genres,
      hasCompletedOnboarding: true,
    );
    await saveProfile(profile);
  }

  Future<void> resetProfile() async {
    await _service.clearProfile();
    state = UserProfile.empty();
  }
}
