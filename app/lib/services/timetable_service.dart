import 'dart:convert';
import 'dart:typed_data';

import '../models/timetable_models.dart';
import 'attendance_notification_service.dart';
import 'api_service.dart';

class TimetableService {
  Future<TimetableSubject> scanTimetableImage(Uint8List bytes) async {
    final json = await ApiService.instance.post('/timetable/parse', {
      'imageBase64': base64Encode(bytes),
    }) as Map<String, dynamic>;

    final subjectsJson = json['subjects'] as List<dynamic>? ?? [];
    if (subjectsJson.isEmpty) {
      throw ApiException(
          422, 'Could not extract subjects from this timetable.');
    }

    final subjects = subjectsJson
        .map((item) => TimetableSubject.fromJson(item as Map<String, dynamic>))
        .toList();
    await saveSubjects(subjects);
    return subjects.first;
  }

  static Future<TimetableData>? _timetableFuture;

  Future<List<TimetableSubject>> getAllSubjects() async {
    final timetable = await getTimetable();
    return timetable.subjects;
  }

  Future<TimetableData> getTimetable() {
    _timetableFuture ??= _fetchTimetable();
    return _timetableFuture!;
  }

  Future<TimetableData> _fetchTimetable() async {
    try {
      final json =
          await ApiService.instance.get('/timetable') as Map<String, dynamic>;
      return TimetableData.fromJson(json);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return TimetableData(subjects: []);
      _timetableFuture = null;
      rethrow;
    } catch (_) {
      _timetableFuture = null;
      rethrow;
    }
  }

  Future<void> saveSubjects(List<TimetableSubject> subjects) async {
    await ApiService.instance.post('/timetable', {
      'subjects': subjects.map((subject) => subject.toJson()).toList(),
    });
    _timetableFuture = null;
    await AttendanceNotificationService.instance.scheduleForTimetable(subjects);
  }

  Future<List<TimetableClass>> getClassesForDay(
    String subjectId,
    String day,
  ) async {
    final subject = await getSubjectById(subjectId);
    return subject.classes.where((c) => c.day == day).toList();
  }

  Future<TimetableSubject> getSubjectById(String id) async {
    final subjects = await getAllSubjects();
    return subjects.firstWhere(
      (s) => s.id == id,
      orElse: () => subjects.first,
    );
  }
}
