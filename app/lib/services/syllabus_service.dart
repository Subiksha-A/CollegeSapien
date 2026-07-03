import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/syllabus_models.dart';
import 'api_service.dart';

class SyllabusService {
  Future<CurriculumBundle> getCurriculum({
    required String collegeCode,
    required String courseCode,
    String? regulation,
  }) async {
    final cacheKey =
        'curriculum_${collegeCode}_${courseCode}_${regulation ?? 'latest'}';
    final timestampKey = '${cacheKey}_timestamp';
    final prefs = await SharedPreferences.getInstance();

    final cachedJson = prefs.getString(cacheKey);
    final cachedTimestamp = prefs.getString(timestampKey);

    if (cachedJson != null && cachedTimestamp != null) {
      try {
        final cachedTime = DateTime.parse(cachedTimestamp);
        final difference = DateTime.now().difference(cachedTime);
        if (difference.inDays < 1) {
          return CurriculumBundle.fromJson(
              jsonDecode(cachedJson) as Map<String, dynamic>);
        }
      } catch (_) {
        // Ignore parse errors and fetch fresh data
      }
    }

    try {
      final query = StringBuffer(
          '/curriculum?collegeCode=$collegeCode&courseCode=$courseCode');
      if (regulation != null) query.write('&regulation=$regulation');

      final json =
          await ApiService.instance.get(query.toString()) as Map<String, dynamic>;
      await prefs.setString(cacheKey, jsonEncode(json));
      await prefs.setString(timestampKey, DateTime.now().toIso8601String());
      return CurriculumBundle.fromJson(json);
    } catch (e) {
      if (cachedJson != null) {
        return CurriculumBundle.fromJson(
            jsonDecode(cachedJson) as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final curriculumKeys =
        keys.where((key) => key.startsWith('curriculum_')).toList();
    for (final key in curriculumKeys) {
      await prefs.remove(key);
    }
  }

  List<CurriculumSubject> getSubjectsForSemester(
    CurriculumBundle bundle, {
    required int semester,
  }) {
    return bundle.subjects
        .where((s) => s.effectiveSemester == semester && !s.isOption)
        .toList();
  }

  List<CurriculumSubject> getElectiveOptions(
    CurriculumBundle bundle, {
    required String electiveType,
  }) {
    return bundle.subjects
        .where((s) => s.isOption && s.electiveType == electiveType)
        .toList();
  }

  Future<SavedSyllabus?> getSavedSyllabus(int semester) async {
    try {
      final json = await ApiService.instance
          .get('/syllabus/subjects/$semester') as Map<String, dynamic>;
      return SavedSyllabus.fromJsonOrNull(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<SavedSubject>?> getSavedSubjects(int semester) async {
    final saved = await getSavedSyllabus(semester);
    return saved?.subjects;
  }

  Future<void> saveSubjects({
    required int semester,
    required String regulation,
    required List<SavedSubject> subjects,
  }) async {
    await ApiService.instance.post('/syllabus/subjects', {
      'semester': semester,
      'regulation': regulation,
      'subjects': subjects.map((s) => s.toJson()).toList(),
    });
  }
}
