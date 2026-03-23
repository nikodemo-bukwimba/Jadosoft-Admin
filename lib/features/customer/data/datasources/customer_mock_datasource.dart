import '../../../../core/network/paginated_response.dart';
import '../models/customer_model.dart';
import 'customer_remote_datasource.dart';

class CustomerMockDataSource implements CustomerRemoteDataSource {
  static final List<Map<String, dynamic>> _store = [
    {'id':'cust-001','org_id':'branch-mbeya','assigned_officer_id':'act-001','name':'Mbeya City Pharmacy','code':'CUST-00001','customer_type':'b2b','category':'pharmacy','tier':'gold','status':'active','address':'Karume Road, Mbeya CBD','city':'Mbeya','county':'Mbeya','country':'Tanzania','latitude':-8.9,'longitude':33.45,'phone':'+255752100001','receives_whatsapp':true,'receives_sms':true,'receives_in_app':true,'contacts':[{'id':'ct-001','name':'Hassan Mwakyembe','role':'owner','phone':'+255752100001','is_primary':true},{'id':'ct-002','name':'Salma Abdallah','role':'pharmacist','phone':'+255712200001','is_primary':false}],'created_at':'2024-04-10T08:00:00.000Z'},
    {'id':'cust-002','org_id':'branch-mbeya','assigned_officer_id':'act-002','name':'Uyole Medical Supplies','code':'CUST-00002','customer_type':'b2b','category':'wholesaler','tier':'silver','status':'active','address':'Uyole Junction, Mbeya','city':'Mbeya','latitude':-8.92,'longitude':33.43,'phone':'+255765300002','contacts':[{'id':'ct-003','name':'Rehema Mwambene','role':'owner','phone':'+255765300002','is_primary':true}],'created_at':'2024-05-22T09:30:00.000Z'},
    {'id':'cust-003','org_id':'branch-dar','assigned_officer_id':'act-003','name':'Tukuyu Health Store','code':'CUST-00003','customer_type':'b2b','category':'clinic','tier':'standard','status':'active','address':'Market Street, Tukuyu','city':'Tukuyu','county':'Rungwe','latitude':-9.255,'longitude':33.64,'phone':'+255754400003','contacts':[{'id':'ct-004','name':'Daniel Mwasambili','role':'owner','phone':'+255754400003','is_primary':true}],'created_at':'2024-07-15T10:00:00.000Z'},
    {'id':'cust-004','org_id':'branch-mbeya','name':'Amina Juma','code':'CUST-00004','customer_type':'b2c','tier':'standard','status':'active','phone':'+255783654004','city':'Mbeya','contacts':[],'created_at':'2025-02-01T08:00:00.000Z'},
    {'id':'cust-005','org_id':'branch-mbeya','assigned_officer_id':'act-001','name':'Forest Hill Pharmacy','code':'CUST-00005','customer_type':'b2b','category':'pharmacy','tier':'platinum','status':'active','address':'Jacaranda Road, Mbeya','city':'Mbeya','latitude':-8.91,'longitude':33.46,'phone':'+255745600004','contacts':[{'id':'ct-005','name':'Joyce Mwakatobe','role':'manager','phone':'+255756700004','is_primary':true}],'created_at':'2024-09-01T07:00:00.000Z'},
    {'id':'cust-006','org_id':'branch-dar','name':'Soweto Health Point','code':'CUST-00006','customer_type':'b2b','category':'clinic','tier':'gold','status':'inactive','address':'Soweto Area, Mbeya','city':'Mbeya','latitude':-8.905,'longitude':33.455,'phone':'+255783900006','contacts':[{'id':'ct-006','name':'Flora Mwaipopo','role':'procurement','phone':'+255765110006','is_primary':true}],'created_at':'2024-11-10T11:00:00.000Z'},
  ];
  static int _idC = 7;
  Future<void> _d() => Future.delayed(const Duration(milliseconds: 300));

  @override Future<PaginatedResponse<CustomerModel>> getAll({String? customerType, String? status, String? category, String? tier, String? officerId, String? search, int? perPage, int? page}) async {
    await _d(); var l = List<Map<String, dynamic>>.from(_store);
    if (customerType != null) l = l.where((e) => e['customer_type'] == customerType).toList();
    if (status != null) l = l.where((e) => e['status'] == status).toList();
    if (category != null) l = l.where((e) => e['category'] == category).toList();
    if (search != null && search.isNotEmpty) { final q = search.toLowerCase(); l = l.where((e) => (e['name']??'').toString().toLowerCase().contains(q)||(e['phone']??'').toString().contains(q)||(e['code']??'').toString().toLowerCase().contains(q)).toList(); }
    final items = l.map((e) => CustomerModel.fromJson(e)).toList();
    return PaginatedResponse(items: items, currentPage: page ?? 1, lastPage: 1, total: items.length, perPage: perPage ?? 25);
  }
  @override Future<CustomerModel> getById(String id) async { await _d(); return CustomerModel.fromJson(_store.firstWhere((e) => e['id'] == id, orElse: () => throw Exception('Not found'))); }
  @override Future<CustomerModel> create(Map<String, dynamic> data) async { await _d(); final id = _idC++; final item = {'id':'cust-${id.toString().padLeft(3,'0')}','code':'CUST-${id.toString().padLeft(5,'0')}','status':'active','tier':'standard','created_at':DateTime.now().toIso8601String(),...data}; _store.add(item); return CustomerModel.fromJson(item); }
  @override Future<CustomerModel> update(String id, Map<String, dynamic> data) async { await _d(); final i = _store.indexWhere((e) => e['id'] == id); if (i == -1) throw Exception('Not found'); _store[i] = {..._store[i], ...data}; return CustomerModel.fromJson(_store[i]); }
  @override Future<void> delete(String id) async { await _d(); _store.removeWhere((e) => e['id'] == id); }
  @override Future<CustomerModel> assignOfficer(String cId, String oId) async { await _d(); final i = _store.indexWhere((e) => e['id'] == cId); if (i == -1) throw Exception('Not found'); _store[i]['assigned_officer_id'] = oId; return CustomerModel.fromJson(_store[i]); }
  @override Future<CustomerContactModel> addContact(String cId, Map<String, dynamic> data) async { await _d(); return CustomerContactModel.fromJson({'id':'ct-new-${DateTime.now().millisecondsSinceEpoch}',...data,'created_at':DateTime.now().toIso8601String()}); }
  @override Future<CustomerContactModel> updateContact(String cId, Map<String, dynamic> data) async { await _d(); return CustomerContactModel.fromJson({'id':cId,...data}); }
  @override Future<void> deleteContact(String cId) async { await _d(); }
}
