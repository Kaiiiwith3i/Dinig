import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/citizen_profile.dart';

class PreferencesService {
  static const String _profileKey = 'dinig_citizen_profile';
  static const String _listeningKey = 'dinig_listening_on';

  static Future<CitizenProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_profileKey);
    if (jsonStr != null) {
      try {
        return CitizenProfile.fromJson(jsonDecode(jsonStr));
      } catch (_) {}
    }
    return const CitizenProfile();
  }

  static Future<void> saveProfile(CitizenProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  static Future<bool> isListeningOn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_listeningKey) ?? false;
  }

  static Future<void> setListeningOn(bool on) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_listeningKey, on);
  }
}
