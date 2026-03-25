import '../models/weekly_plan_model.dart';
import 'weekly_plan_remote_datasource.dart';

class WeeklyPlanMockDataSource implements WeeklyPlanRemoteDataSource {
  static final List<Map<String, dynamic>> _store = [
    {
      'id': 'wp-001', 'officer_id': 'off-001',
      'week_start': '2026-03-09T00:00:00.000Z', 'week_end': '2026-03-15T23:59:59.000Z',
      'planned_customer_ids': ['cust-001', 'cust-003'],
      'planned_activities': 'Visit Mbeya City Pharmacy for Q2 pricing review. Follow up Tukuyu Health Store on pending order.',
      'notes': 'Priority: close Paracetamol bulk deal', 'status': 'submitted',
      'submitted_at': '2026-03-08T18:00:00.000Z', 'reviewed_at': null,
      'review_notes': null, 'created_at': '2026-03-07T10:00:00.000Z',
    },
    {
      'id': 'wp-002', 'officer_id': 'off-002',
      'week_start': '2026-03-09T00:00:00.000Z', 'week_end': '2026-03-15T23:59:59.000Z',
      'planned_customer_ids': ['cust-002', 'cust-006'],
      'planned_activities': 'Routine stock check at Uyole Medical. Introduce new Omeprazole line to Soweto Health Point.',
      'notes': null, 'status': 'approved',
      'submitted_at': '2026-03-08T17:30:00.000Z', 'reviewed_at': '2026-03-09T08:00:00.000Z',
      'review_notes': 'Good plan, proceed.', 'created_at': '2026-03-07T09:00:00.000Z',
    },
    {
      'id': 'wp-003', 'officer_id': 'off-003',
      'week_start': '2026-03-09T00:00:00.000Z', 'week_end': '2026-03-15T23:59:59.000Z',
      'planned_customer_ids': ['cust-004'],
      'planned_activities': 'Demo Hydrocortisone cream at Forest Hill Pharmacy.',
      'notes': 'Only 1 customer planned — needs more targets', 'status': 'rejected',
      'submitted_at': '2026-03-08T16:00:00.000Z', 'reviewed_at': '2026-03-09T09:00:00.000Z',
      'review_notes': 'Too few customers. Resubmit with at least 3 targets.',
      'created_at': '2026-03-07T11:00:00.000Z',
    },
    {
      'id': 'wp-004', 'officer_id': 'off-006',
      'week_start': '2026-03-16T00:00:00.000Z', 'week_end': '2026-03-22T23:59:59.000Z',
      'planned_customer_ids': ['cust-005', 'cust-006', 'cust-001'],
      'planned_activities': 'Expand coverage to Igawa area. Collect pending payments from Soweto. Introduce supplements line to Mbeya City.',
      'notes': 'Aiming for 3 new orders this week', 'status': 'draft',
      'submitted_at': null, 'reviewed_at': null,
      'review_notes': null, 'created_at': '2026-03-13T08:00:00.000Z',
    },
  ];

  static int _idCounter = 5;
  Future<void> _simulateDelay() => Future.delayed(const Duration(milliseconds: 400));

  @override
  Future<List<WeeklyPlanModel>> getAll() async {
    await _simulateDelay();
    return _store.map((e) => WeeklyPlanModel.fromJson(e)).toList();
  }

  @override
  Future<WeeklyPlanModel> getById(String id) async {
    await _simulateDelay();
    return WeeklyPlanModel.fromJson(
      _store.firstWhere((e) => e['id'] == id, orElse: () => throw Exception('Plan not found')),
    );
  }

  @override
  Future<WeeklyPlanModel> create(Map<String, dynamic> data) async {
    await _simulateDelay();
    final id = _idCounter++;
    final n = {
      'id': 'wp-${id.toString().padLeft(3, '0')}',
      ...data,
      'status': 'draft',
      'submitted_at': null,
      'reviewed_at': null,
      'review_notes': null,
      'created_at': DateTime.now().toIso8601String(),
    };
    _store.add(n);
    return WeeklyPlanModel.fromJson(n);
  }

  @override
  Future<WeeklyPlanModel> update(String id, Map<String, dynamic> data) async {
    await _simulateDelay();
    final i = _store.indexWhere((e) => e['id'] == id);
    if (i == -1) throw Exception('Plan not found');
    _store[i] = {..._store[i], ...data, 'id': id, 'created_at': _store[i]['created_at']};
    return WeeklyPlanModel.fromJson(_store[i]);
  }

  @override
  Future<void> delete(String id) async {
    await _simulateDelay();
    _store.removeWhere((e) => e['id'] == id);
  }

  @override
  Future<WeeklyPlanModel> approve(String id, {String? notes}) async {
    await _simulateDelay();
    final i = _store.indexWhere((e) => e['id'] == id);
    if (i == -1) throw Exception('Plan not found');
    _store[i] = {
      ..._store[i],
      'status': 'approved',
      'reviewed_at': DateTime.now().toIso8601String(),
      'review_notes': notes,
    };
    return WeeklyPlanModel.fromJson(_store[i]);
  }

  @override
  Future<WeeklyPlanModel> reject(String id, {required String notes}) async {
    await _simulateDelay();
    final i = _store.indexWhere((e) => e['id'] == id);
    if (i == -1) throw Exception('Plan not found');
    _store[i] = {
      ..._store[i],
      'status': 'rejected',
      'reviewed_at': DateTime.now().toIso8601String(),
      'review_notes': notes,
    };
    return WeeklyPlanModel.fromJson(_store[i]);
  }
}