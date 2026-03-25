import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/context/org_context.dart';
import '../models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<List<PaymentModel>> getAll();
  Future<PaymentModel>       getById(String id);
  Future<PaymentModel>       create(Map<String, dynamic> data);
  Future<PaymentModel>       update(String id, Map<String, dynamic> data);
  Future<void>               delete(String id);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;

  PaymentRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  })  : _dio = dio,
        _orgContext = orgContext;

  String get _base => '/commerce/${_orgContext.effectiveOrgId}/payments';

  @override
  Future<List<PaymentModel>> getAll() async {
    try {
      final response = await _dio.get(_base);
      final data = (response.data['data'] ?? response.data) as List;
      return data
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<PaymentModel> getById(String id) async {
    try {
      final response = await _dio.get('$_base/$id');
      final data = response.data['data'] ?? response.data;
      return PaymentModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<PaymentModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(_base, data: data);
      final body = response.data['data'] ?? response.data;
      return PaymentModel.fromJson(body as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<PaymentModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('$_base/$id', data: data);
      final body = response.data['data'] ?? response.data;
      return PaymentModel.fromJson(body as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('$_base/$id');
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