// lib/features/weekly_plan/data/datasources/weekly_plan_remote_datasource.dart
//
// FIX: OfficerNameResolver was constructed with orgContext.effectiveOrgId
// which is the branch org ID. Officers are members of the ROOT org, so the
// /orgs/{id}/members fetch was returning only branch members (often empty),
// causing an empty cache and no name resolution.
//
// Fix: pass orgContext.rootOrgId ?? orgContext.effectiveOrgId to the resolver.

import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/utils/officer_name_resolver.dart';
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
  late final OfficerNameResolver _nameResolver;

  WeeklyPlanRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  })  : _dio = dio,
        _orgContext = orgContext {
    _nameResolver = OfficerNameResolver(
      dio: dio,
      // FIX: use root org so all officers in the tree are in the cache.
      orgId: () => orgContext.rootOrgId ?? orgContext.effectiveOrgId,
    );
  }

  String get _orgId => _orgContext.effectiveOrgId;
  String get _orgBase => '/pharma/orgs/$_orgId/plans';

  @override
  Future<List<WeeklyPlanModel>> getAll() async {
    try {
      await _nameResolver.warmUp();
      final response = await _dio.get(_orgBase);
      final raw = response.data;
      final data = (raw is Map ? (raw['data'] ?? []) : raw) as List? ?? [];
      return Future.wait(
        data.whereType<Map<String, dynamic>>().map(
              (j) async =>
                  WeeklyPlanModel.fromJson(await _nameResolver.inject(j)),
            ),
      );
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<WeeklyPlanModel> getById(String id) async {
    try {
      await _nameResolver.warmUp();
      final response = await _dio.get('/pharma/plans/$id');
      final raw = response.data;
      final data = (raw is Map ? (raw['data'] ?? raw['plan'] ?? raw) : raw)
          as Map<String, dynamic>;
      return WeeklyPlanModel.fromJson(await _nameResolver.inject(data));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<WeeklyPlanModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(_orgBase, data: data);
      final body =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      return WeeklyPlanModel.fromJson(await _nameResolver.inject(body));
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
      final body =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      return WeeklyPlanModel.fromJson(await _nameResolver.inject(body));
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
      final body =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      return WeeklyPlanModel.fromJson(await _nameResolver.inject(body));
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
      final body =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      return WeeklyPlanModel.fromJson(await _nameResolver.inject(body));
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