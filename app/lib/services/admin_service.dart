import '../models/api_models.dart';
import 'api_service.dart';

class AdminService {
  AdminService._();

  static final AdminService instance = AdminService._();

  Future<List<AdminReport>> listPendingReports() async {
    final json =
        await ApiService.instance.get('/admin/reports') as List<dynamic>;
    return json
        .map((item) => AdminReport.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> resolveReport({
    required String reportId,
    required String action,
  }) async {
    await ApiService.instance
        .patch('/admin/reports/$reportId/resolve', {'action': action});
  }

  Future<List<AdminUser>> listUsers() async {
    final json = await ApiService.instance.get('/admin/users') as List<dynamic>;
    return json
        .map((item) => AdminUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> assignRole({
    required String uid,
    required String role,
    String? collegeId,
  }) async {
    await ApiService.instance.post('/admin/assign-role', {
      'uid': uid,
      'role': role,
      if (collegeId != null && collegeId.isNotEmpty) 'collegeId': collegeId,
    });
  }
}
