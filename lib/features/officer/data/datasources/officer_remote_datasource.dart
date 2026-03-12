import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/officer_model.dart';

abstract class OfficerRemoteDataSource {
  Future<List<OfficerModel>> getAll();
  Future<OfficerModel>       getById(String id);
  Future<OfficerModel>       create(Map<String, dynamic> data);
  Future<OfficerModel>       update(String id, Map<String, dynamic> data);
  Future<void>                delete(String id);
}

class OfficerRemoteDataSourceImpl implements OfficerRemoteDataSource {
  final Dio _dio;
  OfficerRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<OfficerModel>> getAll() async {
    try {
      final response = await _dio.get('/officers');
      final data = response.data as List;
      return data
          .map((e) => OfficerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OfficerModel> getById(String id) async {
    try {
      final response = await _dio.get('/officers/$id');
      return OfficerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OfficerModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/officers', data: data);
      return OfficerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<OfficerModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/officers/$id', data: data);
      return OfficerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/officers/$id');
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
