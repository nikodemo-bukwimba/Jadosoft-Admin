import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/daily_report_model.dart';

abstract class DailyReportRemoteDataSource {
  Future<List<DailyReportModel>> getAll();
  Future<DailyReportModel>       getById(String id);
  Future<DailyReportModel>       create(Map<String, dynamic> data);
  Future<DailyReportModel>       update(String id, Map<String, dynamic> data);
  Future<void>                delete(String id);
}

class DailyReportRemoteDataSourceImpl implements DailyReportRemoteDataSource {
  final Dio _dio;
  DailyReportRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<DailyReportModel>> getAll() async {
    try {
      final response = await _dio.get('/daily-reports');
      final data = response.data as List;
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
      final response = await _dio.get('/daily-reports/$id');
      return DailyReportModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<DailyReportModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/daily-reports', data: data);
      return DailyReportModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<DailyReportModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/daily-reports/$id', data: data);
      return DailyReportModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/daily-reports/$id');
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
