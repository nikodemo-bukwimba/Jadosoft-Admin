// Admin visit API datasource.
// The pharma visits API returns only officer_actor_id — no name.
// Officer names are resolved from GET /orgs/{orgId}/members,
// exactly as the officer feature does: user.username keyed by actor_id.

import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/error/exceptions.dart';
import '../models/visit_model.dart';
import 'visit_remote_datasource.dart';

class VisitApiDataSource implements VisitRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;

  /// actorId → display name, populated once per datasource instance.
  /// Refreshed whenever getAll() is called so the list stays current.
  final Map<String, String> _officerNameCache = {};

  VisitApiDataSource({required Dio dio, required OrgContext orgContext})
    : _dio = dio,
      _orgContext = orgContext;

  String get _orgId => _orgContext.effectiveOrgId;

  // ── Fetch officer name map from org members ──────────────────────────────
  // Mirrors what OfficerRemoteDataSourceImpl does: GET /orgs/{orgId}/members
  // Each member has user.actor_id (the key visits store as officer_actor_id)
  // and user.username (the display name used by the officer feature).
  Future<void> _refreshOfficerNames() async {
    try {
      final response = await _dio.get(
        '/orgs/$_orgId/members',
        queryParameters: {'per_page': 200},
      );
      final raw = response.data;
      final list = (raw is Map ? (raw['data'] ?? []) : raw) as List? ?? [];
      _officerNameCache.clear();
      for (final item in list.whereType<Map<String, dynamic>>()) {
        final user = item['user'] as Map<String, dynamic>?;
        if (user == null) continue;
        // actor_id is the key that visits reference as officer_actor_id
        final actorId = (user['actor_id'] ?? item['actor_id'] ?? '').toString();
        if (actorId.isEmpty) continue;
        // username is the display name — same as OfficerEntity.displayName
        final name =
            (user['username'] as String?)?.trim() ??
            (user['name'] as String?)?.trim() ??
            (user['email'] as String?)?.split('@').first ??
            '';
        if (name.isNotEmpty) _officerNameCache[actorId] = name;
      }
    } catch (_) {
      // Non-fatal — visits still load, officer column just shows actor ID.
    }
  }

  // ── GET all visits ────────────────────────────────────────────────────────
  @override
  Future<List<VisitModel>> getAll() async {
    try {
      // Refresh officer name map before mapping visits
      await _refreshOfficerNames();

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

  // ── GET single visit ──────────────────────────────────────────────────────
  @override
  Future<VisitModel> getById(String id) async {
    try {
      // Ensure cache is populated (may be empty if detail page opened directly)
      if (_officerNameCache.isEmpty) await _refreshOfficerNames();

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

  /// Calls review or flag endpoint based on 'status' in [data].
  /// data['status'] == 'reviewed' | 'flagged'
  /// data['flag_reason'] for flagged; data['admin_comment'] for reviewed
  @override
  Future<VisitModel> update(String id, Map<String, dynamic> data) async {
    final targetStatus = data['status'] as String?;
    try {
      if (targetStatus == 'reviewed') {
        final body = <String, dynamic>{};
        if (data['admin_comment'] != null &&
            (data['admin_comment'] as String).isNotEmpty) {
          body['notes'] = data['admin_comment'];
        }
        await _dio.post('/pharma/visits/$id/review', data: body);
      } else if (targetStatus == 'flagged') {
        final body = <String, dynamic>{'reason': data['flag_reason'] ?? ''};
        await _dio.post('/pharma/visits/$id/flag', data: body);
      }
      return getById(id);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) {
    throw UnimplementedError('Admin cannot delete visits');
  }

  // ── Map pharma visit JSON → admin VisitModel ─────────────────────────────
  VisitModel _mapPharmaToAdminModel(Map<String, dynamic> j) {
    final customer = j['customer'] as Map<String, dynamic>?;

    final visitDateStr = j['check_in_at'] ?? j['visit_date'] ?? j['created_at'];

    // Resolve officer_actor_id — the key to look up the officer name
    final officerActorId =
        j['officer_actor_id']?.toString() ?? j['officer_id']?.toString() ?? '';

    // Resolve officer display name:
    // 1. Cache built from org members (user.username keyed by actor_id) — primary
    // 2. Embedded officer object if API ever starts loading it — fallback
    // 3. Raw actor_id as last resort (still better than blank)
    final embeddedOfficer = j['officer'] as Map<String, dynamic>?;
    final embeddedUser = embeddedOfficer?['user'] as Map<String, dynamic>?;
    final officerName =
        (officerActorId.isNotEmpty
            ? _officerNameCache[officerActorId]
            : null) ??
        embeddedUser?['username'] as String? ??
        embeddedOfficer?['display_name'] as String? ??
        embeddedOfficer?['username'] as String? ??
        embeddedOfficer?['name'] as String? ??
        j['officer_name'] as String? ??
        (officerActorId.isNotEmpty ? officerActorId : null);

    final mapped = <String, dynamic>{
      'id': j['id']?.toString() ?? '',
      'customer_id':
          j['customer_id']?.toString() ?? customer?['id']?.toString() ?? '',
      'officer_id': officerActorId,
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
      'status': _mapStatus(j),
      'created_at':
          j['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'visit_type': j['visit_type'],
      'objective': j['objective'],
      'outcome': j['outcome'],
      'outcome_status': j['outcome_status'],
      'duration_minutes': j['duration_minutes'],
      'customer_name': customer?['name'] as String? ?? j['customer_name'],
      'officer_name': officerName,
      'flag_reason': j['flag_reason'],
      'admin_comments': j['admin_comments'] ?? <Map<String, dynamic>>[],
      'flag_reason': j['flag_reason'],
      'admin_comments': j['admin_comments'] ?? <Map<String, dynamic>>[],
    };
    return VisitModel.fromJson(mapped);
  }

  // Replace _mapStatus entirely:
  String _mapStatus(Map<String, dynamic> j) {
    final pharmaStatus = j['status'] as String?;
    final adminStatus = j['admin_status'] as String?;

    // Admin overrides take priority on completed visits
    if (pharmaStatus == 'completed') {
      return switch (adminStatus) {
        'reviewed' => 'reviewed',
        'flagged' => 'flagged',
        _ => 'pending', // completed but not yet reviewed
      };
    }
    // in_progress or cancelled → still pending from admin view
    return 'pending';
  }

  // Add to VisitApiDataSource
  String _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      final apiUri = Uri.parse(_dio.options.baseUrl);
      if (!url.startsWith('http')) {
        final base = _dio.options.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
        return '$base$url';
      }
      final fileUri = Uri.parse(url);
      return fileUri
          .replace(
            scheme: apiUri.scheme,
            host: apiUri.host,
            port: apiUri.hasPort ? apiUri.port : null,
          )
          .toString();
    } catch (_) {
      return url;
    }
  }

  List<String>? _buildImageUrls(Map<String, dynamic> j) {
    final attachments = j['attachments'] as List?;
    if (attachments != null && attachments.isNotEmpty) {
      return attachments
          .whereType<Map>()
          .where(
            (a) =>
                a['type'] == 'photo' ||
                (a['mime_type'] as String? ?? '').startsWith('image/'),
          )
          .map(
            (a) => _resolveUrl(a['file_url']?.toString()),
          ) // ← wrap with _resolveUrl
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
