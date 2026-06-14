// lib/features/visit/data/datasources/visit_api_datasource.dart
//
// FIX: OfficerNameResolver was constructed with orgContext.effectiveOrgId
// (branch org). Officers are members of the ROOT org, so the members fetch
// returned an empty/partial list → empty cache → no name resolved.
//
// Fix: pass orgContext.rootOrgId ?? orgContext.effectiveOrgId to the resolver.

import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/officer_name_resolver.dart';
import '../models/visit_model.dart';
import 'visit_remote_datasource.dart';

class VisitApiDataSource implements VisitRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;
  late final OfficerNameResolver _nameResolver;

  VisitApiDataSource({required Dio dio, required OrgContext orgContext})
    : _dio = dio,
      _orgContext = orgContext {
    _nameResolver = OfficerNameResolver(
      dio: dio,
      // FIX: use root org so all officers in the tree are in the cache.
      orgId: () => orgContext.rootOrgId ?? orgContext.effectiveOrgId,
    );
  }

  String get _orgId => _orgContext.effectiveOrgId;

  @override
  Future<List<VisitModel>> getAll() async {
    try {
      await _nameResolver.warmUp();
      final response = await _dio.get('/pharma/orgs/$_orgId/visits');
      final raw = response.data;
      final list = (raw is Map ? (raw['data'] ?? []) : raw) as List? ?? [];
      return Future.wait(
        list.whereType<Map<String, dynamic>>().map(
          (j) async => _mapPharmaToAdminModel(j, await _nameResolver.inject(j)),
        ),
      );
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<VisitModel> getById(String id) async {
    try {
      await _nameResolver.warmUp();
      final response = await _dio.get('/pharma/visits/$id');
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : (response.data['data'] ?? response.data) as Map<String, dynamic>;
      return _mapPharmaToAdminModel(data, await _nameResolver.inject(data));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<VisitModel> create(Map<String, dynamic> data) {
    throw UnimplementedError('Admin cannot create visits');
  }

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

  @override
  Future<List<VisitModel>> getByCustomer(String customerId) async {
    try {
      await _nameResolver.warmUp();
      final response = await _dio.get(
        '/pharma/orgs/$_orgId/visits',
        queryParameters: {'customer_id': customerId, 'per_page': 100},
      );
      final raw = response.data;
      final list =
          (raw is Map
                  ? (raw['data'] ?? raw['visits'] ?? raw['items'] ?? [])
                  : raw)
              as List? ??
          [];
      return Future.wait(
        list.whereType<Map<String, dynamic>>().map(
          (j) async => _mapPharmaToAdminModel(j, await _nameResolver.inject(j)),
        ),
      );
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  VisitModel _mapPharmaToAdminModel(
    Map<String, dynamic> j,
    Map<String, dynamic> injected,
  ) {
    final customer = j['customer'] as Map<String, dynamic>?;
    final visitDateStr = j['check_in_at'] ?? j['visit_date'] ?? j['created_at'];
    final officerActorId =
        j['officer_actor_id']?.toString() ?? j['officer_id']?.toString() ?? '';

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
      'officer_name': injected['officer_name'],
      'flag_reason': j['flag_reason'],
      'admin_comments': j['admin_comments'] ?? <Map<String, dynamic>>[],
    };
    return VisitModel.fromJson(mapped);
  }

  String _mapStatus(Map<String, dynamic> j) {
    final pharmaStatus = j['status'] as String?;
    final adminStatus = j['admin_status'] as String?;
    if (pharmaStatus == 'completed') {
      return switch (adminStatus) {
        'reviewed' => 'reviewed',
        'flagged' => 'flagged',
        _ => 'pending',
      };
    }
    return 'pending';
  }

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
          .map((a) => _resolveUrl(a['file_url']?.toString()))
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
