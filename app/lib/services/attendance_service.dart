import '../models/api_models.dart';
import 'api_service.dart';

class AttendanceService {
  Future<List<AttendanceSummary>> getSummary() async {
    final timezoneOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
    final json = await ApiService.instance.get(
      '/attendance/summary?timezoneOffsetMinutes=$timezoneOffsetMinutes',
    ) as List<dynamic>;
    return json
        .map((item) => AttendanceSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAttendance({
    required String subjectId,
    DateTime? date,
    String? dateKey,
    String? slotStartTime,
    String? slotEndTime,
    required String status,
  }) async {
    await ApiService.instance.post('/attendance', {
      'subjectId': subjectId,
      if (dateKey != null) 'dateKey': dateKey,
      if (dateKey == null && date != null) 'date': date.toIso8601String(),
      if (slotStartTime != null) 'slotStartTime': slotStartTime,
      if (slotEndTime != null) 'slotEndTime': slotEndTime,
      'status': status,
    });
  }
}
