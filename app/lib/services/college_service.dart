import '../models/api_models.dart';
import 'api_service.dart';

class CollegeService {
  static List<College>? _cachedColleges;

  Future<List<College>> listColleges() async {
    if (_cachedColleges != null) return _cachedColleges!;
    final json = await ApiService.instance.get('/colleges') as List<dynamic>;
    _cachedColleges = json
        .map((item) => College.fromJson(item as Map<String, dynamic>))
        .toList();
    return _cachedColleges!;
  }
}
