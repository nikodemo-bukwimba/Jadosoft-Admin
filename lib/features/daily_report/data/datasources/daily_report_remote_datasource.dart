import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/context/org_context.dart';
import '../models/daily_report_model.dart';

abstract class DailyReportRemoteDataSource {
  Future<List<DailyReportModel>> getAll();
  Future<DailyReportModel> getById(String id);
  Future<DailyReportModel> create(Map<String, dynamic> data);
  Future<DailyReportModel> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<DailyReportModel> approve(String id, {required String feedback});
  Future<DailyReportModel> reject(String id, {required String feedback});
}

class DailyReportRemoteDataSourceImpl implements DailyReportRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;

  DailyReportRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  }) : _dio = dio,
       _orgContext = orgContext;

  String get _base => '/pharma/orgs/${_orgContext.effectiveOrgId}/reports';

  @override
  Future<List<DailyReportModel>> getAll() async {
    try {
      final response = await _dio.get(_base);
      final data = (response.data['data'] ?? response.data) as List;
      return data
          .map((e) => DailyReportModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<DailyReportModel> getById(String id) async {
    try {
      // Correct route: /pharma/reports/{id} not /pharma/orgs/{orgId}/reports/{id}
      final response = await _dio.get('/pharma/reports/$id');
      final data = response.data['data'] ?? response.data;
      return DailyReportModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<DailyReportModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(_base, data: data);
      final body = response.data['data'] ?? response.data;
      return DailyReportModel.fromJson(body as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<DailyReportModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('$_base/$id', data: data);
      final body = response.data['data'] ?? response.data;
      return DailyReportModel.fromJson(body as Map<String, dynamic>);
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
      // BEFORE (wrong): final response = await _dio.post('$_base/$id/approve', ...);
      // AFTER (correct):
      final response = await _dio.post(
        '/pharma/reports/$id/approve',
        data: {'notes': feedback},
      );
      final body = response.data['data'] ?? response.data;
      return DailyReportModel.fromJson(body as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<DailyReportModel> reject(String id, {required String feedback}) async {
    try {
      // BEFORE (wrong): final response = await _dio.post('$_base/$id/reject', ...);
      // AFTER (correct):
      final response = await _dio.post(
        '/pharma/reports/$id/reject',
        data: {'notes': feedback},
      );
      final body = response.data['data'] ?? response.data;
      return DailyReportModel.fromJson(body as Map<String, dynamic>);
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
