import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../services/attendance_notification_service.dart';
import '../../services/timetable_service.dart';
import 'home_screen.dart';
import '../attendance_screen.dart';
import '../timetable_list_screen.dart';
import '../resources/resources_hub_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _attendanceRefreshToken = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  static const _navItems = [
    (icon: Icons.home_outlined, label: 'Home'),
    (icon: Icons.check_circle_outline, label: 'Attendance'),
    (icon: Icons.calendar_today_outlined, label: 'Timetable'),
    (icon: Icons.library_books_outlined, label: 'Resources'),
    (icon: Icons.person_outline, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();

    _prepareAttendanceNotifications();
  }

  Future<void> _prepareAttendanceNotifications() async {
    try {
      await AttendanceNotificationService.instance.syncPendingActions();
      AttendanceNotificationService.instance.openPendingNavigation();
      final subjects = await TimetableService().getAllSubjects();
      await AttendanceNotificationService.instance
          .scheduleForTimetable(subjects);
    } catch (_) {}
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onTab(int index) {
    if (_currentIndex == index) return;
    _fadeCtrl.value = 0.0;
    setState(() {
      _currentIndex = index;
      if (index == 1) _attendanceRefreshToken += 1;
    });
    _fadeCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(_fade),
          child: _screenForIndex(_currentIndex),
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _screenForIndex(int index) {
    return switch (index) {
      0 => HomeScreen(onTabSwitch: _onTab),
      1 => AttendanceScreen(refreshToken: _attendanceRefreshToken),
      2 => const TimetableListScreen(),
      3 => const ResourcesHubScreen(),
      4 => const ProfileScreen(),
      _ => HomeScreen(onTabSwitch: _onTab),
    };
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryYellow,
        border: Border(top: BorderSide(color: Colors.black, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_navItems.length, _navItem),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index) {
    final isActive = _currentIndex == index;
    final item = _navItems[index];

    if (isActive) {
      return GestureDetector(
        onTap: () => _onTab(index),
        child: Container(
          // Outer container owns the border + shadow — drawn OUTSIDE the clip
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(offset: Offset(2, 2), color: Colors.black),
            ],
          ),
          child: ClipRRect(
            // Clip stripes to rounded corners — border is above this clip
            borderRadius: BorderRadius.circular(7),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              color: AppColors.navigationBlue,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Shine stripes clipped inside, under the border
                  Positioned.fill(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _navStripe(left: 78, top: -41, width: 12),
                        _navStripe(left: 29, top: -24, width: 12),
                        _navStripe(left: 46, top: -21, width: 6),
                        _navStripe(left: -31, top: -18, width: 14),
                        _navStripe(left: -10, top: -13, width: 7),
                        _navStripe(left: -39, top: -10, width: 7),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 24, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.21,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTab(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(item.icon, size: 26, color: Colors.black),
      ),
    );
  }

  Widget _navStripe({
    required double left,
    required double top,
    required double width,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: 71,
        height: 94,
        child: Center(
          child: Transform.rotate(
            angle: -35 * math.pi / 180,
            child: Container(
              width: width,
              height: 106,
              color: AppColors.lightBlue,
            ),
          ),
        ),
      ),
    );
  }
}
