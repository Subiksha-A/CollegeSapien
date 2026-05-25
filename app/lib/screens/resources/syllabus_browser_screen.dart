import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/api_models.dart';
import '../../services/resource_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';

class SyllabusBrowserScreen extends StatefulWidget {
  const SyllabusBrowserScreen({super.key});

  @override
  State<SyllabusBrowserScreen> createState() => _SyllabusBrowserScreenState();
}

class _SyllabusBrowserScreenState extends State<SyllabusBrowserScreen> {
  final _resourceService = ResourceService();
  late Future<List<HubResource>> _future;
  double? _uploadProgress;
  final _searchController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedRegulation;
  final _subjectCodeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _regulationController = TextEditingController();
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _resourceService.listSyllabus();
  }

  void _refresh() {
    setState(() {
      _future = _resourceService.listSyllabus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _subjectCodeController.dispose();
    _departmentController.dispose();
    _regulationController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    _subjectCodeController.clear();
    _departmentController.clear();
    _regulationController.clear();
    _titleController.clear();

    final uploadData = await showModalBottomSheet<Map<String, String>>(
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
              const Text('Upload Syllabus',
                  style: TextStyle(
                      fontFamily: 'Lexend Mega',
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: _subjectCodeController,
                decoration: InputDecoration(
                  labelText: 'Subject Code',
                  hintText: 'e.g., CS3401',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _departmentController,
                decoration: InputDecoration(
                  labelText: 'Department',
                  hintText: 'e.g., Computer Science',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _regulationController,
                decoration: InputDecoration(
                  labelText: 'Regulation',
                  hintText: 'e.g., R2021',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Document Title',
                  hintText: 'e.g., Syllabus 2023',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, {
                      'subjectCode': _subjectCodeController.text.trim(),
                      'department': _departmentController.text.trim(),
                      'regulation': _regulationController.text.trim(),
                      'title': _titleController.text.trim(),
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (uploadData == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final file = result?.files.single;
    if (file?.path == null) return;

    if (mounted) setState(() => _uploadProgress = 0.0);
    try {
      await _resourceService.uploadLocalFile(
        filePath: file!.path!,
        fileName: file.name,
        title: uploadData['title'] ?? file.name,
        category: 'Syllabus',
        mimeType: file.extension == 'pdf'
            ? 'application/pdf'
            : 'image/${file.extension}',
        subjectId: uploadData['subjectCode'],
        regulation: uploadData['regulation'],
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      if (mounted) setState(() => _uploadProgress = null);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Uploaded for moderation.'),
            backgroundColor: Colors.green),
      );
      _refresh();
    } catch (e) {
      if (mounted) setState(() => _uploadProgress = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'Syllabus Browser',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            letterSpacing: 0,
          ),
        ),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.black),
            onPressed: _pickAndUpload,
          ),
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _refresh),
        ],
      ),
      body: Column(
        children: [
          if (_uploadProgress != null)
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.grey.shade200,
              color: Colors.black,
              minHeight: 4,
            ),
          Expanded(
            child: SafeArea(
              child: FutureBuilder<List<HubResource>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }

                  final allItems = snapshot.data ?? [];
                  final departments = allItems
                      .map((r) => r.department)
                      .whereType<String>()
                      .toSet()
                      .toList()
                    ..sort();
                  final regulations = allItems
                      .map((r) => r.regulation)
                      .whereType<String>()
                      .toSet()
                      .toList()
                    ..sort();

                  final query = _searchController.text.toLowerCase();
                  final items = allItems
                      .where((r) {
                        final matchesSearch = query.isEmpty ||
                            r.name.toLowerCase().contains(query);
                        final matchesDept = _selectedDepartment == null ||
                            r.department == _selectedDepartment;
                        final matchesReg = _selectedRegulation == null ||
                            r.regulation == _selectedRegulation;
                        return matchesSearch && matchesDept && matchesReg;
                      })
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Search field
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search syllabus...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (departments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          value: _selectedDepartment,
                          decoration: InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Departments'),
                            ),
                            ...departments.map(
                              (dept) => DropdownMenuItem<String?>(
                                value: dept,
                                child:
                                    Text(dept, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedDepartment = v),
                        ),
                      ],
                      if (regulations.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          value: _selectedRegulation,
                          decoration: InputDecoration(
                            labelText: 'Regulation',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Regulations'),
                            ),
                            ...regulations.map(
                              (reg) => DropdownMenuItem<String?>(
                                value: reg,
                                child: Text(reg, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedRegulation = v),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration:
                              AppTheme.cardDecoration(color: AppColors.accentGreen),
                          child: const Text('No syllabus documents found.'),
                        )
                      else
                        ...items.map(_buildSyllabusCard),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyllabusCard(HubResource item) {
    final url = item.fileUrl;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(color: AppColors.accentGreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(
              fontFamily: 'Lexend Mega',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (item.department != null) ...[
            const SizedBox(height: 8),
            Text(item.department!),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: url == null
                ? null
                : () => launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.download, size: 18, color: Colors.black),
            label: const Text('Open', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}
