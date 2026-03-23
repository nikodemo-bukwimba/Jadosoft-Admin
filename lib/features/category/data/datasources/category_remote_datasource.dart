import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/base_remote_datasource.dart';
import '../../../../core/network/paginated_response.dart';
import '../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<PaginatedResponse<CategoryModel>> getAll({String? search, int? perPage, int? page});
  Future<CategoryModel> getById(String id);
  Future<CategoryModel> create(Map<String, dynamic> data);
  Future<CategoryModel> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
}

class CategoryRemoteDataSourceImpl extends BaseRemoteDataSource implements CategoryRemoteDataSource {
  final OrgContext _orgContext;
  CategoryRemoteDataSourceImpl({required Dio dio, required OrgContext orgContext})
      : _orgContext = orgContext, super(dio: dio);

  @override Future<PaginatedResponse<CategoryModel>> getAll({String? search, int? perPage, int? page}) {
    final orgId = _orgContext.requireRootOrgId();
    final p = <String, dynamic>{
      if (search != null) 'search': search, if (perPage != null) 'per_page': perPage, if (page != null) 'page': page};
    return fetchPaginatedList(ApiPaths.commerce.categories(orgId), CategoryModel.fromJson,
      queryParams: p.isNotEmpty ? p : null);
  }
  @override Future<CategoryModel> getById(String id) =>
    fetchSingle(ApiPaths.commerce.category(id), CategoryModel.fromJson, dataKey: 'category');
  @override Future<CategoryModel> create(Map<String, dynamic> data) =>
    postAndParse(ApiPaths.commerce.categories(_orgContext.requireRootOrgId()), data, CategoryModel.fromJson, dataKey: 'category');
  @override Future<CategoryModel> update(String id, Map<String, dynamic> data) =>
    patchAndParse(ApiPaths.commerce.category(id), data, CategoryModel.fromJson, dataKey: 'category');
  @override Future<void> delete(String id) => deleteResource(ApiPaths.commerce.category(id));
}
