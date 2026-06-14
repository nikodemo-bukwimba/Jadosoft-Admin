// lib/features/daily_report/data/datasources/daily_report_remote_datasource.dart
//
// FIX: same root org fix applied — resolver must fetch from rootOrgId
// so all officers across the tree are in the name cache.

import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/utils/officer_name_resolver.dart';
import '../models/daily_report_model.dart';

abstract class DailyReportRemoteDataSource {
  Future<List<DailyReportModel>> getAll();
  Future<DailyReportModel> getById(String id);
  Future<DailyReportModel> create(Map<String, dynamic> data);
  Future<DailyReportModel> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<DailyReportModel> approve(String id, {String? feedback});
  Future<DailyReportModel> reject(String id, {required String feedback});
}

class DailyReportRemoteDataSourceImpl implements DailyReportRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;
  late final OfficerNameResolver _nameResolver;

  DailyReportRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  }) : _dio = dio,
       _orgContext = orgContext {
    _nameResolver = OfficerNameResolver(
      dio: dio,
      // FIX: use root org so all officers in the tree are in the cache.
      orgId: () => orgContext.rootOrgId ?? orgContext.effectiveOrgId,
    );
  }

  String get _base => '/pharma/orgs/${_orgContext.effectiveOrgId}/reports';

  @override
  Future<List<DailyReportModel>> getAll() async {
    try {
      await _nameResolver.warmUp();
      final response = await _dio.get(_base);
      final raw = response.data;
      final list = (raw is Map ? (raw['data'] ?? []) : raw) as List? ?? [];
      return Future.wait(
        list.whereType<Map<String, dynamic>>().map(
          (e) async => DailyReportModel.fromJson(await _nameResolver.inject(e)),
        ),
      );
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<DailyReportModel> getById(String id) async {
    try {
      await _nameResolver.warmUp();
      final response = await _dio.get('/pharma/reports/$id');
      final raw = response.data;
      final data =
          (raw is Map ? (raw['data'] ?? raw['report'] ?? raw) : raw)
              as Map<String, dynamic>;
      return DailyReportModel.fromJson(await _nameResolver.inject(data));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<DailyReportModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(_base, data: data);
      final body =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      return DailyReportModel.fromJson(await _nameResolver.inject(body));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<DailyReportModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('$_base/$id', data: data);
      final body =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      return DailyReportModel.fromJson(await _nameResolver.inject(body));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('$_base/$id');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<DailyReportModel> approve(String id, {String? feedback}) async {
    try {
      final response = await _dio.post(
        '/pharma/reports/$id/approve',
        data: (feedback != null && feedback.trim().isNotEmpty)
            ? {'notes': feedback.trim()}
            : null,
      );
      final body =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      return DailyReportModel.fromJson(await _nameResolver.inject(body));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<DailyReportModel> reject(String id, {required String feedback}) async {
    try {
      final response = await _dio.post(
        '/pharma/reports/$id/reject',
        data: {'notes': feedback},
      );
      final body =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      return DailyReportModel.fromJson(await _nameResolver.inject(body));
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
