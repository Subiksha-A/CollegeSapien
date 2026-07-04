import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_models.dart';
import '../utils/department_constants.dart';
import 'api_service.dart';

class CollegeService {
  static List<College>? _cachedColleges;
  static List<Department>? _cachedDepartments;

  static const String _cacheKeyData = 'combined_masters_data';
  static const String _cacheKeyTime = 'combined_masters_timestamp';
  static const Duration _cacheTtl = Duration(hours: 24);

  // Fallback colleges in case of offline & empty cache on first boot
  static const List<Map<String, String>> _fallbackColleges = [
    {'id': 'col_ssn', 'name': 'SSN College of Engineering', 'code': 'SSN'},
    {'id': 'col_aua', 'name': 'Anna University Affiliated', 'code': 'AUA'},
    {'id': 'col_panimalar', 'name': 'Panimalar Engineering College', 'code': 'PEC'},
    {'id': 'col_sairam', 'name': 'Sri Sairam Engineering College', 'code': 'SEC'},
  ];

  Future<void> fetchCombinedMasters({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedColleges != null && _cachedDepartments != null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cachedJson = prefs.getString(_cacheKeyData);
      final cachedTimeMs = prefs.getInt(_cacheKeyTime);
      if (cachedJson != null && cachedTimeMs != null) {
        final cachedTime = DateTime.fromMillisecondsSinceEpoch(cachedTimeMs);
        if (DateTime.now().difference(cachedTime) < _cacheTtl) {
          try {
            _parseCombinedJson(jsonDecode(cachedJson) as Map<String, dynamic>);
            return;
          } catch (e) {
            // Cache corrupted, ignore and proceed to fetch
          }
        }
      }
    }

    try {
      final response = await ApiService.instance.get('/colleges/combined') as Map<String, dynamic>;
      _parseCombinedJson(response);
      // Save cache
      await prefs.setString(_cacheKeyData, jsonEncode(response));
      await prefs.setInt(_cacheKeyTime, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Offline / API error fallback:
      // 1. Try to read expired cache
      final cachedJson = prefs.getString(_cacheKeyData);
      if (cachedJson != null) {
        try {
          _parseCombinedJson(jsonDecode(cachedJson) as Map<String, dynamic>);
          return;
        } catch (_) {}
      }

      // 2. Final fallback: Use local constants/defaults
      _cachedColleges = _fallbackColleges
          .map((c) => College(id: c['id']!, name: c['name']!, code: c['code']!))
          .toList();
      _cachedDepartments = defaultDepartments;
    }
  }

  void _parseCombinedJson(Map<String, dynamic> json) {
    final collegesList = json['colleges'] as List<dynamic>? ?? [];
    final deptsList = json['departments'] as List<dynamic>? ?? [];

    _cachedColleges = collegesList
        .map((item) => College.fromJson(item as Map<String, dynamic>))
        .toList();
    _cachedDepartments = deptsList
        .map((item) => Department.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<College>> listColleges() async {
    await fetchCombinedMasters();
    return _cachedColleges ?? [];
  }

  Future<List<Department>> listDepartments() async {
    await fetchCombinedMasters();
    return _cachedDepartments ?? [];
  }
}
