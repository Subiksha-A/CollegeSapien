import '../data/curriculum_data.dart';
import '../models/syllabus_models.dart';
import 'api_service.dart';

class SyllabusService {
  List<CurriculumSubject> getSubjectsForSemester({
    required String collegeCode,
    required String courseCode,
    required String regulation,
    required int semester,
  }) {
    return curriculumData
        .map((json) => CurriculumSubject.fromJson(json))
        .where((s) =>
            s.collegeCode == collegeCode &&
            s.courseCode == courseCode &&
            s.regulation == regulation &&
            s.effectiveSemester == semester &&
            !s.isOption)
        .toList();
  }

  List<CurriculumSubject> getElectiveOptions({
    required String collegeCode,
    required String courseCode,
    required String regulation,
    required String electiveType,
  }) {
    return curriculumData
        .map((json) => CurriculumSubject.fromJson(json))
        .where((s) =>
            s.collegeCode == collegeCode &&
            s.courseCode == courseCode &&
            s.regulation == regulation &&
            s.isOption &&
            s.electiveType == electiveType)
        .toList();
  }

  String? getLatestRegulation({
    required String collegeCode,
    required String courseCode,
  }) {
    final regs = curriculumData
        .where((json) =>
            json['college_code'] == collegeCode &&
            json['course_code'] == courseCode)
        .map((json) => json['regulation'] as String)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return regs.firstOrNull;
  }

  Future<List<SavedSubject>?> getSavedSubjects(int semester) async {
    try {
      final json = await ApiService.instance
          .get('/syllabus/subjects/$semester') as Map<String, dynamic>;
      final subjects = json['subjects'] as List<dynamic>?;
      if (subjects == null || subjects.isEmpty) return null;
      return subjects
          .map((s) => SavedSubject.fromJson(s as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
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
