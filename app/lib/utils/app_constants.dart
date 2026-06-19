// App-wide constants

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

class AppConstants {
  // App Info
  static const String appName = 'CollegeSapien';
  static const String appVersion = '1.0.0';

  // Attendance Thresholds
  static const double attendanceThreshold = 75.0;
  static const double warningThreshold = 78.0;

  // CGPA
  static const int totalSemesters = 8;

  // Access Control
  static const int minUploadsForAccess = 1;

  // API
  static String get apiBaseUrl {
    const baseUrl = String.fromEnvironment(
      'CODESAPIENS_API_BASE_URL',
      defaultValue:
          'https://asia-south1-collegesapiens.cloudfunctions.net/api/api/v1',
    );
    if (defaultTargetPlatform == TargetPlatform.android &&
        baseUrl.contains('127.0.0.1')) {
      return baseUrl.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return baseUrl;
  }

  static const String appCheckRecaptchaSiteKey = String.fromEnvironment(
    'CODESAPIENS_RECAPTCHA_SITE_KEY',
    defaultValue: '',
  );
  static const bool disableAppCheck = bool.fromEnvironment(
    'DISABLE_APP_CHECK',
    defaultValue: false,
  );

  // Storage Paths
  static const String syllabusPath = 'syllabus';
  static const String notesPath = 'notes';
  static const String qpPath = 'question_papers';
  static const String gradesPath = 'grade_sheets';

  // Notification Messages (Tanglish)
  static const List<String> lowAttendanceMessages = [
    'Dei! Attendance romba kamiya poitu iruku da!',
    'Ayo paithyam! Class ku poda maatiya?',
    'Abba! Ipdi poina fail ayiruva!',
    'Machan! Konjam serious ah class ku po!',
    'Kadavule! Ipo poina kattuku velila than!',
    'Anna! Please class attend pannu, illana percentage sethurum!',
  ];

  static const List<String> goodAttendanceMessages = [
    'Machaan! Super ah attendance maintain panra!',
    'Vera level da! Keep it up!',
    'Semma! Ipdi continue pannu!',
    'Perfect! Romba nalla iruku!',
  ];

  // CGPA Motivational Messages
  static const List<String> highCGPAMessages = [
    'Mass da! Vera level marks!',
    'Genius! Keep rocking!',
    'Top ah iruka! Semma!',
  ];

  static const List<String> averageCGPAMessages = [
    'Decent! Konjam improve panlam!',
    'Not bad! Push pannalam!',
    'Good! Vera level ku pogalam!',
  ];

  static const List<String> lowCGPAMessages = [
    'Tension ayidatha da! Next time crush pannu!',
    'Parava illa! Hard work pannalam!',
    'Don\'t worry! Comeback strong!',
  ];

  // Class Reminder Messages
  static const List<String> classReminderMessages = [
    'Machaan! {{time}} ku class iruku! Ready ah iru!',
    'Dei! {{subject}} class time aachu! Polam!',
    'Anna! {{time}} ku class! Late agatha!',
    'Yo! {{room}} ku poganum! Class start aaguthu!',
  ];

  // Pomodoro Timer Durations (in minutes)
  static const int pomodoroWorkDuration = 25;
  static const int pomodoroShortBreak = 5;
  static const int pomodoroLongBreak = 15;
  static const int pomodoroSessionsBeforeLongBreak = 4;
}
