import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/api_models.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../services/cache_service.dart';
import '../../services/resource_service.dart';
import '../../services/syllabus_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../attendance_screen.dart';
import '../auth/login_screen.dart';
import '../resources/resources_hub_screen.dart';
import '../syllabus/syllabus_selection_screen.dart';
import 'about_screen.dart';
// import 'admin_management_screen.dart'; // mod: moved to web admin panel
import 'edit_profile_screen.dart';
import '../cgpa/cgpa_calculator_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _cgpaCacheKey = 'profile_cgpa_stat';
  static const _semesterCacheKey = 'profile_semester_stat';
  static const _semesterPrefsKey = 'last_semester';
  static const _filesUploadedCacheKey = 'profile_files_uploaded_stat';

  String _attendanceStat = '--';
  String _cgpaStat = '--';
  String _semesterStat = '--';
  int? _subjectCount;
  int? _totalCredits;
  String _filesUploaded = '--';
  String? _collegeName;
  String? _department;
  // mod: _showAdminManagement removed — admin management moved to web admin panel
  // bool _showAdminManagement = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    // Attendance — show cached immediately, then refresh
    final cached = CacheService.instance
        .get<List<AttendanceSummary>>('attendance_summary');
    if (cached != null && cached.isNotEmpty) {
      final avg = cached.map((s) => s.percentage).reduce((a, b) => a + b) /
          cached.length;
      if (mounted) {
        setState(() => _attendanceStat = '${avg.toStringAsFixed(1)}%');
      }
    }

    // CGPA/Semester/Files — show in-memory cache immediately
    final cachedCgpa = CacheService.instance.get<String>(_cgpaCacheKey);
    if (cachedCgpa != null && mounted) setState(() => _cgpaStat = cachedCgpa);
    final cachedSemester = CacheService.instance.get<String>(_semesterCacheKey);
    if (cachedSemester != null && mounted) {
      setState(() => _semesterStat = cachedSemester);
    }
    final cachedFilesUploaded =
        CacheService.instance.get<String>(_filesUploadedCacheKey);
    if (cachedFilesUploaded != null && mounted) {
      setState(() => _filesUploaded = cachedFilesUploaded);
    }

    // CGPA/Semester — show persisted values, then refresh semester from profile sync
    try {
      final prefs = await SharedPreferences.getInstance();
      final cgpa = prefs.getString('last_cgpa');
      if (cgpa != null) {
        CacheService.instance.set(_cgpaCacheKey, cgpa);
        if (mounted) setState(() => _cgpaStat = cgpa);
      }

      final semester = prefs.getInt(_semesterPrefsKey);
      if (semester != null) {
        final semText = semester.toString();
        CacheService.instance.set(_semesterCacheKey, semText);
        if (mounted) setState(() => _semesterStat = semText);
      }

      final filesUploaded = prefs.getString('last_files_uploaded');
      if (filesUploaded != null) {
        CacheService.instance.set(_filesUploadedCacheKey, filesUploaded);
        if (mounted) setState(() => _filesUploaded = filesUploaded);
      }
    } catch (_) {}

    try {
      final summaries = await AttendanceService().getSummary();
      CacheService.instance.set('attendance_summary', summaries);
      if (summaries.isNotEmpty) {
        final avg = summaries.map((s) => s.percentage).reduce((a, b) => a + b) /
            summaries.length;
        if (mounted) {
          setState(() => _attendanceStat = '${avg.toStringAsFixed(1)}%');
        }
      }
    } catch (_) {}

    // Semester + college from profile sync
    try {
      final result = await AuthService.instance.syncProfile();
      final profile = result.user;
      if (profile != null) {
        final sem = profile.semester;
        if (sem > 0) {
          final semText = sem.toString();
          CacheService.instance.set(_semesterCacheKey, semText);
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(_semesterPrefsKey, sem);
          } catch (_) {}
          if (mounted) setState(() => _semesterStat = semText);
        }
        if (mounted) {
          setState(() {
            if (profile.collegeName != null) _collegeName = profile.collegeName;
            if (profile.department != null) _department = profile.department;
          });
        }

        if (profile.semester > 0) {
          try {
            final saved = await SyllabusService().getSavedSubjects(profile.semester);
            if (saved != null && saved.isNotEmpty && mounted) {
              final credits = saved.fold<int>(0, (sum, s) => sum + (s.credits ?? 0));
              setState(() {
                _subjectCount = saved.length;
                _totalCredits = credits > 0 ? credits : null;
              });
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    // Files uploaded by this user
    try {
      final uid = AuthService.instance.currentUser?.uid;
      if (uid != null) {
        final results = await Future.wait([
          ResourceService().listHubResources('Notes'),
          ResourceService().listHubResources('QP'),
        ]);
        final count = results
            .expand((list) => list)
            .where((r) => r.uploadedBy == uid)
            .length;
        final countStr = count.toString();
        CacheService.instance.set(_filesUploadedCacheKey, countStr);
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_files_uploaded', countStr);
        } catch (_) {}
        if (mounted) setState(() => _filesUploaded = countStr);
      }
    } catch (_) {}

    // mod: admin management capability check removed — moved to web admin panel
    // try {
    //   final capabilities =
    //       await AppCapabilityService.instance.resolveCapabilities();
    //   if (mounted) {
    //     setState(() => _showAdminManagement = capabilities.canModerateResources);
    //   }
    // } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final user = AuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.045),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Back button + title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: AppTheme.cardDecoration(
                        color: Colors.white,
                        shadowOffset: const Offset(2, 2),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 28,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontFamily: 'Lexend Mega',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Profile card
              Container(
                width: double.infinity,
                decoration: AppTheme.cardDecoration(
                  color: AppColors.primaryYellow,
                ),
                child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 2),
                                color: Colors.grey[300],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: user?.photoURL != null
                                  ? Image.network(
                                      user!.photoURL!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.black54,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.black54,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.displayName?.isNotEmpty == true
                                        ? user!.displayName!
                                        : 'Student',
                                    style: const TextStyle(
                                      fontFamily: 'Lexend Mega',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.email_outlined, size: 14, color: Colors.black.withValues(alpha: 0.6)),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          user?.email ?? '',
                                          style: TextStyle(
                                            fontFamily: 'Public Sans',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black.withValues(alpha: 0.7),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_department != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _department!.toUpperCase(),
                                        style: TextStyle(
                                          fontFamily: 'Lexend Mega',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryYellow,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_collegeName != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(6),
                              bottomRight: Radius.circular(6),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INSTITUTION',
                                style: TextStyle(
                                  fontFamily: 'Public Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black.withValues(alpha: 0.45),
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.home_outlined, size: 18, color: Colors.black.withValues(alpha: 0.6)),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _collegeName!,
                                      style: const TextStyle(
                                        fontFamily: 'Public Sans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ),
              const SizedBox(height: 20),

              // Stats — 2×2 grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Attendance',
                      _attendanceStat,
                      AppColors.accentGreen,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AttendanceScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'CGPA',
                      _cgpaStat,
                      AppColors.accentBlue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CgpaCalculatorScreen()),
                      ).then((_) => _loadStats()),
                      emptyHint: 'Tap to\ncalculate',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSemesterCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SyllabusSelectionScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Files Uploaded',
                      _filesUploaded,
                      AppColors.accentPurple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ResourcesHubScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Menu Items
              _buildMenuItem(
                context,
                'Settings',
                Icons.settings,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                context,
                'Edit Profile',
                Icons.edit,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ).then((_) => _loadStats()),
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                context,
                'Help & Support',
                Icons.help_outline,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                context,
                'About',
                Icons.info_outline,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
              // mod: Admin Management menu item removed — moved to web admin panel
              // if (_showAdminManagement) ...[
              //   const SizedBox(height: 12),
              //   _buildMenuItem(
              //     context,
              //     'Admin Management',
              //     Icons.admin_panel_settings_outlined,
              //     () => Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (_) => const AdminManagementScreen()),
              //     ),
              //   ),
              // ],
              const SizedBox(height: 30),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await AuthService.instance.signOut();
                    } catch (_) {}
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.black),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSemesterCard({VoidCallback? onTap}) {
    final parts = <String>[];
    if (_subjectCount != null) parts.add('$_subjectCount subjects');
    if (_totalCredits != null) parts.add('$_totalCredits credits');

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(color: AppColors.primaryYellow),
      child: Column(
        children: [
          Text(
            _semesterStat,
            style: const TextStyle(
              fontFamily: 'Lexend Mega',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Semester',
            style: TextStyle(
              fontFamily: 'Public Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (parts.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              parts.join('  •  '),
              style: TextStyle(
                fontFamily: 'Public Sans',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color, {
    VoidCallback? onTap,
    String? emptyHint,
  }) {
    final isEmpty = value == '--' && emptyHint != null && emptyHint.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration(color: color),
        child: Column(
          children: [
            if (isEmpty) ...[
              const Text(
                '--',
                style: TextStyle(
                  fontFamily: 'Lexend Mega',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ] else
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Lexend Mega',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Public Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration(color: Colors.white),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

