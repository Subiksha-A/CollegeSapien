import '../../models/timetable_models.dart';

class AttendanceNotificationService {
  AttendanceNotificationService._();
  static final AttendanceNotificationService instance =
      AttendanceNotificationService._();

  Future<void> initialize() async {}
  Future<bool> requestPermission() async => false;
  Future<bool> hasPermission() async => false;
  Future<void> scheduleTestNotification() async {}
  Future<void> scheduleForTimetable(List<TimetableSubject> subjects) async {}
  Future<void> syncPendingActions() async {}
  void openPendingNavigation() {}
}
