import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/app_state_notifier.dart';
import '../home/main_navigation.dart';
import '../onboarding/onboarding_screen.dart';
import 'login_screen.dart';

/// Splash Screen - App launch screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Start animation
    _controller.forward();

    // Navigate after delay
    _navigationTimer = Timer(const Duration(seconds: 3), _navigateToNext);
  }

  Future<void> _navigateToNext() async {
    if (!mounted) return;

    final user = AuthService.instance.currentUser;
    if (user == null) {
      _replaceWith(const LoginScreen());
      return;
    }

    try {
      final appState = Provider.of<AppStateNotifier>(context, listen: false);
      await appState.loadFromLocalCache();

      await user.reload();
      await AuthService.instance.currentUser?.getIdToken(true);
      final result = await AuthService.instance.syncProfile();

      if (result.user != null) {
        appState.setUserProfile(result.user);
      }
      // Persist the rest of the sync payload too, so the home screen finds
      // fresh cached data on mount instead of hitting /auth/sync again.
      if (result.attendanceSummary != null) {
        appState.setAttendanceSummary(result.attendanceSummary!);
      }
      if (result.timetableSubjects != null) {
        appState.setTimetableSubjects(result.timetableSubjects!);
      }
      final savedSubjects = result.savedSubjects?.subjects;
      if (savedSubjects != null && savedSubjects.isNotEmpty) {
        appState.setSavedSubjects(savedSubjects);
      }

      if (!mounted) return;
      if (!result.emailVerified) {
        _replaceWith(const LoginScreen());
      } else if (result.onboardingRequired) {
        _replaceWith(const OnboardingScreen());
      } else {
        _replaceWith(const MainNavigation());
      }
    } catch (e) {
      if (mounted) {
        debugPrint('SplashScreen navigation error: $e');
        final appState = Provider.of<AppStateNotifier>(context, listen: false);
        final profile = appState.userProfile;
        if (profile != null &&
            profile.collegeId != null &&
            profile.department != null) {
          // Navigate to main screen offline if we have cached details
          _replaceWith(const MainNavigation());
        } else {
          _replaceWith(const LoginScreen());
        }
      }
    }
  }

  void _replaceWith(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEEEC3),
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD966),
                      border: Border.all(color: Colors.black, width: 3),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          offset: Offset(8, 8),
                          color: Colors.black,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.school,
                        size: 80,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // App Name
                  const Text(
                    'CollegeSapien',
                    style: TextStyle(
                      fontFamily: 'Lexend Mega',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2.0,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tagline
                  Text(
                    'Your College Companion',
                    style: TextStyle(
                      fontFamily: 'Public Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open Source • For Students, By Students',
                    style: TextStyle(
                      fontFamily: 'Public Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 52),

                  // Loading indicator
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
