import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthStorageService {
  static const _sessionTokenKey = 'session_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userDisplayNameKey = 'user_display_name';
  static const _phoneNumberKey = 'phone_number';
  static const _genderKey = 'gender';
  static const _dobKey = 'dob';
  static const _firstNameKey = 'first_name';
  static const _middleNameKey = 'middle_name';
  static const _lastNameKey = 'last_name';
  static const _bioKey = 'bio';
  static const _usernameKey = 'username';
  static const _categoryKey = 'category';
  static const _socialLinksKey = 'social_links_json';

  Future<void> saveSession({
    required String sessionToken,
    required String refreshToken,
    String? userId,
    String? displayName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionTokenKey, sessionToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_userIdKey, userId);
    } else {
      await prefs.remove(_userIdKey);
    }
    if (displayName != null && displayName.trim().isNotEmpty) {
      await prefs.setString(_userDisplayNameKey, displayName.trim());
    } else {
      await prefs.remove(_userDisplayNameKey);
    }
  }

  Future<void> updateSessionTokens({
    required String sessionToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionTokenKey, sessionToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<String?> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<String?> getUserDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userDisplayNameKey);
  }

  Future<void> saveProfileDetails({
    String? displayName,
    String? firstName,
    String? middleName,
    String? lastName,
    String? phoneNumber,
    String? gender,
    String? dob,
    String? bio,
    String? username,
    String? category,
    List<Map<String, dynamic>>? socialLinks,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    Future<void> saveOrRemove(String key, String? value) async {
      if (value != null && value.trim().isNotEmpty) {
        await prefs.setString(key, value.trim());
      } else {
        await prefs.remove(key);
      }
    }

    await saveOrRemove(_userDisplayNameKey, displayName);
    await saveOrRemove(_firstNameKey, firstName);
    await saveOrRemove(_middleNameKey, middleName);
    await saveOrRemove(_lastNameKey, lastName);
    await saveOrRemove(_phoneNumberKey, phoneNumber);
    await saveOrRemove(_genderKey, gender);
    await saveOrRemove(_dobKey, dob);
    await saveOrRemove(_bioKey, bio);
    await saveOrRemove(_usernameKey, username);
    await saveOrRemove(_categoryKey, category);
    if (socialLinks != null && socialLinks.isNotEmpty) {
      await prefs.setString(_socialLinksKey, jsonEncode(socialLinks));
    } else if (socialLinks != null) {
      await prefs.remove(_socialLinksKey);
    }
  }

  Future<StoredProfileDetails?> getProfileDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final displayName = prefs.getString(_userDisplayNameKey);
    final firstName = prefs.getString(_firstNameKey);
    final middleName = prefs.getString(_middleNameKey);
    final lastName = prefs.getString(_lastNameKey);
    final phoneNumber = prefs.getString(_phoneNumberKey);
    final gender = prefs.getString(_genderKey);
    final dob = prefs.getString(_dobKey);
    final bio = prefs.getString(_bioKey);
    final username = prefs.getString(_usernameKey);
    final category = prefs.getString(_categoryKey);
    final socialLinksRaw = prefs.getString(_socialLinksKey);
    List<Map<String, dynamic>>? socialLinks;
    if (socialLinksRaw != null && socialLinksRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(socialLinksRaw);
        if (decoded is List) {
          socialLinks = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        } else if (decoded is Map) {
          socialLinks = [Map<String, dynamic>.from(decoded)];
        }
      } catch (_) {}
    }

    if ([
      displayName,
      firstName,
      middleName,
      lastName,
      phoneNumber,
      gender,
      dob,
      bio,
      username,
      category,
      socialLinksRaw,
    ].every((value) => value == null || value.isEmpty)) {
      return null;
    }

    return StoredProfileDetails(
      displayName: displayName,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      gender: gender,
      dob: dob,
      bio: bio,
      username: username,
      category: category,
      socialLinks: socialLinks,
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userDisplayNameKey);
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_genderKey);
    await prefs.remove(_dobKey);
    await prefs.remove(_firstNameKey);
    await prefs.remove(_middleNameKey);
    await prefs.remove(_lastNameKey);
    await prefs.remove(_bioKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_categoryKey);
    await prefs.remove(_socialLinksKey);
  }
}

class StoredProfileDetails {
  const StoredProfileDetails({
    this.displayName,
    this.firstName,
    this.middleName,
    this.lastName,
    this.phoneNumber,
    this.gender,
    this.dob,
    this.bio,
    this.username,
    this.category,
    this.socialLinks,
  });

  final String? displayName;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? phoneNumber;
  final String? gender;
  final String? dob;
  final String? bio;
  final String? username;
  final String? category;
  final List<Map<String, dynamic>>? socialLinks;
}
