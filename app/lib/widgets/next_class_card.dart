import 'package:flutter/material.dart';
import 'dart:math' as math;

class NextClassCard extends StatelessWidget {
  final String subject;
  final String room;
  final String block;
  final String startTime;
  final String endTime;

  const NextClassCard({
    super.key,
    required this.subject,
    required this.room,
    required this.block,
    required this.startTime,
    required this.endTime,
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
              // "Next Class" label
              const Text(
                'NEXT CLASS',
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              // Subject name
              Text(
                subject,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 8),

              // Room and block
              Text(
                '$room • $block',
                style: const TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.43,
                ),
              ),
              const SizedBox(height: 16),

              // Time info
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
                      '$startTime - $endTime',
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
            ],
          ),

          // Book illustration (top right)
          Positioned(
            right: 10,
            top: 10,
            child: Image.asset(
              'assets/images/book_illustration.png',
              width: screenWidth * 0.26,
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.menu_book,
                  size: 70,
                  color: Colors.orange,
                );
              },
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
