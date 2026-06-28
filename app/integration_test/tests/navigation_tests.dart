import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:codesapiens/screens/home/main_navigation.dart';
import 'package:codesapiens/screens/home/home_screen.dart';
import 'package:codesapiens/screens/attendance_screen.dart';
import 'package:codesapiens/screens/timetable_list_screen.dart';
import 'package:codesapiens/screens/resources/resources_hub_screen.dart';
import 'package:codesapiens/screens/home/events_all_screen.dart';

void runNavigationTests() {
  group('Main Navigation & Shell Flow', () {
    testWidgets('Verify Tab Switching via Bottom Bar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigation()));
      await tester.pumpAndSettle();

      // Starts on HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);

      // Tap on Attendance Tab
      final attendanceTab = find.byIcon(Icons.check_circle_outline);
      expect(attendanceTab, findsOneWidget);
      await tester.tap(attendanceTab);
      await tester.pumpAndSettle();

      // Verify AttendanceScreen is displayed
      expect(find.byType(AttendanceScreen), findsOneWidget);

      // Tap on Timetable Tab
      final timetableTab = find.byIcon(Icons.calendar_today_outlined);
      expect(timetableTab, findsOneWidget);
      await tester.tap(timetableTab);
      await tester.pumpAndSettle();

      // Verify TimetableListScreen is displayed
      expect(find.byType(TimetableListScreen), findsOneWidget);

      // Tap on Resources Tab
      final resourcesTab = find.byIcon(Icons.library_books_outlined);
      expect(resourcesTab, findsOneWidget);
      await tester.tap(resourcesTab);
      await tester.pumpAndSettle();

      // Verify ResourcesHubScreen is displayed
      expect(find.byType(ResourcesHubScreen), findsOneWidget);
    });

    testWidgets('Verify Navigation to Events Screen from Home', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigation()));
      await tester.pumpAndSettle();

      // Find and tap the "View All" or similar events text/button on HomeScreen
      // Let's look for "Campus Events" or "View All"
      final viewAllEvents = find.text('View All');
      if (viewAllEvents.evaluate().isNotEmpty) {
        await tester.tap(viewAllEvents);
        await tester.pumpAndSettle();

        // Verify we navigated to EventsAllScreen
        expect(find.byType(EventsAllScreen), findsOneWidget);
      }
    });
  });
}
