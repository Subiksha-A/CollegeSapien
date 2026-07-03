class CurriculumSubject {
  final String collegeCode;
  final String courseCode;
  final String regulation;
  final String semester;
  final int? parentSemester;
  final String subjectCode;
  final String subjectName;
  final String courseType;
  final String ltp;
  final num? tcp;
  final num? credits;
  final String category;
  final bool isElective;
  final String? electiveType;
  final String recordType;
  final String? electiveStream;
  final String? optionsFrom;

  CurriculumSubject({
    required this.collegeCode,
    required this.courseCode,
    required this.regulation,
    required this.semester,
    this.parentSemester,
    required this.subjectCode,
    required this.subjectName,
    required this.courseType,
    required this.ltp,
    this.tcp,
    this.credits,
    required this.category,
    required this.isElective,
    this.electiveType,
    this.recordType = 'core',
    this.electiveStream,
    this.optionsFrom,
  });

  factory CurriculumSubject.fromJson(Map<String, dynamic> json) {
    return CurriculumSubject(
      collegeCode: json['college_code'] as String? ?? '',
      courseCode: json['course_code'] as String? ?? '',
      regulation: json['regulation'] as String? ?? '',
      semester: json['semester']?.toString() ?? '',
      parentSemester: (json['parent_semester'] as num?)?.toInt(),
      subjectCode: json['subject_code'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      courseType: json['course_type'] as String? ?? '',
      ltp: json['l_t_p'] as String? ?? '',
      tcp: json['tcp'] as num?,
      credits: json['credits'] as num?,
      category: json['category'] as String? ?? '',
      isElective: json['is_elective'] as bool? ?? false,
      electiveType: json['elective_type'] as String?,
      recordType: json['record_type'] as String? ?? 'core',
      electiveStream: json['elective_stream'] as String?,
      optionsFrom: json['options_from'] as String?,
    );
  }

  bool get isSlot => recordType == 'slot';
  bool get isOption => recordType == 'option';
  bool get isCore => recordType == 'core';

  int? get effectiveSemester {
    if (parentSemester != null) return parentSemester;
    return int.tryParse(semester);
  }
}

class CurriculumBundle {
  final String collegeCode;
  final String courseCode;
  final String regulation;
  final List<String> availableRegulations;
  final List<CurriculumSubject> subjects;

  CurriculumBundle({
    required this.collegeCode,
    required this.courseCode,
    required this.regulation,
    required this.availableRegulations,
    required this.subjects,
  });

  factory CurriculumBundle.fromJson(Map<String, dynamic> json) {
    final subjectsJson = json['subjects'] as List<dynamic>? ?? [];
    return CurriculumBundle(
      collegeCode: json['collegeCode'] as String? ?? '',
      courseCode: json['courseCode'] as String? ?? '',
      regulation: json['regulation'] as String? ?? '',
      availableRegulations: (json['availableRegulations'] as List<dynamic>?)
              ?.map((r) => r as String)
              .toList() ??
          [],
      subjects: subjectsJson
          .map((s) => CurriculumSubject.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SavedSyllabus {
  final String? regulation;
  final List<SavedSubject> subjects;

  SavedSyllabus({this.regulation, required this.subjects});

  static SavedSyllabus? fromJsonOrNull(Map<String, dynamic>? json) {
    if (json == null) return null;
    final subjects = json['subjects'] as List<dynamic>?;
    if (subjects == null || subjects.isEmpty) return null;
    return SavedSyllabus(
      regulation: json['regulation'] as String?,
      subjects: subjects
          .map((s) => SavedSubject.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SavedSubject {
  final String subjectCode;
  final String subjectName;
  final num? credits;
  final String? electiveType;
  final bool isElective;
  final String? courseType;
  final String? ltp;
  final num? tcp;
  final String? category;
  final String? electiveStream;

  SavedSubject({
    required this.subjectCode,
    required this.subjectName,
    this.credits,
    this.electiveType,
    this.isElective = false,
    this.courseType,
    this.ltp,
    this.tcp,
    this.category,
    this.electiveStream,
  });

  factory SavedSubject.fromJson(Map<String, dynamic> json) {
    return SavedSubject(
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      credits: json['credits'] as num?,
      electiveType: json['electiveType'] as String?,
      isElective: json['isElective'] as bool? ?? false,
      courseType: json['courseType'] as String?,
      ltp: json['ltp'] as String?,
      tcp: json['tcp'] as num?,
      category: json['category'] as String?,
      electiveStream: json['electiveStream'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'credits': credits,
        'isElective': isElective,
        if (electiveType != null) 'electiveType': electiveType,
        if (courseType != null) 'courseType': courseType,
        if (ltp != null) 'ltp': ltp,
        if (tcp != null) 'tcp': tcp,
        if (category != null) 'category': category,
        if (electiveStream != null) 'electiveStream': electiveStream,
      };
}
