import 'package:flutter/material.dart';

class ResourceButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const ResourceButton({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD966),
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 4),
              color: Colors.black,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 24,
                color: Colors.black,
              ),
            ),

            // Title
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Arrow icon
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}
