import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/base_remote_datasource.dart';
import '../../../../core/network/paginated_response.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<PaginatedResponse<CustomerModel>> getAll({
    String? customerType,
    String? status,
    String? category,
    String? tier,
    String? officerId,
    String? search,
    int? perPage,
    int? page,
  });
  Future<CustomerModel> getById(String id);
  Future<CustomerModel> create(Map<String, dynamic> data);
  Future<CustomerModel> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<CustomerModel> assignOfficer(String customerId, String officerActorId);
  Future<CustomerContactModel> addContact(
    String customerId,
    Map<String, dynamic> data,
  );
  Future<CustomerContactModel> updateContact(
    String contactId,
    Map<String, dynamic> data,
  );
  Future<void> deleteContact(String contactId);
}

class CustomerRemoteDataSourceImpl extends BaseRemoteDataSource
    implements CustomerRemoteDataSource {
  final OrgContext _orgContext;
  CustomerRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  }) : _orgContext = orgContext,
       super(dio: dio);

  @override
  Future<PaginatedResponse<CustomerModel>> getAll({
    String? customerType,
    String? status,
    String? category,
    String? tier,
    String? officerId,
    String? search,
    int? perPage,
    int? page,
  }) {
    final orgId = _orgContext.effectiveOrgId;
    final p = <String, dynamic>{
      'customer_type': ?customerType,
      'status': ?status,
      'category': ?category,
      'tier': ?tier,
      'officer_id': ?officerId,
      'search': ?search,
      'per_page': ?perPage,
      'page': ?page,
    };
    return fetchPaginatedList(
      ApiPaths.pharma.customers(orgId),
      CustomerModel.fromJson,
      queryParams: p.isNotEmpty ? p : null,
    );
  }

  @override
  Future<CustomerModel> getById(String id) => fetchSingle(
    ApiPaths.pharma.customer(id),
    CustomerModel.fromJson,
    dataKey: 'customer',
  );
  @override
  Future<CustomerModel> create(Map<String, dynamic> data) => postAndParse(
    ApiPaths.pharma.customers(_orgContext.effectiveOrgId),
    data,
    CustomerModel.fromJson,
    dataKey: 'customer',
  );
  @override
  Future<CustomerModel> update(String id, Map<String, dynamic> data) =>
      patchAndParse(
        ApiPaths.pharma.customer(id),
        data,
        CustomerModel.fromJson,
        dataKey: 'customer',
      );
  @override
  Future<void> delete(String id) =>
      deleteResource(ApiPaths.pharma.customer(id));
  @override
  Future<CustomerModel> assignOfficer(
    String customerId,
    String officerActorId,
  ) => postAction(
    '${ApiPaths.pharma.customer(customerId)}/assign',
    CustomerModel.fromJson,
    data: {'officer_actor_id': officerActorId},
    dataKey: 'customer',
  );
  @override
  Future<CustomerContactModel> addContact(
    String customerId,
    Map<String, dynamic> data,
  ) => postAndParse(
    ApiPaths.pharma.customerContacts(customerId),
    data,
    CustomerContactModel.fromJson,
    dataKey: 'contact',
  );
  @override
  Future<CustomerContactModel> updateContact(
    String contactId,
    Map<String, dynamic> data,
  ) => patchAndParse(
    ApiPaths.pharma.contact(contactId),
    data,
    CustomerContactModel.fromJson,
    dataKey: 'contact',
  );
  @override
  Future<void> deleteContact(String contactId) =>
      deleteResource(ApiPaths.pharma.contact(contactId));
}
