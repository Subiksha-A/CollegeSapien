import 'package:flutter/material.dart';

class CommunityFeedCard extends StatelessWidget {
  final String tag;
  final String title;
  final String sharedBy;

  const CommunityFeedCard({
    super.key,
    required this.tag,
    required this.title,
    required this.sharedBy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFB6EAFF),
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
          // Background pattern - decorative only, skip if images fail to load

          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF9191FF),
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
                  tag,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.14,
                    color: Color(0xFF191C1E),
                    height: 1.43,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1,
                  color: Colors.black,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Shared by
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.black, width: 1),
                      boxShadow: const [
                        BoxShadow(
                          offset: Offset(2, 2),
                          color: Colors.black,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        'assets/images/profile.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          letterSpacing: -0.5,
                          height: 1.2,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: 'Shared By ',
                            style: TextStyle(
                              fontWeight: FontWeight.w300,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                          TextSpan(
                            text: sharedBy,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
