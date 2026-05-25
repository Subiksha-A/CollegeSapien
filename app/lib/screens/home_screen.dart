import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/attendance_card.dart';
import '../widgets/next_class_card.dart';
import '../widgets/timetable_card.dart';
import '../widgets/community_feed_card.dart';
import '../widgets/resource_button.dart';
import '../services/auth_service.dart';
import 'ai_features/resume_roast_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _semester = 0;
  String _collegeName = '';

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
    _syncProfile();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _semester = prefs.getInt('last_semester') ?? 0;
        _collegeName = prefs.getString('last_college_name') ?? '';
      });
    }
  }

  Future<void> _syncProfile() async {
    try {
      final result = await AuthService.instance.syncProfile();
      final user = result.user;
      if (user == null || !mounted) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_semester', user.semester);
      await prefs.setString('last_college_name', user.collegeName ?? '');
      if (mounted) {
        setState(() {
          _semester = user.semester;
          _collegeName = user.collegeName ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEEEC3),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Main scrollable content
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 30),

                    // Attendance Card
                    const AttendanceCard(
                      percentage: 72,
                      safeToSkip: 0,
                    ),
                    const SizedBox(height: 30),

                    // Next Class Card
                    const NextClassCard(
                      subject: 'Engineering Math',
                      room: 'Room 302',
                      block: 'Block B',
                      startTime: '10:30 AM',
                      endTime: '11:30 AM',
                    ),
                    const SizedBox(height: 30),

                    // Today's Timetable Header
                    _buildSectionHeader("TODAY'S TIMETABLE", onShowAll: () {}),
                    const SizedBox(height: 20),

                    // Timetable Cards (Horizontal Scroll)
                    SizedBox(
                      height: 105,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          TimetableCard(
                            time: '08:30 AM',
                            subject: 'Engineering Math',
                            location: 'Lec Hall 1',
                            color: Color(0xFFD2FFB6),
                          ),
                          SizedBox(width: 10),
                          TimetableCard(
                            time: '10:30 AM',
                            subject: 'Eng. Math',
                            location: 'Room 302',
                            color: Color(0xFFFFC0B6),
                          ),
                          SizedBox(width: 10),
                          TimetableCard(
                            time: '11:39',
                            subject: 'Theory of Comp',
                            location: 'Lec Hall 4',
                            color: Color(0xFFE3B6FF),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Community Feed Header
                    _buildSectionHeader('COMMUNITY FEED', onShowAll: () {}),
                    const SizedBox(height: 20),

                    // Community Feed Card
                    const CommunityFeedCard(
                      tag: 'CSE 3RD YEAR',
                      title: 'Notes For AI Module 2 Has Been Shared!',
                      sharedBy: 'Rahul S',
                    ),
                    const SizedBox(height: 30),

                    // Academic Resources Header
                    _buildSectionHeader('ACADEMIC RESOURCES'),
                    const SizedBox(height: 20),

                    // Resource Buttons
                    Column(
                      children: const [
                        ResourceButton(
                          icon: Icons.book,
                          title: 'Previous Year Papers',
                        ),
                        SizedBox(height: 20),
                        ResourceButton(
                          icon: Icons.menu_book,
                          title: 'Previous Year Papers',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_semester >= 4) ...[
                      _buildSectionHeader('AI FEATURES'),
                      const SizedBox(height: 20),
                      _buildResumeRoastCard(),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNavigation(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.menu,
          size: 24,
          color: Colors.black,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _collegeName.isNotEmpty ? _collegeName : 'CodeSapien',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 1),
            boxShadow: const [
              BoxShadow(
                offset: Offset(2, 2),
                color: Colors.black,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/profile.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.black),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onShowAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.14,
            color: Color(0xFF191C1E),
            height: 1.43,
          ),
        ),
        if (onShowAll != null)
          GestureDetector(
            onTap: onShowAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB6B6),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(2, 2),
                    color: Colors.black,
                  ),
                ],
              ),
              child: const Text(
                'SHOW ALL',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.11,
                  color: Color(0xFF191C1E),
                  height: 1.82,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResumeRoastCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResumeRoastScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB6B6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(offset: Offset(4, 4), color: Colors.black),
          ],
        ),
        child: Row(
          children: const [
            Icon(Icons.local_fire_department, size: 36, color: Colors.black),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resume Roast',
                    style: TextStyle(
                      fontFamily: 'Lexend Mega',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Let AI roast your resume',
                    style: TextStyle(
                      fontFamily: 'Public Sans',
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFD966),
        border: Border(
          top: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, 'Home', Icons.home, true),
            _buildNavItem(1, null, Icons.bar_chart, false),
            _buildNavItem(2, null, Icons.bookmark, false),
            _buildNavItem(3, null, Icons.people, false),
            _buildNavItem(4, null, Icons.person, false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String? label, IconData icon, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: isActive
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFB4E4FF),
                border: Border.all(color: Colors.black, width: 1),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(2, 2),
                    color: Colors.black,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 24, color: Colors.black),
                  if (label != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                  ],
                ],
              ),
            )
          : Icon(icon, size: 24, color: Colors.black),
    );
  }
}
