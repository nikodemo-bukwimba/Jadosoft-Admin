// Reads officer-created visits from the pharma API.
// Admin review/flag transitions are not yet supported by the backend —
// they need a future endpoint before they can persist.

import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/error/exceptions.dart';
import '../models/visit_model.dart';
import 'visit_remote_datasource.dart';

class VisitApiDataSource implements VisitRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;

  VisitApiDataSource({required Dio dio, required OrgContext orgContext})
      : _dio = dio,
        _orgContext = orgContext;

  String get _orgId => _orgContext.effectiveOrgId;

  @override
  Future<List<VisitModel>> getAll() async {
    try {
      final response = await _dio.get('/pharma/orgs/$_orgId/visits');
      final raw = response.data;
      final list = (raw is Map ? (raw['data'] ?? []) : raw) as List? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(_mapPharmaToAdminModel)
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<VisitModel> getById(String id) async {
    try {
      final response = await _dio.get('/pharma/visits/$id');
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : (response.data['data'] ?? response.data) as Map<String, dynamic>;
      return _mapPharmaToAdminModel(data);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  /// Admin does not create visits — officers do via check-in.
  @override
  Future<VisitModel> create(Map<String, dynamic> data) {
    throw UnimplementedError('Admin cannot create visits');
  }

  /// Review/flag transitions — no backend endpoint yet.
  /// Returns the entity unchanged; UI state is optimistic only.
  @override
  Future<VisitModel> update(String id, Map<String, dynamic> data) async {
    // TODO: call PATCH /pharma/visits/{id}/status once backend adds it.
    // For now, re-fetch so the returned entity is current.
    return getById(id);
  }

  @override
  Future<void> delete(String id) {
    throw UnimplementedError('Admin cannot delete visits');
  }

  // ── Map pharma visit JSON → admin VisitModel ─────────────────
  VisitModel _mapPharmaToAdminModel(Map<String, dynamic> j) {
    final customer = j['customer'] as Map<String, dynamic>?;
    final officer  = j['officer']  as Map<String, dynamic>?;

    // Pharma: check_in_at / check_in_latitude / check_in_longitude
    final visitDateStr = j['check_in_at'] ?? j['visit_date'] ?? j['created_at'];

    // Build a minimal admin-compatible JSON and delegate to VisitModel.fromJson
    final mapped = <String, dynamic>{
      'id':                   j['id']?.toString() ?? '',
      'customer_id':          j['customer_id']?.toString() ??
                              customer?['id']?.toString() ?? '',
      'officer_id':           j['officer_actor_id']?.toString() ??
                              j['officer_id']?.toString() ??
                              officer?['id']?.toString() ?? '',
      'visit_date':           visitDateStr?.toString() ??
                              DateTime.now().toIso8601String(),
      'business_name':        customer?['name'] as String? ??
                              customer?['business_name'] as String? ??
                              j['business_name'] as String?,
      'owner_phone':          customer?['phone'] as String? ?? j['owner_phone'],
      'contact_person_phone': j['contact_person_phone'],
      'business_phone':       j['business_phone'],
      'notes':                j['notes'],
      'gps_lat':              j['check_in_latitude'] ?? j['gps_lat'],
      'gps_lng':              j['check_in_longitude'] ?? j['gps_lng'],
      'image_urls':           _toStringList(j['image_urls']),
      'document_urls':        _toStringList(j['document_urls']),
      'promoted_product_ids': _toStringList(j['promoted_product_ids']),
      'discussion_summary':   j['discussion_summary'],
      // Map pharma statuses to admin statuses
      'status':               _mapStatus(j['status'] as String?),
      'created_at':           j['created_at']?.toString() ??
                              DateTime.now().toIso8601String(),
      'visit_type':           j['visit_type'],
      'objective':            j['objective'],
      'outcome':              j['outcome'],
      'outcome_status':       j['outcome_status'],
      'duration_minutes':     j['duration_minutes'],
      'customer_name':        customer?['name'] as String? ?? j['customer_name'],
      'officer_name':         officer?['name'] as String? ?? j['officer_name'],
      'flag_reason':          j['flag_reason'],
      'admin_comments':       j['admin_comments'] ?? <Map<String, dynamic>>[],
    };
    return VisitModel.fromJson(mapped);
  }

  /// pharma: pending | in_progress | completed | cancelled
  /// admin:  pending | reviewed | flagged
  String _mapStatus(String? pharmaStatus) {
    switch (pharmaStatus) {
      case 'completed': return 'pending'; // ready for admin review
      case 'cancelled': return 'pending';
      default:          return 'pending';
    }
  }

  List<String>? _toStringList(dynamic v) {
    if (v == null) return null;
    if (v is List) return v.map((e) => e.toString()).toList();
    return null;
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'An error occurred. Please try again.';
  }
}