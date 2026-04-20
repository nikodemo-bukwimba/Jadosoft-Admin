import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/context/org_context.dart';
import '../models/weekly_plan_model.dart';

abstract class WeeklyPlanRemoteDataSource {
  Future<List<WeeklyPlanModel>> getAll();
  Future<WeeklyPlanModel> getById(String id);
  Future<WeeklyPlanModel> create(Map<String, dynamic> data);
  Future<WeeklyPlanModel> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<WeeklyPlanModel> approve(String id, {String? notes});
  Future<WeeklyPlanModel> reject(String id, {required String notes});
}

class WeeklyPlanRemoteDataSourceImpl implements WeeklyPlanRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;

  /// actorId → display name, same pattern as VisitApiDataSource.
  final Map<String, String> _officerNameCache = {};

  WeeklyPlanRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  }) : _dio = dio,
       _orgContext = orgContext;

  String get _orgId => _orgContext.effectiveOrgId;
  String get _orgBase => '/pharma/orgs/$_orgId/plans';

  // ── Fetch officer name map from org members ──────────────────────────
  // Mirrors VisitApiDataSource._refreshOfficerNames()
  Future<void> _refreshOfficerNames() async {
    try {
      final response = await _dio.get(
        '/orgs/$_orgId/members',
        queryParameters: {'per_page': 200},
      );
      final raw = response.data;
      final list = (raw is Map ? (raw['data'] ?? []) : raw) as List? ?? [];
      _officerNameCache.clear();
      for (final item in list.whereType<Map<String, dynamic>>()) {
        final user = item['user'] as Map<String, dynamic>?;
        if (user == null) continue;
        final actorId = (user['actor_id'] ?? item['actor_id'] ?? '').toString();
        if (actorId.isEmpty) continue;
        final name =
            (user['username'] as String?)?.trim() ??
            (user['name'] as String?)?.trim() ??
            (user['email'] as String?)?.split('@').first ??
            '';
        if (name.isNotEmpty) _officerNameCache[actorId] = name;
      }
    } catch (_) {
      // Non-fatal — plans still load, officer column shows actor ID.
    }
  }

  // ── Inject resolved officer_name into raw plan JSON ───────────────────
  Map<String, dynamic> _injectOfficerName(Map<String, dynamic> j) {
    if (j['officer_name'] is String &&
        (j['officer_name'] as String).isNotEmpty) {
      return j; // API already sent a name — use it
    }
    final actorId = (j['officer_actor_id'] ?? j['officer_id'] ?? '').toString();
    final resolved = actorId.isNotEmpty ? _officerNameCache[actorId] : null;
    if (resolved == null) return j;
    return {...j, 'officer_name': resolved};
  }

  @override
  Future<List<WeeklyPlanModel>> getAll() async {
    try {
      await _refreshOfficerNames();
      final response = await _dio.get(_orgBase);
      final raw = response.data;
      final data = (raw is Map ? (raw['data'] ?? raw) : raw) as List? ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((j) => WeeklyPlanModel.fromJson(_injectOfficerName(j)))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<WeeklyPlanModel> getById(String id) async {
    try {
      if (_officerNameCache.isEmpty) await _refreshOfficerNames();
      final response = await _dio.get('/pharma/plans/$id');
      final raw = response.data;
      final data =
          (raw is Map ? (raw['data'] ?? raw['plan'] ?? raw) : raw)
              as Map<String, dynamic>;
      return WeeklyPlanModel.fromJson(_injectOfficerName(data));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<WeeklyPlanModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(_orgBase, data: data);
      final body = response.data['data'] ?? response.data;
      return WeeklyPlanModel.fromJson(body as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<WeeklyPlanModel> update(String id, Map<String, dynamic> data) async {
    final newStatus = data['status'] as String?;
    try {
      late final Response response;
      if (newStatus == 'approved') {
        response = await _dio.post('/pharma/plans/$id/approve');
      } else if (newStatus == 'rejected') {
        final reviewNotes = data['review_notes'] as String?;
        response = await _dio.post(
          '/pharma/plans/$id/reject',
          data: reviewNotes != null ? {'reason': reviewNotes} : null,
        );
      } else {
        return await getById(id);
      }
      final body = response.data['data'] ?? response.data;
      return WeeklyPlanModel.fromJson(
        _injectOfficerName(body as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('$_orgBase/$id');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<WeeklyPlanModel> approve(String id, {String? notes}) async {
    try {
      final response = await _dio.post(
        '/pharma/plans/$id/approve',
        data: notes != null ? {'notes': notes} : {},
      );
      final body = response.data['data'] ?? response.data;
      return WeeklyPlanModel.fromJson(
        _injectOfficerName(body as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<WeeklyPlanModel> reject(String id, {required String notes}) async {
    try {
      final response = await _dio.post(
        '/pharma/plans/$id/reject',
        data: {'notes': notes},
      );
      final body = response.data['data'] ?? response.data;
      return WeeklyPlanModel.fromJson(
        _injectOfficerName(body as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'An error occurred. Please try again.';
  }
}
