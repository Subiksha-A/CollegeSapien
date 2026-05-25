import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _departmentController;
  late final TextEditingController _semesterController;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _departmentController = TextEditingController();
    _semesterController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await AuthService.instance.syncProfile();
      if (!mounted) return;
      final profile = result.user;
      if (profile != null) {
        _departmentController.text = profile.department ?? '';
        _semesterController.text =
            profile.semester > 0 ? profile.semester.toString() : '';
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final body = <String, dynamic>{};
      if (_nameController.text.trim().isNotEmpty) {
        body['name'] = _nameController.text.trim();
      }
      if (_departmentController.text.trim().isNotEmpty) {
        body['department'] = _departmentController.text.trim();
      }
      final sem = int.tryParse(_semesterController.text.trim());
      if (sem != null) body['semester'] = sem;

      await ApiService.instance.patch('/auth/me', body);

      if (_nameController.text.trim().isNotEmpty) {
        await FirebaseAuth.instance.currentUser
            ?.updateDisplayName(_nameController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
                      TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _semesterController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Semester (1–10)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final n = int.tryParse(v.trim());
                          if (n == null || n < 1 || n > 10)
                            return 'Enter a semester between 1 and 10';
                          return null;
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
