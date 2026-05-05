import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/visit_model.dart';

abstract class VisitRemoteDataSource {
  Future<List<VisitModel>> getAll();
  Future<VisitModel> getById(String id);
  Future<VisitModel> create(Map<String, dynamic> data);
  Future<VisitModel> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<List<VisitModel>> getByCustomer(String customerId); // ← NEW
}

class VisitRemoteDataSourceImpl implements VisitRemoteDataSource {
  final Dio _dio;
  VisitRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<VisitModel>> getAll() async {
    try {
      final response = await _dio.get('/visits');
      final data = response.data as List;
      return data
          .map((e) => VisitModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<VisitModel> getById(String id) async {
    try {
      final response = await _dio.get('/visits/$id');
      return VisitModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<VisitModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/visits', data: data);
      return VisitModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<VisitModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/visits/$id', data: data);
      return VisitModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/visits/$id');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<List<VisitModel>> getByCustomer(String customerId) async {
    try {
      final response = await _dio.get(
        '/visits',
        queryParameters: {'customer_id': customerId, 'per_page': 100},
      );
      final raw = response.data;
      final list =
          (raw is Map
                  ? (raw['data'] ?? raw['visits'] ?? raw['items'] ?? [])
                  : raw)
              as List? ??
          [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => VisitModel.fromJson(e))
          .toList();
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
