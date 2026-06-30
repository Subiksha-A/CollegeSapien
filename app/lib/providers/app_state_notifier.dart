import 'package:flutter/foundation.dart';
import '../models/api_models.dart';
import '../models/timetable_models.dart';
import '../models/syllabus_models.dart';
import '../models/cached_data.dart';
import '../screens/home/home_screen.dart';

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

  // Setters
  void setAttendanceSummary(List<AttendanceSummary> data) {
    _attendanceSummary = CachedData(data: data, ttl: attendanceTtl);
    notifyListeners();
  }

  void setTimetableSubjects(List<TimetableSubject> data) {
    _timetableSubjects = CachedData(data: data, ttl: timetableTtl);
    notifyListeners();
  }

  void setUserProfile(UserProfile? data) {
    _userProfile = CachedData(data: data, ttl: userProfileTtl);
    notifyListeners();
  }

  void setSavedSubjects(List<SavedSubject> data) {
    _savedSubjects = CachedData(data: data, ttl: savedSubjectsTtl);
    notifyListeners();
  }

  void setEvents(List<EventItem> data) {
    _events = CachedData(data: data, ttl: eventsTtl);
    notifyListeners();
  }

  // Invalidation
  void invalidateAttendanceSummary() {
    _attendanceSummary = null;
    notifyListeners();
  }

  void invalidateTimetableSubjects() {
    _timetableSubjects = null;
    notifyListeners();
  }

  void invalidateUserProfile() {
    _userProfile = null;
    notifyListeners();
  }

  void invalidateSavedSubjects() {
    _savedSubjects = null;
    notifyListeners();
  }

  void invalidateEvents() {
    _events = null;
    notifyListeners();
  }

  void invalidateAll() {
    _attendanceSummary = null;
    _timetableSubjects = null;
    _userProfile = null;
    _savedSubjects = null;
    _events = null;
    notifyListeners();
  }
}
