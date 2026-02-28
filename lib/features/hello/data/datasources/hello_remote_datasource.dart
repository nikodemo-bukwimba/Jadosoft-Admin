import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/h_e_l_l_o_model.dart';

abstract class HelloRemoteDataSource {
  Future<List<HelloModel>> getAll();
  Future<HelloModel>       getById(String id);
  Future<HelloModel>       create(Map<String, dynamic> data);
  Future<HelloModel>       update(String id, Map<String, dynamic> data);
  Future<void>                delete(String id);
}

class HelloRemoteDataSourceImpl implements HelloRemoteDataSource {
  final Dio _dio;
  HelloRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<HelloModel>> getAll() async {
    try {
      final response = await _dio.get('');
      final data = response.data as List;
      return data
          .map((e) => HelloModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<HelloModel> getById(String id) async {
    try {
      final response = await _dio.get('/$id');
      return HelloModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<HelloModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('', data: data);
      return HelloModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<HelloModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/$id', data: data);
      return HelloModel.fromJson(response.data as Map<String, dynamic>);
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
