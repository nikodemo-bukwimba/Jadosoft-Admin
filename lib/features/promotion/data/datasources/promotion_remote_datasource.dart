// promotion_remote_datasource.dart
// ─────────────────────────────────────────────────────────────
// Replaces the Maishell stub entirely.
// Keeps the abstract interface IDENTICAL — only the impl changes.
//
// Nexora endpoint mapping:
//   GET    /api/v1/pharma/orgs/{orgId}/product-updates   → getAll()
//   POST   /api/v1/pharma/orgs/{orgId}/product-updates   → create()
//   GET    /api/v1/pharma/product-updates/{id}           → getById()
//   PATCH  /api/v1/pharma/product-updates/{id}           → update()
//   POST   /api/v1/pharma/product-updates/{id}/publish   → used by DomainService for activate
//   DELETE not available — cancel/end via PATCH status   → delete() soft-cancels
//
// Field mapping:
//   title          → title
//   description    → body
//   productIds     → product_ids
//   channels       → send_sms / send_whatsapp / send_in_app booleans
//   status         → draft·sending·sent·failed  (mapped to draft·active·cancelled)
//   targetCount    → total_recipients
//   broadcastSentAt→ sent_at
//   startDate/endDate → stored in metadata (Nexora has no date range concept)
//
// OrgContext: uses effectiveOrgId (org-scoped resource).
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import '../../../../core/context/org_context.dart';
import '../../../../core/error/exceptions.dart';
import '../models/promotion_model.dart';

abstract class PromotionRemoteDataSource {
  Future<List<PromotionModel>> getAll();
  Future<PromotionModel>       getById(String id);
  Future<PromotionModel>       create(Map<String, dynamic> data);
  Future<PromotionModel>       update(String id, Map<String, dynamic> data);
  Future<void>                 delete(String id);
  // publish() is called by DomainService directly for the activate transition
  Future<PromotionModel>       publish(String id);
}

class PromotionRemoteDataSourceImpl implements PromotionRemoteDataSource {
  final Dio _dio;
  final OrgContext _orgContext;

  PromotionRemoteDataSourceImpl({
    required Dio dio,
    required OrgContext orgContext,
  })  : _dio = dio,
        _orgContext = orgContext;

  String get _base =>
      '/pharma/orgs/${_orgContext.effectiveOrgId}/product-updates';

  // ── Nexora response → PromotionModel ──────────────────────

  PromotionModel _fromNexora(Map<String, dynamic> j) {
    final meta = (j['metadata'] as Map<String, dynamic>?) ?? {};

    // channels: reconstruct from send_* booleans
    final channels = <String>[
      if (j['send_sms'] == true) 'sms',
      if (j['send_whatsapp'] == true) 'whatsapp',
      if (j['send_in_app'] == true) 'in_app',
    ];

    // status mapping
    final nexoraStatus = j['status'] as String? ?? 'draft';
    final localStatus = _mapStatus(nexoraStatus);

    return PromotionModel(
      id:          j['id']?.toString() ?? '',
      title:       j['title'] as String? ?? '',
      description: j['body'] as String?,
      productIds:  List<String>.from((j['product_ids'] as List?) ?? []),
      startDate:   meta['start_date'] != null
          ? DateTime.tryParse(meta['start_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      endDate:     meta['end_date'] != null
          ? DateTime.tryParse(meta['end_date'] as String) ??
              DateTime.now().add(const Duration(days: 7))
          : DateTime.now().add(const Duration(days: 7)),
      channels:    channels,
      status:      localStatus,
      createdAt:   j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      targetCount:     j['total_recipients'] as int? ?? 0,
      broadcastSentAt: j['sent_at'] != null
          ? DateTime.tryParse(j['sent_at'].toString())
          : null,
    );
  }

  /// Nexora status → local PromotionStatus name
  String _mapStatus(String s) => switch (s) {
    'sending' || 'sent' => 'active',
    'failed'            => 'cancelled',
    _                   => s, // draft passes through
  };

  // ── PromotionModel data → Nexora create body ───────────────

  Map<String, dynamic> _toCreateBody(Map<String, dynamic> d) {
    final channels = List<String>.from(d['channels'] as List? ?? []);
    final startDate = d['start_date'] ?? d['startDate'];
    final endDate   = d['end_date']   ?? d['endDate'];

    return {
      'title':          d['title'] ?? '',
      'body':           d['description'],
      'update_type':    'promotion',
      'target_segment': 'all',
      'send_sms':       channels.contains('sms'),
      'send_whatsapp':  channels.contains('whatsapp'),
      'send_in_app':    channels.contains('in_app'),
      'product_ids':    List<String>.from(d['product_ids'] as List? ?? []),
      'metadata': {
        if (startDate != null) 'start_date': startDate.toString(),
        if (endDate   != null) 'end_date':   endDate.toString(),
      },
    };
  }

  // ── PromotionModel data → Nexora PATCH body ─────────────────

  Map<String, dynamic> _toUpdateBody(Map<String, dynamic> d) {
    final channels = List<String>.from(d['channels'] as List? ?? []);
    final startDate = d['start_date'] ?? d['startDate'];
    final endDate   = d['end_date']   ?? d['endDate'];

    final body = <String, dynamic>{
      'title':         d['title'] ?? '',
      'body':          d['description'],
      'send_sms':      channels.contains('sms'),
      'send_whatsapp': channels.contains('whatsapp'),
      'send_in_app':   channels.contains('in_app'),
      'product_ids':   List<String>.from(d['product_ids'] as List? ?? []),
      'metadata': {
        if (startDate != null) 'start_date': startDate.toString(),
        if (endDate   != null) 'end_date':   endDate.toString(),
      },
    };

    // Allow status passthrough for end/cancel (local-only transitions)
    if (d['status'] != null) body['status'] = d['status'];

    return body;
  }

  Map<String, dynamic> _unwrap(dynamic raw, String key) {
    if (raw is Map<String, dynamic>) {
      if (raw.containsKey(key)) return raw[key] as Map<String, dynamic>;
      if (raw.containsKey('data') && raw['data'] is Map) {
        return raw['data'] as Map<String, dynamic>;
      }
      return raw;
    }
    return {};
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'An error occurred. Please try again.';
  }

  // ── Interface implementation ───────────────────────────────

  @override
  Future<List<PromotionModel>> getAll() async {
    try {
      final res = await _dio.get(_base, queryParameters: {'per_page': 100});
      final raw = res.data;
      final List<dynamic> items = raw is Map
          ? (raw['data'] ?? raw['updates'] ?? []) as List
          : raw as List;
      return items.cast<Map<String, dynamic>>().map(_fromNexora).toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PromotionModel> getById(String id) async {
    try {
      final res = await _dio.get('/pharma/product-updates/$id');
      return _fromNexora(_unwrap(res.data, 'update'));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PromotionModel> create(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(_base, data: _toCreateBody(data));
      return _fromNexora(_unwrap(res.data, 'update'));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PromotionModel> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch(
        '/pharma/product-updates/$id',
        data: _toUpdateBody(data),
      );
      return _fromNexora(_unwrap(res.data, 'update'));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> delete(String id) async {
    // Nexora has no hard DELETE for product-updates.
    // Soft-cancel by patching status to failed (closest equivalent).
    try {
      await _dio.patch(
        '/pharma/product-updates/$id',
        data: {'status': 'failed'},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return; // already gone
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PromotionModel> publish(String id) async {
    try {
      final res = await _dio.post('/pharma/product-updates/$id/publish');
      return _fromNexora(_unwrap(res.data, 'update'));
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}