import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/api_models.dart';
import '../../models/syllabus_models.dart';
import '../../services/auth_service.dart';
import '../../services/college_service.dart';
import '../../services/syllabus_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../utils/department_constants.dart';
import '../../widgets/searchable_dropdown.dart';
import '../home/main_navigation.dart';

class SyllabusSelectionScreen extends StatefulWidget {
  const SyllabusSelectionScreen({super.key});

  @override
  State<SyllabusSelectionScreen> createState() =>
      _SyllabusSelectionScreenState();
}

class _SyllabusSelectionScreenState extends State<SyllabusSelectionScreen> {
  final _syllabusService = SyllabusService();
  final _collegeService = CollegeService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _debugInfo;
  List<_SubjectEntry> _entries = [];
  String? _regulation;
  UserProfile? _profile;
  Map<String, List<CurriculumSubject>> _electiveOptions = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final syncResult = await AuthService.instance.syncProfile();
      final profile = syncResult.user;
      if (profile == null) {
        setState(() {
          _error = 'Profile not found';
          _isLoading = false;
        });
        return;
      }
      _profile = profile;

      final dbg = StringBuffer();
      dbg.writeln('Profile: collegeId=${profile.collegeId}, '
          'collegeName=${profile.collegeName}, '
          'department="${profile.department}", semester=${profile.semester}');

      final colleges = await _collegeService.listColleges();
      final college =
          colleges.where((c) => c.id == profile.collegeId).firstOrNull;
      final collegeCode = college?.code;

      dbg.writeln('College match: ${college?.name} => code=$collegeCode');
      dbg.writeln(
          'Available colleges: ${colleges.map((c) => "${c.id}:${c.code}").join(", ")}');

      final deptObj =
          departments.where((d) => d.name == profile.department).firstOrNull;
      final courseCode = deptObj?.code;

      dbg.writeln('Dept match: "${profile.department}" => code=$courseCode');

      if (collegeCode == null || courseCode == null) {
        dbg.writeln(
            'STOPPED: collegeCode=$collegeCode, courseCode=$courseCode');
        setState(() {
          _debugInfo = dbg.toString();
          _error = 'No syllabus found';
          _isLoading = false;
        });
        return;
      }

      final regulation = _syllabusService.getLatestRegulation(
        collegeCode: collegeCode,
        courseCode: courseCode,
      );

      dbg.writeln('Regulation: $collegeCode + $courseCode => $regulation');

      if (regulation == null) {
        dbg.writeln('STOPPED: no regulation found');
        setState(() {
          _debugInfo = dbg.toString();
          _error = 'No syllabus found';
          _isLoading = false;
        });
        return;
      }

      _regulation = regulation;

      // Load elective options from curriculum (for dropdown choices)
      final optionsMap = <String, List<CurriculumSubject>>{};
      final curriculumSubjects = _syllabusService.getSubjectsForSemester(
        collegeCode: collegeCode,
        courseCode: courseCode,
        regulation: regulation,
        semester: profile.semester,
      );
      final optionPools = curriculumSubjects
          .where((s) => s.isSlot && s.optionsFrom != null)
          .map((s) => s.optionsFrom!)
          .toSet();
      for (final pool in optionPools) {
        optionsMap[pool] = _syllabusService.getElectiveOptions(
          collegeCode: collegeCode,
          courseCode: courseCode,
          regulation: regulation,
          electiveType: pool,
        );
      }

      // Check if user already has saved subjects
      List<SavedSubject>? saved;
      try {
        saved = await _syllabusService.getSavedSubjects(profile.semester);
      } catch (_) {}

      final entries = <_SubjectEntry>[];

