// lib/features/visit/data/datasources/visit_remote_datasource.dart
//
// FIX: VisitRemoteDataSourceImpl was the class being registered in DI.
// It hit the wrong URL (/visits instead of /pharma/orgs/{orgId}/visits)
// and had NO OfficerNameResolver — so officer names were never resolved.
//
// Solution: VisitRemoteDataSourceImpl now delegates entirely to
// VisitApiDataSource, which has the correct URL and resolver.
// The DI container registers VisitRemoteDataSourceImpl — this keeps
// that contract intact while routing all calls through the correct impl.

import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/error/exceptions.dart';
import '../models/visit_model.dart';
import 'visit_api_datasource.dart';

export 'visit_api_datasource.dart' show VisitApiDataSource;

abstract class VisitRemoteDataSource {
  Future<List<VisitModel>> getAll();
  Future<VisitModel> getById(String id);
  Future<VisitModel> create(Map<String, dynamic> data);
  Future<VisitModel> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<List<VisitModel>> getByCustomer(String customerId);
}

/// Concrete implementation — delegates to [VisitApiDataSource] which
/// uses the correct pharma API paths and resolves officer names.
class VisitRemoteDataSourceImpl implements VisitRemoteDataSource {
  late final VisitApiDataSource _api;

  VisitRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  }) {
    _api = VisitApiDataSource(dio: dio, orgContext: orgContext);
  }

  @override
  Future<List<VisitModel>> getAll() => _api.getAll();

  @override
  Future<VisitModel> getById(String id) => _api.getById(id);

  @override
  Future<VisitModel> create(Map<String, dynamic> data) => _api.create(data);

  @override
  Future<VisitModel> update(String id, Map<String, dynamic> data) =>
      _api.update(id, data);

  @override
  Future<void> delete(String id) => _api.delete(id);

  @override
  Future<List<VisitModel>> getByCustomer(String customerId) =>
      _api.getByCustomer(customerId);
}