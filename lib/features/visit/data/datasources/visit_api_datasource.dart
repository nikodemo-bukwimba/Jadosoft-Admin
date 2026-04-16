// === FILE: lib/features/visit/data/datasources/visit_api_datasource.dart ===
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

  @override
  Future<VisitModel> create(Map<String, dynamic> data) {
    throw UnimplementedError('Admin cannot create visits');
  }

  /// Calls review or flag endpoint based on the target status in [data].
  /// Expects data keys: 'status' ('reviewed'|'flagged'), optionally 'flag_reason'.
  @override
  Future<VisitModel> update(String id, Map<String, dynamic> data) async {
    final targetStatus = data['status'] as String?;
    try {
      if (targetStatus == 'reviewed') {
        // POST /pharma/visits/{id}/review  — accept the visit
        final body = <String, dynamic>{};
        if (data['admin_comment'] != null)
          body['notes'] = data['admin_comment'];
        await _dio.post('/pharma/visits/$id/review', data: body);
      } else if (targetStatus == 'flagged') {
        // POST /pharma/visits/{id}/flag
        final body = <String, dynamic>{
          if (data['flag_reason'] != null) 'reason': data['flag_reason'],
        };
        await _dio.post('/pharma/visits/$id/flag', data: body);
      }
      // Re-fetch to return up-to-date entity
      return getById(id);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) {
    throw UnimplementedError('Admin cannot delete visits');
  }

  VisitModel _mapPharmaToAdminModel(Map<String, dynamic> j) {
    final customer = j['customer'] as Map<String, dynamic>?;
    final officer = j['officer'] as Map<String, dynamic>?;

    final visitDateStr = j['check_in_at'] ?? j['visit_date'] ?? j['created_at'];

    // Resolve officer name: prefer officer.name, fallback to officer_name field
    final officerName =
        officer?['name'] as String? ??
        officer?['display_name'] as String? ??
        j['officer_name'] as String?;

    final mapped = <String, dynamic>{
      'id': j['id']?.toString() ?? '',
      'customer_id':
          j['customer_id']?.toString() ?? customer?['id']?.toString() ?? '',
      'officer_id':
          j['officer_actor_id']?.toString() ??
          j['officer_id']?.toString() ??
          officer?['id']?.toString() ??
          '',
      'visit_date':
          visitDateStr?.toString() ?? DateTime.now().toIso8601String(),
      'business_name':
          customer?['name'] as String? ??
          customer?['business_name'] as String? ??
          j['business_name'] as String?,
      'owner_phone': customer?['phone'] as String? ?? j['owner_phone'],
      'contact_person_phone': j['contact_person_phone'],
      'business_phone': j['business_phone'],
      'notes': j['notes'],
      'gps_lat': j['check_in_latitude'] ?? j['gps_lat'],
      'gps_lng': j['check_in_longitude'] ?? j['gps_lng'],
      'image_urls': _buildImageUrls(j),
      'document_urls': _toStringList(j['document_urls']),
      'promoted_product_ids': _toStringList(j['promoted_product_ids']),
      'discussion_summary': j['discussion_summary'],
      'status': _mapStatus(j['status'] as String?),
      'created_at':
          j['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'visit_type': j['visit_type'],
      'objective': j['objective'],
      'outcome': j['outcome'],
      'outcome_status': j['outcome_status'],
      'duration_minutes': j['duration_minutes'],
      'customer_name': customer?['name'] as String? ?? j['customer_name'],
      'officer_name': officerName, // ← Fixed: resolves actual name
      'flag_reason': j['flag_reason'],
      'admin_comments': j['admin_comments'] ?? <Map<String, dynamic>>[],
    };
    return VisitModel.fromJson(mapped);
  }

  /// pharma: in_progress | completed | cancelled
  /// admin:  pending (submitted/in review) | reviewed | flagged
  String _mapStatus(String? pharmaStatus) {
    return switch (pharmaStatus) {
      'completed' => 'pending', // completed visit awaits admin review
      'in_progress' => 'pending',
      'cancelled' => 'pending',
      'reviewed' => 'reviewed', // if backend ever returns this
      'flagged' => 'flagged',
      _ => 'pending',
    };
  }

  /// Build image URL list from pharma attachments structure.
  List<String>? _buildImageUrls(Map<String, dynamic> j) {
    // Try attachments array first (full visit detail response)
    final attachments = j['attachments'] as List?;
    if (attachments != null && attachments.isNotEmpty) {
      return attachments
          .whereType<Map>()
          .where(
            (a) =>
                a['type'] == 'photo' ||
                (a['mime_type'] as String? ?? '').startsWith('image/'),
          )
          .map((a) => a['file_url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return _toStringList(j['image_urls']);
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
