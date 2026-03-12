import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/weekly_plan_model.dart';

abstract class WeeklyPlanRemoteDataSource {
  Future<List<WeeklyPlanModel>> getAll();
  Future<WeeklyPlanModel>       getById(String id);
  Future<WeeklyPlanModel>       create(Map<String, dynamic> data);
  Future<WeeklyPlanModel>       update(String id, Map<String, dynamic> data);
  Future<void>                delete(String id);
}

class WeeklyPlanRemoteDataSourceImpl implements WeeklyPlanRemoteDataSource {
  final Dio _dio;
  WeeklyPlanRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<WeeklyPlanModel>> getAll() async {
    try {
      final response = await _dio.get('/weekly-plans');
      final data = response.data as List;
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
      final response = await _dio.get('/weekly-plans/$id');
      return WeeklyPlanModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<WeeklyPlanModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/weekly-plans', data: data);
      return WeeklyPlanModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<WeeklyPlanModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/weekly-plans/$id', data: data);
      return WeeklyPlanModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/weekly-plans/$id');
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
