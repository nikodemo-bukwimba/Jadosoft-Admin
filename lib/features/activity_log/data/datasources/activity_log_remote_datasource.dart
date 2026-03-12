import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/activity_log_model.dart';

abstract class ActivityLogRemoteDataSource {
  Future<List<ActivityLogModel>> getAll();
  Future<ActivityLogModel>       getById(String id);
  Future<ActivityLogModel>       create(Map<String, dynamic> data);
  Future<ActivityLogModel>       update(String id, Map<String, dynamic> data);
  Future<void>                delete(String id);
}

class ActivityLogRemoteDataSourceImpl implements ActivityLogRemoteDataSource {
  final Dio _dio;
  ActivityLogRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<ActivityLogModel>> getAll() async {
    try {
      final response = await _dio.get('');
      final data = response.data as List;
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
      final response = await _dio.get('/$id');
      return ActivityLogModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ActivityLogModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('', data: data);
      return ActivityLogModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ActivityLogModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/$id', data: data);
      return ActivityLogModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/$id');
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
