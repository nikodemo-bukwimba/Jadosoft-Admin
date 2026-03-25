import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/context/org_context.dart';
import '../models/activity_log_model.dart';

abstract class ActivityLogRemoteDataSource {
  Future<List<ActivityLogModel>> getAll();
  Future<ActivityLogModel> getById(String id);
  // create/update/delete intentionally omitted — backend writes only
}

class ActivityLogRemoteDataSourceImpl implements ActivityLogRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;

  ActivityLogRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  }) : _dio = dio,
       _orgContext = orgContext;

  String get _base => '/pharma/${_orgContext.effectiveOrgId}/activity-logs';

  @override
  Future<List<ActivityLogModel>> getAll() async {
    try {
      final response = await _dio.get(_base);
      final data = (response.data['data'] ?? response.data) as List;
      return data
          .map((e) => ActivityLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ActivityLogModel> getById(String id) async {
    try {
      final response = await _dio.get('$_base/$id');
      final data = response.data['data'] ?? response.data;
      return ActivityLogModel.fromJson(data as Map<String, dynamic>);
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
