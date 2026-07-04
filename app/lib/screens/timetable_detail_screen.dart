import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/timetable_models.dart';

class TimetableDetailScreen extends StatefulWidget {
  final TimetableSubject subject;

  const TimetableDetailScreen({
    super.key,
    required this.subject,
  });

  @override
  State<TimetableDetailScreen> createState() => _TimetableDetailScreenState();
}

class _TimetableDetailScreenState extends State<TimetableDetailScreen> {
  String _selectedDay = 'MON';

  final List<DaySchedule> _days = [
    DaySchedule(day: 'MON', date: 12, isToday: true),
    DaySchedule(day: 'TUE', date: 12, isToday: false),
    DaySchedule(day: 'WED', date: 12, isToday: false),
    DaySchedule(day: 'THU', date: 12, isToday: false),
    DaySchedule(day: 'FRI', date: 12, isToday: false),
    DaySchedule(day: 'SAT', date: 12, isToday: false),
    DaySchedule(day: 'SUN', date: 12, isToday: false),
  ];

  List<TimetableClass> get _selectedDayClasses {
    return widget.subject.classes.where((c) => c.day == _selectedDay).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFEEEC3),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 20 + MediaQuery.of(context).padding.bottom,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.045,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(screenWidth),
                const SizedBox(height: 30),

                // Day selector
                _buildDaySelector(),
                const SizedBox(height: 30),

                // Timeline with classes
                _buildTimeline(screenWidth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 24, color: Colors.black),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            size: 24,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
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

  Widget _buildDaySelector() {
    return Row(
      children: _days
          .map((day) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildDayButton(day),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDayButton(DaySchedule day) {
    final isSelected = _selectedDay == day.day;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day.day;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD966) : const Color(0xFFFFF8E4),
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              offset: Offset(2, 2),
              color: Colors.black,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              day.day,
              style: TextStyle(
                fontFamily: 'Public Sans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.14,
                color: Colors.black.withValues(alpha: 0.5),
                height: 1.07,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              day.date.toString(),
              style: const TextStyle(
                fontFamily: 'Public Sans',
                fontSize: 21,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 1.43,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(double screenWidth) {
    if (_selectedDayClasses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            'No classes scheduled for $_selectedDay',
            style: TextStyle(
              fontFamily: 'Public Sans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _selectedDayClasses
          .map((cls) => Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: _buildClassRow(cls, screenWidth),
              ))
          .toList(),
    );
  }

  Widget _buildClassRow(TimetableClass cls, double screenWidth) {
    if (cls.type == 'BREAK') {
      return _buildBreakRow(cls, screenWidth);
    }

    // Determine if we should show connecting line above this class
    final classIndex = _selectedDayClasses.indexOf(cls);
    final showLineAbove = classIndex > 0;
    final showLineBelow = classIndex < _selectedDayClasses.length - 1;

    return Stack(
      children: [
        // Vertical connecting line
        if (showLineAbove)
          Positioned(
            left: 77, // Position aligned with time label
            top: -30,
            bottom: showLineBelow ? 0 : null,
            height: showLineBelow ? null : 60,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time label
            SizedBox(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    cls.startTime,
                    style: const TextStyle(
                      fontFamily: 'Public Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.14,
                      color: Colors.black,
                      height: 1.07,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cls.period,
                    style: TextStyle(
                      fontFamily: 'Public Sans',
                      fontSize: 14,
                      letterSpacing: -0.14,
                      color: Colors.black.withValues(alpha: 0.5),
                      height: 1.07,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 30),

            // Class card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E4),
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(0, 4),
                      color: Colors.black,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subject.name,
                            style: const TextStyle(
                              fontFamily: 'Public Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              color: Colors.black,
                              height: 1.67,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  cls.room,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Public Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                    height: 2.14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${cls.duration} Hour${cls.duration > 1 ? 's' : ''}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Public Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                    height: 2.14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(
                            offset: Offset(2, 2),
                            color: Colors.black,
                          ),
                        ],
                      ),
                      child: Text(
                        cls.type,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.12,
                          color: Color(0xFF191C1E),
                          height: 1.67,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakRow(TimetableClass cls, double screenWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time label
        SizedBox(
          width: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                cls.startTime,
                style: const TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.14,
                  color: Colors.black,
                  height: 1.07,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cls.period,
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 14,
                  letterSpacing: -0.14,
                  color: Colors.black.withValues(alpha: 0.5),
                  height: 1.07,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 30),

        // Break card with texture
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Halftone texture
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: Image.asset(
                      'assets/images/halftone.png',
                      fit: BoxFit.cover,
                      repeat: ImageRepeat.repeat,
                    ),
                  ),
                ),
                // Wave texture
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.08,
                    child: SvgPicture.asset(
                      'assets/images/wave_texture.svg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Content
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2FFB6), // Mint green color
                    border: Border.all(color: Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        offset: Offset(0, 4),
                        color: Colors.black,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.coffee,
                        size: 24,
                        color: Colors.black,
                      ),
                      SizedBox(width: 13),
                      Text(
                        'Break Time',
                        style: TextStyle(
                          fontFamily: 'Public Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          height: 1.67,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
