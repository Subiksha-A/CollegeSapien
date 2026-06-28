import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:codesapiens/screens/attendance_screen.dart';
import 'package:codesapiens/screens/attendance/mark_attendance_screen.dart';

void runAttendanceTests() {
  group('Attendance Module Flow', () {
    testWidgets('Verify Attendance Overview Screen Rendering', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));
      await tester.pumpAndSettle();

      // Verify page title is present
      expect(find.text('Attendance'), findsOneWidget);

      // Verify that the Floating Action Button is present
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Verify Mark Attendance Form Interaction', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MarkAttendanceScreen()));
      await tester.pumpAndSettle();

      // Verify header/title
      expect(find.text('Log Attendance'), findsOneWidget);

      // Verify Date picker field is present
      expect(find.text('Select Date'), findsOneWidget);

      // Verify subject selector dropdown is present
      expect(find.text('Choose a Subject'), findsOneWidget);

      // Verify slot selector dropdown is present
      expect(find.text('Choose a class slot'), findsOneWidget);

      // Verify Status Buttons exist
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Bunk'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);
      expect(find.text('OD / ML'), findsOneWidget);

      // Tap on Bunk (Absent) status
      await tester.tap(find.text('Bunk'));
      await tester.pumpAndSettle();

      // Tap on Present status
      await tester.tap(find.text('Present'));
      await tester.pumpAndSettle();

      // Verify Save button exists
      expect(find.text('Save Attendance'), findsOneWidget);
    });
  });
}
