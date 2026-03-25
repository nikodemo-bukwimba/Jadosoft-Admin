import '../models/daily_report_model.dart';
import 'daily_report_remote_datasource.dart';

class DailyReportMockDataSource implements DailyReportRemoteDataSource {
  static int _idCounter = 100;

  final List<Map<String, dynamic>> _store = [
    {
      'id': 'dr-001',
      'officer_id': 'off-001',
      'officer_name': 'Amina Juma',
      'officer_email': 'amina.juma@barick.co.tz',
      'officer_phone': '+255 712 345 678',
      'officer_role': 'Senior Marketing Officer',
      'officer_status': 'active',
      'report_number': 'RPT-2026-001',
      'report_date': '2026-03-10',
      'submitted_at': '2026-03-10T17:30:00.000Z',
      'reviewed_at': '2026-03-11T09:15:00.000Z',
      'visited_customers': [
        {
          'customerBusinessName': 'Mbeya Dawa Centre',
          'customerOwnerName': 'Hassan Mwenda',
          'customerOfficeName': 'Mbeya Dawa Centre Ltd',
          'customerPhone': '+255 713 111 222',
          'customerContactPerson': 'Sarah Mwenda',
          'customerContactPhone': '+255 713 111 333',
          'customerAddress': 'Mbeya CBD, Kariakoo Street',
          'customerGpsLat': '-8.9094',
          'customerGpsLng': '33.4607',
          'visitTime': '09:30',
          'promotedProducts': ['Paracetamol 500mg', 'Amoxicillin 250mg'],
          'discussionSummary':
              'Discussed new antibiotic range and bulk pricing. Customer expressed interest in monthly supply agreement.',
          'visitNotes': 'Follow up on pricing proposal by Friday.',
          'visitImageUrls': [],
          'visitDocumentUrls': [],
        },
        {
          'customerBusinessName': 'Sunrise Pharmacy Mbeya',
          'customerOwnerName': 'Grace Kyando',
          'customerOfficeName': 'Sunrise Health Ltd',
          'customerPhone': '+255 714 222 333',
          'customerContactPerson': 'Peter Kyando',
          'customerContactPhone': '+255 714 222 444',
          'customerAddress': 'Mbeya, Sisimba Road Block C',
          'customerGpsLat': '-8.9200',
          'customerGpsLng': '33.4550',
          'visitTime': '11:00',
          'promotedProducts': ['Metformin 500mg', 'Vitamin C 1000mg'],
          'discussionSummary':
              'Introduced diabetes management product line. Customer requested product brochures.',
          'visitNotes': 'Send brochures and sample packs.',
          'visitImageUrls': [],
          'visitDocumentUrls': [],
        },
      ],
      'key_outcomes':
          'Secured 2 potential supply agreements. Both customers showed strong interest in diabetic and antibiotic product lines.',
      'challenges_faced':
          'Traffic delays in CBD caused 30 minute delay to first appointment.',
      'next_day_plan':
          'Visit 3 pharmacies in Uyole area and follow up on Mbeya Dawa pricing proposal.',
      'custom_body': null,
      'is_customized': false,
      'reviewed_by_name': 'Dr. Joseph Barick',
      'reviewed_by_role': 'Head Marketing Officer',
      'admin_feedback':
          'Excellent work Amina. The supply agreement follow-up is critical — please ensure the pricing proposal is sent by Thursday.',
      'review_decision': 'approved',
      'status': 'approved',
      'created_at': '2026-03-10T17:00:00.000Z',
    },
    {
      'id': 'dr-002',
      'officer_id': 'off-002',
      'officer_name': 'Baraka Mwangi',
      'officer_email': 'baraka.mwangi@barick.co.tz',
      'officer_phone': '+255 713 456 789',
      'officer_role': 'Marketing Officer',
      'officer_status': 'active',
      'report_number': 'RPT-2026-002',
      'report_date': '2026-03-10',
      'submitted_at': '2026-03-10T18:00:00.000Z',
      'reviewed_at': '2026-03-11T10:30:00.000Z',
      'visited_customers': [
        {
          'customerBusinessName': 'Lipa Dawa Pharmacy',
          'customerOwnerName': 'Fatuma Salim',
          'customerOfficeName': 'Lipa Dawa Ltd',
          'customerPhone': '+255 715 333 444',
          'customerContactPerson': 'Ali Salim',
          'customerContactPhone': '+255 715 333 555',
          'customerAddress': 'Mbeya, Jacaranda Street',
          'customerGpsLat': '-8.9150',
          'customerGpsLng': '33.4680',
          'visitTime': '10:00',
          'promotedProducts': ['Ibuprofen 400mg'],
          'discussionSummary':
              'Customer complained about delivery delays from last order. Logged complaint for logistics team.',
          'visitNotes': 'Escalate delivery complaint to logistics.',
          'visitImageUrls': [],
          'visitDocumentUrls': [],
        },
      ],
      'key_outcomes': 'Addressed customer complaint. Relationship maintained.',
      'challenges_faced':
          'Customer was unhappy about previous delivery. Required extended conversation to resolve.',
      'next_day_plan':
          'Follow up with logistics on Lipa Dawa delivery complaint resolution.',
      'custom_body': null,
      'is_customized': false,
      'reviewed_by_name': 'Dr. Joseph Barick',
      'reviewed_by_role': 'Head Marketing Officer',
      'admin_feedback':
          'Good handling of the complaint. Please ensure logistics follows up within 24 hours.',
      'review_decision': 'rejected',
      'status': 'rejected',
      'created_at': '2026-03-10T17:45:00.000Z',
    },
    {
      'id': 'dr-003',
      'officer_id': 'off-003',
      'officer_name': 'Celestine Msigwa',
      'officer_email': 'celestine.msigwa@barick.co.tz',
      'officer_phone': '+255 714 567 890',
      'officer_role': 'Marketing Officer',
      'officer_status': 'active',
      'report_number': 'RPT-2026-003',
      'report_date': '2026-03-11',
      'submitted_at': '2026-03-11T17:15:00.000Z',
      'reviewed_at': null,
      'visited_customers': [
        {
          'customerBusinessName': 'Mbeya Afya Pharmacy',
          'customerOwnerName': 'John Temba',
          'customerOfficeName': 'Mbeya Afya Ltd',
          'customerPhone': '+255 716 444 555',
          'customerContactPerson': 'Mary Temba',
          'customerContactPhone': '+255 716 444 666',
          'customerAddress': 'Mbeya, Forest Road',
          'customerGpsLat': '-8.9000',
          'customerGpsLng': '33.4500',
          'visitTime': '09:00',
          'promotedProducts': [
            'Amoxicillin 250mg',
            'Metformin 500mg',
            'Vitamin C 1000mg',
          ],
          'discussionSummary':
              'Introduced 3 new products. Customer agreed to trial order of 50 units each.',
          'visitNotes': 'Trial order confirmed. Process through orders system.',
          'visitImageUrls': [],
          'visitDocumentUrls': [],
        },
        {
          'customerBusinessName': 'Neema Dawa Shop',
          'customerOwnerName': 'Neema Kiiza',
          'customerOfficeName': 'Neema Health Centre',
          'customerPhone': '+255 717 555 666',
          'customerContactPerson': 'Robert Kiiza',
          'customerContactPhone': '+255 717 555 777',
          'customerAddress': 'Mbeya, Mwanjelwa Market',
          'customerGpsLat': '-8.9300',
          'customerGpsLng': '33.4400',
          'visitTime': '11:30',
          'promotedProducts': ['Paracetamol 500mg'],
          'discussionSummary':
              'Routine check-in. Reordering Paracetamol stock.',
          'visitNotes': 'Standard reorder — process this week.',
          'visitImageUrls': [],
          'visitDocumentUrls': [],
        },
      ],
      'key_outcomes':
          'Secured trial order from Mbeya Afya. Maintained relationship with Neema Dawa.',
      'challenges_faced': 'No major challenges today.',
      'next_day_plan':
          'Process Mbeya Afya trial order and visit 2 new pharmacies in Uyole.',
      'custom_body': null,
      'is_customized': false,
      'reviewed_by_name': null,
      'reviewed_by_role': null,
      'admin_feedback': null,
      'review_decision': null,
      'status': 'submitted',
      'created_at': '2026-03-11T17:00:00.000Z',
    },
    {
      'id': 'dr-004',
      'officer_id': 'off-001',
      'officer_name': 'Amina Juma',
      'officer_email': 'amina.juma@barick.co.tz',
      'officer_phone': '+255 712 345 678',
      'officer_role': 'Senior Marketing Officer',
      'officer_status': 'active',
      'report_number': 'RPT-2026-004',
      'report_date': '2026-03-12',
      'submitted_at': null,
      'reviewed_at': null,
      'visited_customers': [],
      'key_outcomes': null,
      'challenges_faced': null,
      'next_day_plan': null,
      'custom_body': null,
      'is_customized': false,
      'reviewed_by_name': null,
      'reviewed_by_role': null,
      'admin_feedback': null,
      'review_decision': null,
      'status': 'draft',
      'created_at': '2026-03-12T08:00:00.000Z',
    },
    {
      'id': 'dr-005',
      'officer_id': 'off-004',
      'officer_name': 'Diana Mosha',
      'officer_email': 'diana.mosha@barick.co.tz',
      'officer_phone': '+255 715 678 901',
      'officer_role': 'Marketing Officer',
      'officer_status': 'active',
      'report_number': 'RPT-2026-005',
      'report_date': '2026-03-11',
      'submitted_at': '2026-03-11T16:45:00.000Z',
      'reviewed_at': null,
      'visited_customers': [
        {
          'customerBusinessName': 'Uyole Community Pharmacy',
          'customerOwnerName': 'Samuel Ngowi',
          'customerOfficeName': 'Uyole Community Health',
          'customerPhone': '+255 718 666 777',
          'customerContactPerson': 'Jane Ngowi',
          'customerContactPhone': '+255 718 666 888',
          'customerAddress': 'Uyole, Mbeya',
          'customerGpsLat': '-8.9500',
          'customerGpsLng': '33.4300',
          'visitTime': '14:00',
          'promotedProducts': ['Ibuprofen 400mg', 'Paracetamol 500mg'],
          'discussionSummary':
              'Demonstrated new pain management product range. Customer interested in seasonal promotion.',
          'visitNotes': 'Send seasonal promotion details.',
          'visitImageUrls': [],
          'visitDocumentUrls': [],
        },
      ],
      'key_outcomes':
          'Positive reception of pain management range in Uyole area.',
      'challenges_faced': 'Customer requested competitor comparison data.',
      'next_day_plan': 'Prepare competitor comparison document and revisit.',
      'custom_body':
          'Additionally visited the district health office to introduce Barick Pharmacy as a preferred supplier.',
      'is_customized': true,
      'reviewed_by_name': null,
      'reviewed_by_role': null,
      'admin_feedback': null,
      'review_decision': null,
      'status': 'submitted',
      'created_at': '2026-03-11T16:30:00.000Z',
    },
  ];

  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 400));

  @override
  Future<List<DailyReportModel>> getAll() async {
    await _delay();
    return _store.map((e) => DailyReportModel.fromJson(Map.from(e))).toList();
  }

  @override
  Future<DailyReportModel> getById(String id) async {
    await _delay();
    final item = _store.firstWhere(
      (e) => e['id'] == id,
      orElse: () => throw Exception('DailyReport not found'),
    );
    return DailyReportModel.fromJson(Map.from(item));
  }

  @override
  Future<DailyReportModel> create(Map<String, dynamic> data) async {
    await _delay();
    final id = 'dr-${_idCounter.toString().padLeft(3, '0')}';
    _idCounter++;
    final newItem = {
      'id': id,
      'officer_id': data['officer_id'] ?? '',
      'officer_name': data['officer_name'],
      'officer_email': data['officer_email'],
      'officer_phone': data['officer_phone'],
      'officer_role': data['officer_role'],
      'officer_status': data['officer_status'],
      'report_number': 'RPT-2026-${_idCounter.toString().padLeft(3, '0')}',
      'report_date':
          data['report_date'] ??
          DateTime.now().toIso8601String().substring(0, 10),
      'submitted_at': null,
      'reviewed_at': null,
      'visited_customers': data['visited_customers'] ?? [],
      'key_outcomes': data['key_outcomes'],
      'challenges_faced': data['challenges_faced'],
      'next_day_plan': data['next_day_plan'],
      'custom_body': data['custom_body'],
      'is_customized': data['is_customized'] ?? false,
      'reviewed_by_name': null,
      'reviewed_by_role': null,
      'admin_feedback': null,
      'review_decision': null,
      'status': 'draft',
      'created_at': DateTime.now().toIso8601String(),
    };
    _store.add(newItem);
    return DailyReportModel.fromJson(newItem);
  }

  @override
  Future<DailyReportModel> update(String id, Map<String, dynamic> data) async {
    await _delay();
    final index = _store.indexWhere((e) => e['id'] == id);
    if (index == -1) throw Exception('DailyReport not found');
    _store[index] = {..._store[index], ...data};
    return DailyReportModel.fromJson(Map.from(_store[index]));
  }

  @override
  Future<void> delete(String id) async {
    await _delay();
    _store.removeWhere((e) => e['id'] == id);
  }

  @override
  Future<DailyReportModel> approve(
    String id, {
    required String feedback,
  }) async {
    await _delay();
    final index = _store.indexWhere((e) => e['id'] == id);
    if (index == -1) throw Exception('DailyReport not found');
    _store[index] = {
      ..._store[index],
      'status': 'approved',
      'review_decision': 'approved',
      'admin_feedback': feedback,
      'reviewed_at': DateTime.now().toIso8601String(),
      'reviewed_by_name': 'Dr. Joseph Barick',
      'reviewed_by_role': 'Head Marketing Officer',
    };
    return DailyReportModel.fromJson(Map.from(_store[index]));
  }

  @override
  Future<DailyReportModel> reject(String id, {required String feedback}) async {
    await _delay();
    final index = _store.indexWhere((e) => e['id'] == id);
    if (index == -1) throw Exception('DailyReport not found');
    _store[index] = {
      ..._store[index],
      'status': 'rejected',
      'review_decision': 'rejected',
      'admin_feedback': feedback,
      'reviewed_at': DateTime.now().toIso8601String(),
      'reviewed_by_name': 'Dr. Joseph Barick',
      'reviewed_by_role': 'Head Marketing Officer',
    };
    return DailyReportModel.fromJson(Map.from(_store[index]));
  }
}