      if (saved != null && saved.isNotEmpty) {
        // User has saved subjects — show exactly those
        for (final sv in saved) {
          final optFrom = sv.isElective ? _findOptionsFrom(sv.electiveType, curriculumSubjects) : null;
          final subject = CurriculumSubject(
            collegeCode: collegeCode,
            courseCode: courseCode,
            regulation: regulation,
            semester: '${profile.semester}',
            subjectCode: sv.subjectCode,
            subjectName: sv.subjectName,
            courseType: sv.courseType ?? '',
            ltp: sv.ltp ?? '',
            credits: sv.credits,
            tcp: sv.tcp,
            category: sv.category ?? '',
            isElective: sv.isElective,
            electiveType: sv.electiveType,
            recordType: sv.isElective ? 'slot' : 'core',
            optionsFrom: optFrom,
          );
          CurriculumSubject? matchedOption;
          if (sv.isElective && optFrom != null) {
            final pool = optionsMap[optFrom] ?? [];
            matchedOption = pool.where((o) => o.subjectName == sv.subjectName).firstOrNull;
          }
          entries.add(_SubjectEntry(subject: subject, selectedOption: matchedOption));
        }
      } else {
        // First time — load from curriculum
        dbg.writeln(
            'Subjects found: ${curriculumSubjects.length} for semester ${profile.semester}');

        if (curriculumSubjects.isEmpty) {
          setState(() {
            _debugInfo = dbg.toString();
            _error = 'No syllabus found';
            _isLoading = false;
          });
          return;
        }

        for (final s in curriculumSubjects) {
          entries.add(_SubjectEntry(subject: s));
        }
      }

