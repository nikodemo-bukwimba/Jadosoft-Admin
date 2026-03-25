import '../models/activity_log_model.dart';
import 'activity_log_remote_datasource.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ActivityLogMockDataSource
// Read-only audit trail. Admin can only view — backend writes all entries.
// Covers all 21 features across all 9 phases.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityLogMockDataSource implements ActivityLogRemoteDataSource {
  static final List<ActivityLogModel> _logs = [
    // ── Auth ──────────────────────────────────────────────────────────────
    ActivityLogModel(
      id: 'log-001',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'logged_in',
      entityType: 'session',
      entityId: 'sess-001',
      entitySnapshot: {'ip': '192.168.1.10', 'device': 'Chrome / Windows'},
      ipAddress: '192.168.1.10',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0)',
      occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    // ── Officers ──────────────────────────────────────────────────────────
    ActivityLogModel(
      id: 'log-002',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'created',
      entityType: 'officer',
      entityId: 'off-004',
      entitySnapshot: {
        'name': 'James Mwangi',
        'email': 'james@barick.co.tz',
        'role': 'marketing_officer',
        'status': 'active',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    ActivityLogModel(
      id: 'log-003',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'transitioned',
      entityType: 'officer',
      entityId: 'off-002',
      entitySnapshot: {
        'from_status': 'active',
        'to_status': 'suspended',
        'reason': 'Disciplinary review',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    // ── Customers ─────────────────────────────────────────────────────────
    ActivityLogModel(
      id: 'log-004',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'created',
      entityType: 'customer',
      entityId: 'cust-005',
      entitySnapshot: {
        'business_name': 'Songea Pharmacy',
        'owner_name': 'Grace Mwenda',
        'phone': '+255 754 800 005',
        'address': 'Main Street, Songea',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ActivityLogModel(
      id: 'log-005',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'updated',
      entityType: 'customer',
      entityId: 'cust-002',
      entitySnapshot: {
        'field': 'assigned_officer_id',
        'old_value': 'off-001',
        'new_value': 'off-003',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    // ── Products ──────────────────────────────────────────────────────────
    ActivityLogModel(
      id: 'log-006',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'transitioned',
      entityType: 'product',
      entityId: 'prod-003',
      entitySnapshot: {
        'product_name': 'Vitamin C 1000mg',
        'from_status': 'draft',
        'to_status': 'active',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ActivityLogModel(
      id: 'log-007',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'transitioned',
      entityType: 'product',
      entityId: 'prod-002',
      entitySnapshot: {
        'product_name': 'Amoxicillin 250mg',
        'from_status': 'active',
        'to_status': 'featured',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    // ── Promotions ────────────────────────────────────────────────────────
    ActivityLogModel(
      id: 'log-008',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'transitioned',
      entityType: 'promotion',
      entityId: 'promo-001',
      entitySnapshot: {
        'title': 'Flu Season Bundle',
        'from_status': 'draft',
        'to_status': 'active',
        'channels': ['sms', 'whatsapp'],
        'target_count': 47,
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    // ── Visits ────────────────────────────────────────────────────────────
    ActivityLogModel(
      id: 'log-009',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'transitioned',
      entityType: 'visit',
      entityId: 'visit-012',
      entitySnapshot: {
        'customer': 'Mbeya City Pharmacy',
        'officer': 'Peter Mwakasege',
        'from_status': 'pending',
        'to_status': 'reviewed',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 9)),
    ),
    ActivityLogModel(
      id: 'log-010',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'transitioned',
      entityType: 'visit',
      entityId: 'visit-008',
      entitySnapshot: {
        'customer': 'Tukuyu Health Store',
        'officer': 'Amina Hassan',
        'from_status': 'reviewed',
        'to_status': 'flagged',
        'reason': 'GPS coordinates do not match customer address',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 10)),
    ),
    // ── Weekly Plans ──────────────────────────────────────────────────────
    ActivityLogModel(
      id: 'log-011',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'transitioned',
      entityType: 'weekly_plan',
      entityId: 'plan-003',
      entitySnapshot: {
        'officer': 'James Mwangi',
        'week': '2026-W11',
        'from_status': 'submitted',
        'to_status': 'approved',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 11)),
    ),
    // ── Daily Reports ─────────────────────────────────────────────────────
    ActivityLogModel(
      id: 'log-012',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'transitioned',
      entityType: 'daily_report',
      entityId: 'rep-005',
      entitySnapshot: {
        'officer': 'Peter Mwakasege',
        'date': '2026-03-10',
        'from_status': 'submitted',
        'to_status': 'approved',
        'feedback': 'Excellent coverage. 8 visits recorded.',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    ActivityLogModel(
      id: 'log-013',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'transitioned',
      entityType: 'daily_report',
      entityId: 'rep-004',
      entitySnapshot: {
        'officer': 'Amina Hassan',
        'date': '2026-03-10',
        'from_status': 'submitted',
        'to_status': 'rejected',
        'feedback': 'Only 2 visits logged. Minimum is 5 per day.',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 13)),
    ),
    // ── Orders ────────────────────────────────────────────────────────────
    ActivityLogModel(
      id: 'log-014',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'transitioned',
      entityType: 'order',
      entityId: 'ord-003',
      entitySnapshot: {
        'customer': 'Mbeya City Pharmacy',
        'total': 45000.0,
        'from_status': 'draft',
        'to_status': 'confirmed',
        'payment_ref': 'MPESA-2026-044',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 14)),
    ),
    ActivityLogModel(
      id: 'log-015',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'transitioned',
      entityType: 'order',
      entityId: 'ord-001',
      entitySnapshot: {
        'customer': 'Uyole Medical Supplies',
        'total': 31000.0,
        'from_status': 'shipped',
        'to_status': 'delivered',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 15)),
    ),
    ActivityLogModel(
      id: 'log-016',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'created',
      entityType: 'order',
      entityId: 'ord-007',
      entitySnapshot: {
        'customer_id': 'cust-003',
        'items_count': 3,
        'total': 18500.0,
        'source': 'manual_entry',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 16)),
    ),
    // ── Notifications ─────────────────────────────────────────────────────
    ActivityLogModel(
      id: 'log-017',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'transitioned',
      entityType: 'notification',
      entityId: 'notif-009',
      entitySnapshot: {
        'recipient': 'Hassan Mwakyembe',
        'channel': 'sms',
        'from_status': 'failed',
        'to_status': 'queued',
        'action': 'retry',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(hours: 17)),
    ),
    // ── Categories ────────────────────────────────────────────────────────
    ActivityLogModel(
      id: 'log-018',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'created',
      entityType: 'category',
      entityId: 'cat-005',
      entitySnapshot: {
        'name': 'Dermatology',
        'description': 'Skin care and treatment products',
        'is_active': true,
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    // ── Logout ────────────────────────────────────────────────────────────
    ActivityLogModel(
      id: 'log-019',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'logged_out',
      entityType: 'session',
      entityId: 'sess-000',
      entitySnapshot: {'duration_minutes': 142},
      ipAddress: '192.168.1.10',
      userAgent: 'Mozilla/5.0 (Windows NT 10.0)',
      occurredAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    // ── Delete ────────────────────────────────────────────────────────────
    ActivityLogModel(
      id: 'log-020',
      actorId: 'usr-001',
      actorName: 'Admin User',
      actorRole: 'admin',
      action: 'deleted',
      entityType: 'order',
      entityId: 'ord-006',
      entitySnapshot: {
        'customer': 'Forest Hill Pharmacy',
        'total': 7500.0,
        'status': 'draft',
        'reason': 'Duplicate entry',
      },
      ipAddress: '192.168.1.10',
      occurredAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
    ),
  ];

  @override
  Future<List<ActivityLogModel>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final sorted = List<ActivityLogModel>.from(_logs)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return sorted;
  }

  @override
  Future<ActivityLogModel> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _logs.firstWhere(
      (e) => e.id == id,
      orElse: () => throw Exception('Activity log not found'),
    );
  }
}