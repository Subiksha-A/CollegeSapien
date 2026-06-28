import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:codesapiens/screens/auth/splash_screen.dart';
import 'package:codesapiens/screens/auth/login_screen.dart';
import 'package:codesapiens/screens/auth/signup_screen.dart';
import 'package:codesapiens/screens/onboarding/onboarding_screen.dart';
import 'package:codesapiens/screens/onboarding/user_details_screen.dart';

void runAuthTests() {
  group('Authentication & Onboarding Flow', () {
    testWidgets('Verify Splash Screen & Navigation to Login', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      await tester.pumpAndSettle();

      // Verify splash screen contents
      expect(find.text('CollegeSapien'), findsOneWidget);
      expect(find.text('Your College Companion'), findsOneWidget);
      expect(find.byIcon(Icons.school), findsOneWidget);

      // Wait for splash navigation timer (3 seconds) to trigger
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Should transition to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome Back!'), findsOneWidget);
    });

    testWidgets('Verify Login Screen Form & Validation', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      // Verify fields exist
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

      // Tap login without credentials to trigger validation
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Verify validation errors
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'invalid-email');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('Verify Navigation to Signup Screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      // Tap on Sign Up navigation button
      final signUpButton = find.text("Don't have an account?  Sign Up →");
      expect(signUpButton, findsOneWidget);
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      // Verify we are on SignupScreen
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
    });

    testWidgets('Verify Onboarding Carousel Swipe Flow', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      // Verify first onboarding slide
      expect(find.text('Track Attendance'), findsOneWidget);

      // Swipe left to go to next page
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Verify second onboarding slide
      expect(find.text('Calculate CGPA'), findsOneWidget);

      // Tap "Skip" to skip onboarding
      final skipButton = find.text('Skip');
      expect(skipButton, findsOneWidget);
      await tester.tap(skipButton);
      await tester.pumpAndSettle();
    });

    testWidgets('Verify User Details Form Inputs', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: UserDetailsScreen()));
      await tester.pumpAndSettle();

      // Verify form fields
      expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Roll / Reg Number'), findsOneWidget);
      expect(find.text('Select Department'), findsOneWidget);
      expect(find.text('Select Semester'), findsOneWidget);
      expect(find.text('Select College'), findsOneWidget);

      // Enter name and roll number
      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      await tester.enterText(find.widgetWithText(TextFormField, 'Roll / Reg Number'), 'CS101');
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('CS101'), findsOneWidget);
    });
  });
}
