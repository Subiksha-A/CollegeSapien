import 'package:flutter/material.dart';
import '../models/timetable_models.dart';
import '../services/cache_service.dart';
import '../services/timetable_service.dart';
import 'timetable_detail_screen.dart';

class TimetableListScreen extends StatefulWidget {
  const TimetableListScreen({super.key});

  @override
  State<TimetableListScreen> createState() => _TimetableListScreenState();
}

class _TimetableListScreenState extends State<TimetableListScreen> {
  final TimetableService _timetableService = TimetableService();
  List<TimetableSubject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final cached =
        CacheService.instance.get<List<TimetableSubject>>('timetable_subjects');
    if (cached != null) {
      _subjects = cached;
      _isLoading = false;
    }
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    if (_subjects.isEmpty) setState(() => _isLoading = true);
    try {
      final subjects = await _timetableService.getAllSubjects();
      CacheService.instance.set('timetable_subjects', subjects);
      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subjects: $e')),
        );
      }
    }
  }

  Future<void> _showSubjectSheet({TimetableSubject? subject}) async {
    final isEditing = subject != null;
    final nameController = TextEditingController(text: subject?.name ?? '');
    final codeController = TextEditingController(text: subject?.code ?? '');

    final List<Map<String, String>> slots = subject?.classes
            .map((c) => {
                  'day': c.day,
                  'startTime': c.startTime,
                  'endTime': c.endTime,
                  'room': c.room,
                  'type': c.type,
                })
            .toList() ??
        [];

    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final types = ['CORE', 'LAB', 'BREAK'];
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF8E4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Colors.black, width: 2),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> addSlot() async {
              String selectedDay = days.first;
              String selectedType = types.first;
              final startController = TextEditingController(text: '09:00');
              final endController = TextEditingController(text: '10:00');
              final roomController = TextEditingController();

              final confirmed = await showDialog<bool>(
                context: ctx,
                builder: (dlgCtx) => AlertDialog(
                  backgroundColor: const Color(0xFFFFF8E4),
                  title: const Text(
                    'Add Class Slot',
                    style: TextStyle(fontFamily: 'Lexend Mega', fontSize: 16),
                  ),
                  content: StatefulBuilder(
                    builder: (dlgCtx, setDlgState) => SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: selectedDay,
                            decoration: const InputDecoration(labelText: 'Day'),
                            items: days
                                .map((d) =>
                                    DropdownMenuItem(value: d, child: Text(d)))
                                .toList(),
                            onChanged: (v) =>
                                setDlgState(() => selectedDay = v!),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: startController,
                            decoration: const InputDecoration(
                                labelText: 'Start Time (HH:MM)'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: endController,
                            decoration: const InputDecoration(
                                labelText: 'End Time (HH:MM)'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: roomController,
                            decoration: const InputDecoration(
                                labelText: 'Room (optional)'),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            decoration:
                                const InputDecoration(labelText: 'Type'),
                            items: types
                                .map((t) =>
                                    DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (v) =>
                                setDlgState(() => selectedType = v!),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dlgCtx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dlgCtx, true),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                setSheetState(() {
                  slots.add({
                    'day': selectedDay,
                    'startTime': startController.text.trim(),
                    'endTime': endController.text.trim(),
                    'room': roomController.text.trim(),
                    'type': selectedType,
                  });
                });
              }
            }

            Future<void> saveSubject() async {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              if (name.isEmpty || code.isEmpty) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Subject name and code are required.')),
                  );
                }
                return;
              }

              setSheetState(() => isSaving = true);

              try {
                final classes = slots.map((s) {
                  final start = s['startTime'] ?? '09:00';
                  return TimetableClass(
                    day: s['day'] ?? 'MON',
                    startTime: start,
                    endTime: s['endTime'] ?? start,
                    period: (int.tryParse(start.split(':').first) ?? 9) >= 12
                        ? 'PM'
                        : 'AM',
                    room: s['room'] ?? '',
                    type: s['type'] ?? 'CORE',
                    duration: 1,
                  );
                }).toList();

                final newSubject = TimetableSubject(
                  id: isEditing
                      ? subject.id
                      : code.toLowerCase().replaceAll(' ', '_'),
                  name: name,
                  code: code,
                  classes: classes,
                );

                final existing = await _timetableService.getAllSubjects();
                final List<TimetableSubject> merged;
                if (isEditing) {
                  merged = existing
                      .map((s) => s.id == subject.id ? newSubject : s)
                      .toList();
                } else {
                  merged = [...existing, newSubject];
                }
                await _timetableService.saveSubjects(merged);
                CacheService.instance.set('timetable_subjects', merged);

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() => _subjects = merged);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing
                          ? 'Subject updated successfully!'
                          : 'Subject added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  setSheetState(() => isSaving = false);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error saving subject: $e')),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEditing ? 'Edit Subject' : 'Add Subject',
                      style: const TextStyle(
                        fontFamily: 'Lexend Mega',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Class Slots',
                          style: TextStyle(
                            fontFamily: 'Public Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: addSlot,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Slot'),
                        ),
                      ],
                    ),
                    if (slots.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No class slots added yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...slots.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${s['day']} ${s['startTime']}–${s['endTime']}',
                            style: const TextStyle(
                                fontFamily: 'Public Sans',
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${s['type']}${s['room']!.isNotEmpty ? ' · ${s['room']}' : ''}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                setSheetState(() => slots.removeAt(i)),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveSubject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD966),
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : Text(
                                isEditing ? 'Update Subject' : 'Save Subject',
                                style: const TextStyle(
                                  fontFamily: 'Public Sans',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeSubject(TimetableSubject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: const Text(
          'Remove Subject',
          style: TextStyle(fontFamily: 'Lexend Mega', fontSize: 16),
        ),
        content: Text('Remove "${subject.name}" from your timetable?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final existing = await _timetableService.getAllSubjects();
      final updated = existing.where((s) => s.id != subject.id).toList();
      await _timetableService.saveSubjects(updated);
      CacheService.instance.set('timetable_subjects', updated);
      setState(() => _subjects = updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Subject removed.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing subject: $e')),
        );
      }
    }
  }

  void _openTimetableDetail(TimetableSubject subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimetableDetailScreen(subject: subject),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFEEEC3),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.045,
                    vertical: 20,
                  ),
                  child: _buildHeader(screenWidth),
                ),

                // Subject cards list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _subjects.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.045,
                              ).copyWith(
                                bottom:
                                    100 + MediaQuery.of(context).padding.bottom,
                              ),
                              itemCount: _subjects.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _buildSubjectCard(
                                    _subjects[index],
                                    screenWidth,
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),

            // Floating Action Button for adding a subject manually
            Positioned(
              right: 20,
              bottom: 20,
              child: _buildAddButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    return const Row(
      children: [
        Icon(Icons.calendar_today, size: 24, color: Colors.black),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Time Table',
            style: TextStyle(
              fontFamily: 'Lexend Mega',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(TimetableSubject subject, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD966),
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(offset: Offset(4, 4), color: Colors.black),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _openTimetableDetail(subject),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.code,
                        style: const TextStyle(
                          fontFamily: 'Lexend Mega',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subject.name,
                        style: TextStyle(
                          fontFamily: 'Public Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: Colors.black.withValues(alpha: 0.8),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _showSubjectSheet(subject: subject),
                    child: const Icon(Icons.edit_outlined,
                        size: 20, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _removeSubject(subject),
                    child: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _openTimetableDetail(subject),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.black),
                const SizedBox(width: 8),
                Text(
                  '${subject.classes.length} classes per week',
                  style: const TextStyle(
                    fontFamily: 'Public Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month,
            size: 80,
            color: Colors.black.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No timetables yet',
            style: TextStyle(
              fontFamily: 'Public Sans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a subject',
            style: TextStyle(
              fontFamily: 'Public Sans',
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD966),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            offset: Offset(4, 4),
            color: Colors.black,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSubjectSheet(),
          customBorder: const CircleBorder(),
          child: const Icon(
            Icons.add,
            size: 28,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
