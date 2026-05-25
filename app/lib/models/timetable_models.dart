// Data models for timetable functionality

class TimetableSubject {
  final String id;
  final String name;
  final String code;
  final List<TimetableClass> classes;

  TimetableSubject({
    required this.id,
    required this.name,
    required this.code,
    required this.classes,
  });

  factory TimetableSubject.fromJson(Map<String, dynamic> json) {
    return TimetableSubject(
      id: (json['id'] ?? json['code'])?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled Subject',
      code: json['code']?.toString() ?? '',
      classes: (json['classes'] as List<dynamic>? ?? [])
          .map((e) => TimetableClass.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'classes': classes.map((e) => e.toJson()).toList(),
    };
  }
}

class TimetableClass {
  final String day; // MON, TUE, WED, THU, FRI, SAT
  final String startTime; // "09:00"
  final String endTime; // "10:00"
  final String period; // "AM" or "PM"
  final String room;
  final String type; // "CORE", "LAB", "BREAK"
  final int duration; // in hours

  TimetableClass({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.period,
    required this.room,
    required this.type,
    required this.duration,
  });

  factory TimetableClass.fromJson(Map<String, dynamic> json) {
    final startTime = json['startTime']?.toString() ?? '09:00';
    return TimetableClass(
      day: json['day']?.toString() ?? 'MON',
      startTime: startTime,
      endTime: json['endTime']?.toString() ?? startTime,
      period: json['period']?.toString() ?? _periodFromTime(startTime),
      room: json['room']?.toString() ?? '',
      type: json['type']?.toString() ?? 'CORE',
      duration: json['duration'] is int
          ? json['duration'] as int
          : int.tryParse(json['duration']?.toString() ?? '') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'period': period,
      'room': room,
      'type': type,
      'duration': duration,
    };
  }
}

String _periodFromTime(String time) {
  final hour = int.tryParse(time.split(':').first) ?? 9;
  return hour >= 12 ? 'PM' : 'AM';
}

class DaySchedule {
  final String day;
  final int date;
  final bool isToday;

  DaySchedule({
    required this.day,
    required this.date,
    required this.isToday,
  });
}

class TimetableData {
  final List<TimetableSubject> subjects;
  final String? attendanceTrackingStartDate;

  TimetableData({
    required this.subjects,
    this.attendanceTrackingStartDate,
  });

  factory TimetableData.fromJson(Map<String, dynamic> json) {
    final subjects = json['subjects'] as List<dynamic>? ?? [];
    return TimetableData(
      subjects: subjects
          .map(
              (item) => TimetableSubject.fromJson(item as Map<String, dynamic>))
          .toList(),
      attendanceTrackingStartDate:
          json['attendanceTrackingStartDate']?.toString(),
    );
  }
}