      setState(() {
        _electiveOptions = optionsMap;
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String? _findOptionsFrom(String? electiveType, List<CurriculumSubject> curriculum) {
    if (electiveType == null) return null;
    return curriculum
        .where((s) => s.isSlot && s.electiveType == electiveType)
        .map((s) => s.optionsFrom)
        .firstOrNull;
  }

  Future<void> _save() async {
    if (_regulation == null || _profile == null) return;

    setState(() => _isSaving = true);
    try {
      final subjects = _entries.map((e) {
        final opt = e.selectedOption;
        final src = opt ?? e.subject;
        return SavedSubject(
          subjectCode: src.subjectCode,
          subjectName:
              opt?.subjectName ?? e.editedName ?? e.subject.subjectName,
          credits: e.editedCredits ?? src.credits,
          electiveType: e.subject.electiveType,
          isElective: e.subject.isElective,
          courseType: src.courseType.isNotEmpty ? src.courseType : null,
          ltp: src.ltp.isNotEmpty ? src.ltp : null,
          tcp: src.tcp,
          category: src.category.isNotEmpty ? src.category : null,
          electiveStream: opt?.electiveStream,
        );
      }).toList();

      await _syllabusService.saveSubjects(
        semester: _profile!.semester,
        regulation: _regulation!,
        subjects: subjects,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditSheet(int index) {
    final entry = _entries[index];
    final currentName = entry.selectedOption?.subjectName ??
        entry.editedName ??
        entry.subject.subjectName;
    final currentCredits =
        entry.editedCredits ?? entry.selectedOption?.credits ?? entry.subject.credits;
    final nameCtrl = TextEditingController(text: currentName);
    final creditsCtrl = TextEditingController(text: '${currentCredits ?? ''}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Subject',
              style: TextStyle(
                fontFamily: 'Lexend Mega',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Subject Name',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: creditsCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Credits',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _entries.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  label: const Text('Delete',
                      style: TextStyle(color: Colors.red)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final newName = nameCtrl.text.trim();
                    final newCredits = int.tryParse(creditsCtrl.text.trim());
                    setState(() {
                      _entries[index] = _SubjectEntry(
                        subject: entry.subject,
                        selectedOption: null,
                        editedName: newName.isNotEmpty ? newName : null,
                        editedCredits: newCredits,
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubjectSheet() {
    final nameCtrl = TextEditingController();
    final creditsCtrl = TextEditingController();
    bool isElective = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Subject',
                style: TextStyle(
                  fontFamily: 'Lexend Mega',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Subject Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: creditsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Credits',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Type:',
                      style: TextStyle(
                          fontFamily: 'Public Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Core'),
                    selected: !isElective,
                    onSelected: (_) =>
                        setSheetState(() => isElective = false),
                    selectedColor: AppColors.accentGreen,
                    side: const BorderSide(color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Elective'),
                    selected: isElective,
                    onSelected: (_) =>
                        setSheetState(() => isElective = true),
                    selectedColor: AppColors.accentPurple,
                    side: const BorderSide(color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final credits =
                          int.tryParse(creditsCtrl.text.trim());
                      if (name.isEmpty) return;
                      final newSubject = CurriculumSubject(
                        collegeCode: '',
                        courseCode: '',
                        regulation: _regulation ?? '',
                        semester: '${_profile?.semester ?? 0}',
                        subjectCode: '',
                        subjectName: name,
                        courseType: '',
                        ltp: '',
                        credits: credits,
                        category: '',
                        isElective: isElective,
                        recordType: 'core',
                      );
                      setState(() {
                        _entries
                            .add(_SubjectEntry(subject: newSubject));
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'Your Subjects',
          style: TextStyle(letterSpacing: 0),
        ),
        backgroundColor: AppColors.background,
        actions: [
          if (!_isLoading && _error == null)
            IconButton(
              onPressed: _showAddSubjectSheet,
              icon:
                  const Icon(Icons.add_circle_outline, color: Colors.black),
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: (!_isLoading && _error == null)
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _save,
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Saving...' : 'Save Subjects'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration:
                    AppTheme.cardDecoration(color: AppColors.accentPink),
                child: Column(
                  children: [
                    const Icon(Icons.menu_book_outlined,
                        size: 48, color: Colors.black),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Lexend Mega',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Syllabus data is not available for your college and department yet.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontFamily: 'Public Sans', fontSize: 14),
                    ),
                    if (_debugInfo != null && _debugInfo!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black26),
                        ),
                        child: SelectableText(
                          _debugInfo!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MainNavigation()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Continue to Home'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final semester = _profile?.semester ?? 0;
    final totalCredits = _entries.fold<int>(
        0, (sum, e) => sum + (e.editedCredits ?? e.subject.credits ?? 0));

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(color: AppColors.primaryYellow),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semester $semester  •  $_regulation',
                style: const TextStyle(
                  fontFamily: 'Lexend Mega',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_entries.length} subjects  •  $totalCredits credits',
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: _entries.length,
            itemBuilder: (context, index) =>
                _buildSubjectCard(_entries[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(_SubjectEntry entry, int index) {
    final subject = entry.subject;
    final isSlot = subject.isSlot;
    final hasOptions = isSlot &&
        subject.optionsFrom != null &&
        (_electiveOptions[subject.optionsFrom]?.isNotEmpty ?? false);
    final color =
        subject.isElective ? AppColors.accentPurple : AppColors.accentGreen;
    final displayName = entry.selectedOption?.subjectName ??
        entry.editedName ??
        subject.subjectName;
    final displayCredits = entry.editedCredits ??
        entry.selectedOption?.credits ??
        subject.credits;
    final isEdited = entry.editedName != null ||
        entry.editedCredits != null ||
        entry.selectedOption != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(color: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subject.isElective && subject.electiveType != null)
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    subject.electiveType!,
                    style: const TextStyle(
                      fontFamily: 'Public Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isEdited) ...[
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: const Text(
                      'edited',
                      style: TextStyle(
                        fontFamily: 'Public Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            )
          else if (isEdited)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: const Text(
                'edited',
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (hasOptions)
            _buildElectiveDropdown(entry, index)
          else
            Text(
              displayName,
              style: const TextStyle(
                fontFamily: 'Lexend Mega',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (displayCredits != null)
                      _chip('$displayCredits credits'),
                    if (entry.selectedOption?.electiveStream != null)
                      _chip(entry.selectedOption!.electiveStream!),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showEditSheet(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.black.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElectiveDropdown(_SubjectEntry entry, int index) {
    final options = _electiveOptions[entry.subject.optionsFrom] ?? [];
    final currentValue = entry.selectedOption ?? _findMatchingOption(entry, options);

    return SearchableDropdown<CurriculumSubject>(
      items: options,
      value: currentValue,
      labelBuilder: (opt) =>
          '${opt.subjectName}${opt.electiveStream != null ? '  (${opt.electiveStream})' : ''}',
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.7),
        hintText: 'Type or select a subject',
        hintStyle: const TextStyle(
          fontFamily: 'Public Sans',
          fontSize: 13,
          color: Colors.black54,
        ),
      ),
      onChanged: (selected) {
        setState(() {
          _entries[index] = _SubjectEntry(
            subject: entry.subject,
            selectedOption: selected,
          );
        });
      },
    );
  }

  CurriculumSubject? _findMatchingOption(_SubjectEntry entry, List<CurriculumSubject> options) {
    final name = entry.editedName ?? entry.subject.subjectName;
    return options.where((o) => o.subjectName == name).firstOrNull;
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Public Sans',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _SubjectEntry {
  final CurriculumSubject subject;
  final String? editedName;
  final int? editedCredits;
  final CurriculumSubject? selectedOption;

  _SubjectEntry({
    required this.subject,
    this.editedName,
    this.editedCredits,
    this.selectedOption,
  });
}
