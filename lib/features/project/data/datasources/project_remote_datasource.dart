import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/project_model.dart';

abstract class ProjectRemoteDataSource {
  Future<List<ProjectModel>> getAll();
  Future<ProjectModel>       getById(String id);
  Future<ProjectModel>       create(Map<String, dynamic> data);
  Future<ProjectModel>       update(String id, Map<String, dynamic> data);
  Future<void>                delete(String id);
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  final Dio _dio;
  ProjectRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<ProjectModel>> getAll() async {
    try {
      final response = await _dio.get('/projects');
      final data = response.data as List;
      return data
          .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ProjectModel> getById(String id) async {
    try {
      final response = await _dio.get('/projects/$id');
      return ProjectModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ProjectModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/projects', data: data);
      return ProjectModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ProjectModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/projects/$id', data: data);
      return ProjectModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/projects/$id');
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
