import 'package:flutter/material.dart';
import 'dart:math' as math;

class TimetableCard extends StatelessWidget {
  final String time;
  final String subject;
  final String location;
  final Color color;

  const TimetableCard({
    super.key,
    required this.time,
    required this.subject,
    required this.location,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          const BoxShadow(
            offset: Offset(4, 4),
            color: Colors.black,
          ),
          BoxShadow(
            offset: const Offset(0, 8),
            blurRadius: 24,
            color: const Color(0xFF003FB1).withOpacity(0.12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background halftone pattern - decorative only
          Positioned(
            left: -40,
            top: -60,
            child: Transform.scale(
              scaleY: -1,
              child: Transform.rotate(
                angle: 48 * math.pi / 180,
                child: Opacity(
                  opacity: 0.04,
                  child: Image.asset(
                    'assets/images/halftone.png',
                    width: 289.272,
                    height: 176.1,
                    fit: BoxFit.cover,
                    color: Colors.black,
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ),
                ),
              ),
            ),
          ),

          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),

              // Subject
              Text(
                subject,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // Location
              Text(
                location,
                style: const TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.43,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
