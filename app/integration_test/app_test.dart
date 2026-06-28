import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'tests/auth_tests.dart';
import 'tests/navigation_tests.dart';
import 'tests/attendance_tests.dart';
import 'tests/timetable_tests.dart';
import 'tests/resources_tests.dart';
import 'tests/utility_tests.dart';
import 'tests/profile_tests.dart';

void main() {
  // Initialize the integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CollegeSapien Integration Test Suite', () {
    runAuthTests();
    runNavigationTests();
    runAttendanceTests();
    runTimetableTests();
    runResourcesTests();
    runUtilityTests();
    runProfileTests();
  });
}
