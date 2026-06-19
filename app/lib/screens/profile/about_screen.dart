import 'package:codesapiens/utils/app_constants.dart';
import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
        title: const Expanded(
          child: Text(
            'About',
            style: TextStyle(
              fontFamily: 'Lexend Mega',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: 0,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: AppTheme.cardDecoration(
                  color: AppColors.primaryYellow,
                  shadowOffset: const Offset(4, 4),
                ),
                child: const Icon(Icons.school, size: 50, color: Colors.black),
              ),
              const SizedBox(height: 24),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontFamily: 'Lexend Mega',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your university companion — attendance tracking, timetable management, and AI-powered tools built for students.',
                style: TextStyle(
                  fontFamily: 'Public Sans',
                  fontSize: 15,
                  color: Colors.black,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildInfoCard(
                'Features',
                AppColors.accentBlue,
                [
                  'Timetable scanning with AI',
                  'Attendance tracking per subject',
                  'CGPA calculator with credits',
                  'Notes & Question Paper hub',
                  'Pomodoro timer with tasks',
                  'Resume Roast AI feedback',
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Built with',
                AppColors.accentGreen,
                [
                  'Flutter (iOS & Android)',
                  'Firebase Cloud Functions',
                  'Google Gemini Vision API',
                  'Firebase Firestore & Storage',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, Color color, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(color: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Lexend Mega',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontFamily: 'Public Sans',
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
