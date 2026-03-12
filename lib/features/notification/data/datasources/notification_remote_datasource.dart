import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getAll();
  Future<NotificationModel>       getById(String id);
  Future<NotificationModel>       create(Map<String, dynamic> data);
  Future<NotificationModel>       update(String id, Map<String, dynamic> data);
  Future<void>                delete(String id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio _dio;
  NotificationRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<NotificationModel>> getAll() async {
    try {
      final response = await _dio.get('/notifications');
      final data = response.data as List;
      return data
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<NotificationModel> getById(String id) async {
    try {
      final response = await _dio.get('/notifications/$id');
      return NotificationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<NotificationModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/notifications', data: data);
      return NotificationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<NotificationModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/notifications/$id', data: data);
      return NotificationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/notifications/$id');
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
