import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../models/api_models.dart';
import '../../models/syllabus_models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/college_service.dart';
import '../../services/syllabus_service.dart';
import '../../providers/app_state_notifier.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../utils/department_constants.dart';
import '../../widgets/searchable_dropdown.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  List<College> _colleges = [];
  String? _selectedCollegeId;
  String? _selectedDepartment;
  int? _selectedSemester;
  String? _initialCollegeId;
  String? _initialDepartment;
  int? _initialSemester;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        CollegeService().listColleges(),
        AuthService.instance.syncProfile(),
      ]);
      if (!mounted) return;
      _colleges = results[0] as List<College>
        ..sort((a, b) => a.name.compareTo(b.name));
      final profile = (results[1] as AuthSyncResult).user;
      if (profile != null) {
        _selectedCollegeId = profile.collegeId;
        _initialCollegeId = profile.collegeId;
        final deptMatch = departments.any((d) => d.name == profile.department);
        _selectedDepartment = deptMatch ? profile.department : null;
        _initialDepartment = profile.department;
        _selectedSemester =
            profile.semester > 0 && profile.semester <= 8 ? profile.semester : null;
        _initialSemester = _selectedSemester;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final appState = Provider.of<AppStateNotifier>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final body = <String, dynamic>{};
      if (_nameController.text.trim().isNotEmpty) {
        body['name'] = _nameController.text.trim();
      }
      if (_selectedCollegeId != null) {
        body['collegeId'] = _selectedCollegeId;
      }
      if (_selectedDepartment != null) {
        body['department'] = _selectedDepartment;
      }
      if (_selectedSemester != null) {
        body['semester'] = _selectedSemester;
      }

      await ApiService.instance.patch('/auth/me', body);

      if (_nameController.text.trim().isNotEmpty) {
        await FirebaseAuth.instance.currentUser
            ?.updateDisplayName(_nameController.text.trim());
      }

      // Refresh local user profile via sync
      final syncResult = await AuthService.instance.syncProfile();
      final updatedProfile = syncResult.user;
      if (updatedProfile != null) {
        appState.setUserProfile(updatedProfile);
      }

      // Check if college, department or semester changed, and update cache accordingly
      final collegeChanged = _selectedCollegeId != _initialCollegeId;
      final departmentChanged = _selectedDepartment != _initialDepartment;
      final semesterChanged = _selectedSemester != _initialSemester;

      if (collegeChanged || departmentChanged) {
        final syllabusService = SyllabusService();
        await syllabusService.clearCache();

        if (_selectedCollegeId != null && _selectedDepartment != null) {
          final newCollege =
              _colleges.where((c) => c.id == _selectedCollegeId).firstOrNull;
          final deptObj =
              departments.where((d) => d.name == _selectedDepartment).firstOrNull;
          final courseCode = deptObj?.code;
          if (newCollege != null && courseCode != null) {
            try {
              // Pre-fetch the new curriculum to refresh local cache
              await syllabusService.getCurriculum(
                collegeCode: newCollege.code,
                courseCode: courseCode,
              );
            } catch (_) {
              // Ignore background fetch errors so the profile save is not blocked
            }
          }
        }
      }

      if (semesterChanged && _selectedSemester != null) {
        final syllabusService = SyllabusService();
        try {
          final saved = await syllabusService.getSavedSubjects(_selectedSemester!);
          if (saved != null) {
            appState.setSavedSubjects(saved);
          } else {
            // Curriculum fallback
            final newCollegeId = _selectedCollegeId ?? _initialCollegeId;
            final newDept = _selectedDepartment ?? _initialDepartment;
            if (newCollegeId != null && newDept != null) {
              final newCollege =
                  _colleges.where((c) => c.id == newCollegeId).firstOrNull;
              final deptObj =
                  departments.where((d) => d.name == newDept).firstOrNull;
              final courseCode = deptObj?.code;
              if (newCollege != null && courseCode != null) {
                final bundle = await syllabusService.getCurriculum(
                  collegeCode: newCollege.code,
                  courseCode: courseCode,
                );
                final subjects = syllabusService.getSubjectsForSemester(
                  bundle,
                  semester: _selectedSemester!,
                );
                if (subjects.isNotEmpty) {
                  final fallbackSubjects = subjects
                      .map((s) => SavedSubject(
                            subjectCode: s.subjectCode,
                            subjectName: s.subjectName,
                            credits: s.credits,
                            isElective: s.isElective,
                            electiveType: s.electiveType,
                            courseType: s.courseType,
                            ltp: s.ltp,
                            tcp: s.tcp,
                            category: s.category,
                          ))
                      .toList();
                  appState.setSavedSubjects(fallbackSubjects);
                } else {
                  appState.invalidateSavedSubjects();
                }
              }
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Profile updated!'), backgroundColor: Colors.green),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Lexend Mega',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: 0,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.black,
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v != null &&
                                v.trim().isNotEmpty &&
                                v.trim().length < 2
                            ? 'Name must be at least 2 characters'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown<College>(
                        items: _colleges,
                        value: _selectedCollegeId != null
                            ? _colleges
                                .where((c) => c.id == _selectedCollegeId)
                                .firstOrNull
                            : null,
                        labelBuilder: (c) => c.name,
                        decoration: const InputDecoration(
                          labelText: 'College',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (college) {
                          setState(() => _selectedCollegeId = college?.id);
                        },
                      ),
                      const SizedBox(height: 16),
                      SearchableDropdown<Department>(
                        items: departments,
                        value: _selectedDepartment != null
                            ? departments
                                .where((d) => d.name == _selectedDepartment)
                                .firstOrNull
                            : null,
                        labelBuilder: (d) => d.name,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (dept) {
                          setState(() => _selectedDepartment = dept?.name);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedSemester,
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          border: OutlineInputBorder(),
                        ),
                        items: semesters.map((sem) {
                          return DropdownMenuItem(
                            value: sem,
                            child: Text('Semester $sem'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedSemester = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isSaving || _isLoading) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Save Changes',
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
      ),
    );
  }
}
