import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_models.dart';
import '../models/timetable_models.dart';
import '../models/syllabus_models.dart';
import '../models/cached_data.dart';
import '../models/event_models.dart';

class AppStateNotifier extends ChangeNotifier {
  CachedData<List<AttendanceSummary>>? _attendanceSummary;
  CachedData<List<TimetableSubject>>? _timetableSubjects;
  CachedData<UserProfile?>? _userProfile;
  CachedData<List<SavedSubject>>? _savedSubjects;
  CachedData<List<EventItem>>? _events;

  static const attendanceTtl = Duration(minutes: 5);
  static const timetableTtl = Duration(hours: 1);
  static const eventsTtl = Duration(minutes: 30);
  static const userProfileTtl = Duration(hours: 24);
  static const savedSubjectsTtl = Duration(hours: 1);

  // Cache Prefs Keys
  static const _profileKey = 'cache_user_profile';
  static const _attendanceKey = 'cache_attendance_summary';
  static const _timetableKey = 'cache_timetable_subjects';
  static const _savedSubjectsKey = 'cache_saved_subjects';
  static const _eventsKey = 'cache_events';

  // Hydration from local storage
  Future<void> loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. User Profile
      final profileStr = prefs.getString(_profileKey);
      if (profileStr != null) {
        try {
          final data = UserProfile.fromJson(
              jsonDecode(profileStr) as Map<String, dynamic>);
          _userProfile = CachedData(data: data, ttl: userProfileTtl);
        } catch (_) {}
      }

      // 2. Attendance Summary
      final attendanceStr = prefs.getString(_attendanceKey);
      if (attendanceStr != null) {
        try {
          final rawList = jsonDecode(attendanceStr) as List<dynamic>;
          final list = rawList
              .map((item) =>
                  AttendanceSummary.fromJson(item as Map<String, dynamic>))
              .toList();
          _attendanceSummary = CachedData(data: list, ttl: attendanceTtl);
        } catch (_) {}
      }

      // 3. Timetable Subjects
      final timetableStr = prefs.getString(_timetableKey);
      if (timetableStr != null) {
        try {
          final rawList = jsonDecode(timetableStr) as List<dynamic>;
          final list = rawList
              .map((item) =>
                  TimetableSubject.fromJson(item as Map<String, dynamic>))
              .toList();
          _timetableSubjects = CachedData(data: list, ttl: timetableTtl);
        } catch (_) {}
      }

      // 4. Saved Subjects
      final savedStr = prefs.getString(_savedSubjectsKey);
      if (savedStr != null) {
        try {
          final rawList = jsonDecode(savedStr) as List<dynamic>;
          final list = rawList
              .map((item) => SavedSubject.fromJson(item as Map<String, dynamic>))
              .toList();
          _savedSubjects = CachedData(data: list, ttl: savedSubjectsTtl);
        } catch (_) {}
      }

      // 5. Events
      final eventsStr = prefs.getString(_eventsKey);
      if (eventsStr != null) {
        try {
          final rawList = jsonDecode(eventsStr) as List<dynamic>;
          final list = rawList
              .map((item) => EventItem.fromJson(item as Map<String, dynamic>))
              .toList();
          _events = CachedData(data: list, ttl: eventsTtl);
        } catch (_) {}
      }

      notifyListeners();
    } catch (_) {}
  }

  // Getters
  List<AttendanceSummary>? get attendanceSummary {
    if (_attendanceSummary?.isValid ?? false) {
      return _attendanceSummary!.data;
    }
    return null;
  }

  List<TimetableSubject>? get timetableSubjects {
    if (_timetableSubjects?.isValid ?? false) {
      return _timetableSubjects!.data;
    }
    return null;
  }

  UserProfile? get userProfile {
    if (_userProfile?.isValid ?? false) {
      return _userProfile!.data;
    }
    return null;
  }

  List<SavedSubject>? get savedSubjects {
    if (_savedSubjects?.isValid ?? false) {
      return _savedSubjects!.data;
    }
    return null;
  }

  List<EventItem>? get events {
    if (_events?.isValid ?? false) {
      return _events!.data;
    }
    return null;
  }

  // True once profile + attendance + timetable are all within their TTLs —
  // lets callers skip re-hitting /auth/sync when the cache is still good.
  bool get hasFreshHomeData =>
      (_userProfile?.isValid ?? false) &&
      (_attendanceSummary?.isValid ?? false) &&
      (_timetableSubjects?.isValid ?? false);

  // Setters
  void setAttendanceSummary(List<AttendanceSummary> data) {
    _attendanceSummary = CachedData(data: data, ttl: attendanceTtl);
    notifyListeners();
    _saveToPrefs(_attendanceKey,
        jsonEncode(data.map((item) => item.toJson()).toList()));
  }

  void setTimetableSubjects(List<TimetableSubject> data) {
    _timetableSubjects = CachedData(data: data, ttl: timetableTtl);
    notifyListeners();
    _saveToPrefs(_timetableKey,
        jsonEncode(data.map((item) => item.toJson()).toList()));
  }

  void setUserProfile(UserProfile? data) {
    _userProfile = CachedData(data: data, ttl: userProfileTtl);
    notifyListeners();
    if (data != null) {
      _saveToPrefs(_profileKey, jsonEncode(data.toJson()));
    } else {
      _removeFromPrefs(_profileKey);
    }
  }

  void setSavedSubjects(List<SavedSubject> data) {
    _savedSubjects = CachedData(data: data, ttl: savedSubjectsTtl);
    notifyListeners();
    _saveToPrefs(_savedSubjectsKey,
        jsonEncode(data.map((item) => item.toJson()).toList()));
  }

  void setEvents(List<EventItem> data) {
    _events = CachedData(data: data, ttl: eventsTtl);
    notifyListeners();
    _saveToPrefs(
        _eventsKey, jsonEncode(data.map((item) => item.toJson()).toList()));
  }

  // Invalidation
  void invalidateAttendanceSummary() {
    _attendanceSummary = null;
    notifyListeners();
    _removeFromPrefs(_attendanceKey);
  }

  void invalidateTimetableSubjects() {
    _timetableSubjects = null;
    notifyListeners();
    _removeFromPrefs(_timetableKey);
  }

  void invalidateUserProfile() {
    _userProfile = null;
    notifyListeners();
    _removeFromPrefs(_profileKey);
  }

  void invalidateSavedSubjects() {
    _savedSubjects = null;
    notifyListeners();
    _removeFromPrefs(_savedSubjectsKey);
  }

  void invalidateEvents() {
    _events = null;
    notifyListeners();
    _removeFromPrefs(_eventsKey);
  }

  void invalidateAll() {
    _attendanceSummary = null;
    _timetableSubjects = null;
    _userProfile = null;
    _savedSubjects = null;
    _events = null;
    notifyListeners();
    _clearAllCachePrefs();
  }

  // Preferences helpers
  Future<void> _saveToPrefs(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  Future<void> _removeFromPrefs(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }

  Future<void> _clearAllCachePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
      await prefs.remove(_attendanceKey);
      await prefs.remove(_timetableKey);
      await prefs.remove(_savedSubjectsKey);
      await prefs.remove(_eventsKey);
      
      // Also clear all curriculum keys
      final keys = prefs.getKeys();
      final curriculumKeys =
          keys.where((key) => key.startsWith('curriculum_')).toList();
      for (final key in curriculumKeys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
