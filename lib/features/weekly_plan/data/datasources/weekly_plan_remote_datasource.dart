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

  WeeklyPlanRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  }) : _dio = dio,
       _orgContext = orgContext;

  String get _orgBase => '/pharma/orgs/${_orgContext.effectiveOrgId}/plans';

  @override
  Future<List<WeeklyPlanModel>> getAll() async {
    try {
      final response = await _dio.get(_orgBase);
      final data = (response.data['data'] ?? response.data) as List;
      return data
          .map((e) => WeeklyPlanModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<WeeklyPlanModel> getById(String id) async {
    try {
      final response = await _dio.get('$_orgBase/$id');
      final data = response.data['data'] ?? response.data;
      return WeeklyPlanModel.fromJson(data as Map<String, dynamic>);
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
        // No general update endpoint — re-fetch current state.
        return await getById(id);
      }
      final body = response.data['data'] ?? response.data;
      return WeeklyPlanModel.fromJson(body as Map<String, dynamic>);
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
        '$_orgBase/$id/approve',
        data: notes != null ? {'notes': notes} : {},
      );
      final body = response.data['data'] ?? response.data;
      return WeeklyPlanModel.fromJson(body as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<WeeklyPlanModel> reject(String id, {required String notes}) async {
    try {
      final response = await _dio.post(
        '$_orgBase/$id/reject',
        data: {'notes': notes},
      );
      final body = response.data['data'] ?? response.data;
      return WeeklyPlanModel.fromJson(body as Map<String, dynamic>);
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
