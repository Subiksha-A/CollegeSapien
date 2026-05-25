import 'package:flutter/material.dart';
import 'dart:math' as math;

class AttendanceCard extends StatelessWidget {
  final int percentage;
  final int safeToSkip;

  const AttendanceCard({
    super.key,
    required this.percentage,
    required this.safeToSkip,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD966),
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            offset: Offset(4, 4),
            color: Colors.black,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background decorative stripes
          ..._buildDecorativeStripes(),

          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Current Attendance" label
              const Text(
                'CURRENT ATTENDANCE',
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),

              // Large percentage display
              FittedBox(
                fit: BoxFit.scaleDown,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 0.9,
                    ),
                    children: [
                      TextSpan(
                        text: percentage.toString(),
                        style: const TextStyle(
                          fontSize: 90,
                          letterSpacing: -5,
                        ),
                      ),
                      const TextSpan(
                        text: '%',
                        style: TextStyle(
                          fontSize: 56,
                          letterSpacing: -3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Safe to skip info
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Safe To Skip : $safeToSkip Classes',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              _buildProgressBar(),
            ],
          ),

          // Target illustration (top right)
          Positioned(
            right: 10,
            top: 10,
            child: Image.asset(
              'assets/images/target_illustration.png',
              width: screenWidth * 0.28,
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.track_changes,
                  size: 80,
                  color: Colors.orange,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 27,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 0),
            blurRadius: 29.1,
            color: Colors.black.withOpacity(0.07),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Filled portion
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth * (percentage / 100);
              return Container(
                width: width,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.only(left: 9, right: 4),
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontFamily: 'Patrick Hand',
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),

          // Star icon on the right
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDecorativeStripes() {
    return [
      Positioned(
        left: -114.5,
        top: -112.5,
        child: Transform.rotate(
          angle: -39 * math.pi / 180,
          child: Container(
            width: 22.17,
            height: 416.391,
            color: const Color(0xFFFCD150).withOpacity(0.52),
          ),
        ),
      ),
      Positioned(
        left: -114.5 + 33.44,
        top: -112.5 + 43,
        child: Transform.rotate(
          angle: -39 * math.pi / 180,
          child: Container(
            width: 42.045,
            height: 416.391,
            color: const Color(0xFFFCD150).withOpacity(0.52),
          ),
        ),
      ),
      Positioned(
        left: -114.5 + 1.5,
        top: -112.5 + 90.83,
        child: Transform.rotate(
          angle: -39 * math.pi / 180,
          child: Container(
            width: 60.386,
            height: 416.391,
            color: const Color(0xFFFCD150).withOpacity(0.52),
          ),
        ),
      ),
      Positioned(
        left: -114.5 + 446.03,
        top: -112.5 + 69.77,
        child: Transform.rotate(
          angle: -39 * math.pi / 180,
          child: Container(
            width: 43.627,
            height: 153.136,
            color: const Color(0xFFFCD150).withOpacity(0.52),
          ),
        ),
      ),
      Positioned(
        left: -114.5 + 333.5,
        top: -112.5 + 1.5,
        child: Transform.rotate(
          angle: -39 * math.pi / 180,
          child: Container(
            width: 17.74,
            height: 416.391,
            color: const Color(0xFFFCD150).withOpacity(0.52),
          ),
        ),
      ),
    ];
  }
}
