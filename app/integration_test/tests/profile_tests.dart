import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:codesapiens/screens/profile/profile_screen.dart';
import 'package:codesapiens/screens/profile/edit_profile_screen.dart';
import 'package:codesapiens/screens/profile/settings_screen.dart';
import 'package:codesapiens/screens/profile/help_screen.dart';
import 'package:codesapiens/screens/profile/about_screen.dart';

void runProfileTests() {
  group('Profile & Settings Flow', () {
    testWidgets('Verify Profile Dashboard Stats & Menu', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pumpAndSettle();

      // Verify page header
      expect(find.text('Profile'), findsOneWidget);

      // Verify that profile cards or sections exist
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('Verify Edit Profile Form Fields', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: EditProfileScreen()));
      await tester.pumpAndSettle();

      // Verify title
      expect(find.text('Edit Profile'), findsOneWidget);

      // Verify fields exist
      expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Department'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Semester'), findsOneWidget);

      // Verify save button exists
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Verify Settings Toggles & Sliders', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Verify settings title
      expect(find.text('Settings'), findsOneWidget);

      // Verify switch tiles
      expect(find.text('Enable Notifications'), findsOneWidget);
      expect(find.text('Class Reminders'), findsOneWidget);
      expect(find.text('Attendance Alerts'), findsOneWidget);

      // Verify slider section
      expect(find.text('Attendance Warning Threshold'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('Verify Help & FAQs Screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HelpScreen()));
      await tester.pumpAndSettle();

      // Verify help title
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Frequently Asked Questions'), findsOneWidget);
    });

    testWidgets('Verify About Screen Links', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
      await tester.pumpAndSettle();

      // Verify about title
      expect(find.text('About CollegeSapien'), findsOneWidget);

      // Verify that version info is shown
      expect(find.textContaining('Version'), findsOneWidget);

      // Verify links exist
      expect(find.text('GitHub Repository'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });
  });
}
