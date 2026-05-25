import '../models/api_models.dart';
import 'api_service.dart';

class CollegeService {
  Future<List<College>> listColleges() async {
    final json = await ApiService.instance.get('/colleges') as List<dynamic>;
    return json.map((item) => College.fromJson(item as Map<String, dynamic>)).toList();
  }
}
