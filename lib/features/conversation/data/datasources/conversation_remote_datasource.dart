import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/conversation_model.dart';

abstract class ConversationRemoteDataSource {
  Future<List<ConversationModel>> getAll();
  Future<ConversationModel>       getById(String id);
  Future<ConversationModel>       create(Map<String, dynamic> data);
  Future<ConversationModel>       update(String id, Map<String, dynamic> data);
  Future<void>                delete(String id);
}

class ConversationRemoteDataSourceImpl implements ConversationRemoteDataSource {
  final Dio _dio;
  ConversationRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<ConversationModel>> getAll() async {
    try {
      final response = await _dio.get('');
      final data = response.data as List;
      return data
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ConversationModel> getById(String id) async {
    try {
      final response = await _dio.get('/$id');
      return ConversationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ConversationModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('', data: data);
      return ConversationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ConversationModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/$id', data: data);
      return ConversationModel.fromJson(response.data as Map<String, dynamic>);
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
