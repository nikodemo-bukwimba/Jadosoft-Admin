// master_product_catalog_page.dart
// Master Product Catalog — Super Admin global pharmaceutical reference.
//
// This is the canonical drug database. Every product a distributor lists
// in their catalog is derived from a MasterProduct record here.
// Super Admin owns this table. Org Admins read from it.
//
// Schema sources:
//   master_products   — canonical drug record (name, dosage_form, strength, TFDA code…)
//   product_categories — hierarchical (Antibiotics › Sub-category)
//   distributor_products — how many orgs have listed each master product
//
// Capabilities:
//   - KPI strip: total, active, Rx-only, by dosage form
//   - Category tree: hierarchical collapsible filter
//   - Search: name, brand, TFDA code, manufacturer
//   - Filters: dosage form, Rx flag, category, active status, manufacturer
//   - Sort: name, most-distributed, newest, manufacturer
//   - Product tiles: full pharmaceutical spec at a glance
//   - Product detail sheet: complete drug record + distributor adoption
//   - Add/Edit product form sheet
//   - Bulk: activate, deactivate, export
//
// No AppBar. No Drawer. Pure page content.
// Location: features/platform_admin/presentation/pages/master_product_catalog_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum DosageForm {
  tablet,
  capsule,
  syrup,
  injection,
  cream,
  drops,
  powder,
  inhaler,
}

enum SortMode { nameAsc, mostDistributed, newestFirst, manufacturer }

// ─── Models ──────────────────────────────────────────────────────────────────

class _Category {
  final String id;
  final String name;
  final String? parentId;
  final String? iconEmoji;
  final int productCount;

  const _Category({
    required this.id,
    required this.name,
    this.parentId,
    this.iconEmoji,
    required this.productCount,
  });
}

class _MasterProduct {
  final String id;
  final String name;
  final String? brandName;
  final String? description;
  final DosageForm dosageForm;
  final String strength;
  final String packSize;
  final String manufacturer;
  final String? regulatoryCode; // TFDA registration
  final bool requiresPrescription;
  final bool isActive;
  final String categoryId;
  final DateTime createdAt;
  final int distributorCount; // how many orgs have listed this
  final int activeListings; // how many currently active distributor_products

  const _MasterProduct({
    required this.id,
    required this.name,
    this.brandName,
    this.description,
    required this.dosageForm,
    required this.strength,
    required this.packSize,
    required this.manufacturer,
    this.regulatoryCode,
    required this.requiresPrescription,
    required this.isActive,
    required this.categoryId,
    required this.createdAt,
    required this.distributorCount,
    required this.activeListings,
  });
}

// ─── Mock categories (hierarchical) ──────────────────────────────────────────

final List<_Category> _categories = [
  _Category(
    id: 'cat0',
    name: 'All Categories',
    iconEmoji: '📦',
    productCount: 42,
  ),
  // Tier 1
  _Category(id: 'cat1', name: 'Antibiotics', iconEmoji: '🦠', productCount: 10),
  _Category(id: 'cat2', name: 'Analgesics', iconEmoji: '💊', productCount: 8),
  _Category(
    id: 'cat3',
    name: 'Vitamins & Supplements',
    iconEmoji: '🌿',
    productCount: 7,
  ),
  _Category(id: 'cat4', name: 'Antifungals', iconEmoji: '🍄', productCount: 4),
  _Category(
    id: 'cat5',
    name: 'Cardiovascular',
    iconEmoji: '❤️',
    productCount: 5,
  ),
  _Category(
    id: 'cat6',
    name: 'Antimalarials',
    iconEmoji: '🦟',
    productCount: 4,
  ),
  _Category(
    id: 'cat7',
    name: 'Gastrointestinal',
    iconEmoji: '🫃',
    productCount: 4,
  ),
  // Tier 2 — children
  _Category(
    id: 'cat1a',
    name: 'Penicillins',
    parentId: 'cat1',
    productCount: 3,
  ),
  _Category(
    id: 'cat1b',
    name: 'Cephalosporins',
    parentId: 'cat1',
    productCount: 3,
  ),
  _Category(id: 'cat1c', name: 'Macrolides', parentId: 'cat1', productCount: 2),
  _Category(
    id: 'cat1d',
    name: 'Fluoroquinolones',
    parentId: 'cat1',
    productCount: 2,
  ),
  _Category(id: 'cat2a', name: 'NSAIDs', parentId: 'cat2', productCount: 4),
  _Category(id: 'cat2b', name: 'Opioids', parentId: 'cat2', productCount: 2),
  _Category(
    id: 'cat2c',
    name: 'Paracetamol-based',
    parentId: 'cat2',
    productCount: 2,
  ),
];

// ─── Mock products (42 realistic East-Africa pharmaceutical products) ─────────

final List<_MasterProduct> _products = [
  // ── Antibiotics ──────────────────────────────────────────────────────────
  _MasterProduct(
    id: 'mp001',
    name: 'Amoxicillin',
    brandName: 'Amoxil',
    description:
        'Broad-spectrum penicillin antibiotic used for bacterial infections.',
    dosageForm: DosageForm.capsule,
    strength: '500mg',
    packSize: '100 caps',
    manufacturer: 'GSK Tanzania',
    regulatoryCode: 'TFDA/MED/2019/001',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat1a',
    createdAt: DateTime(2024, 1, 10),
    distributorCount: 6,
    activeListings: 5,
  ),
  _MasterProduct(
    id: 'mp002',
    name: 'Amoxicillin + Clavulanic Acid',
    brandName: 'Augmentin',
    description:
        'Beta-lactamase inhibitor combination for resistant infections.',
    dosageForm: DosageForm.tablet,
    strength: '625mg',
    packSize: '14 tabs',
    manufacturer: 'GSK Tanzania',
    regulatoryCode: 'TFDA/MED/2019/002',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat1a',
    createdAt: DateTime(2024, 1, 11),
    distributorCount: 5,
    activeListings: 4,
  ),
  _MasterProduct(
    id: 'mp003',
    name: 'Azithromycin',
    brandName: 'Zithromax',
    description: 'Macrolide antibiotic for respiratory and skin infections.',
    dosageForm: DosageForm.tablet,
    strength: '500mg',
    packSize: '3 tabs',
    manufacturer: 'Pfizer East Africa',
    regulatoryCode: 'TFDA/MED/2020/015',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat1c',
    createdAt: DateTime(2024, 2, 1),
    distributorCount: 7,
    activeListings: 7,
  ),
  _MasterProduct(
    id: 'mp004',
    name: 'Ciprofloxacin',
    brandName: 'Ciprobay',
    description:
        'Fluoroquinolone for urinary tract and gastrointestinal infections.',
    dosageForm: DosageForm.tablet,
    strength: '500mg',
    packSize: '10 tabs',
    manufacturer: 'Bayer East Africa',
    regulatoryCode: 'TFDA/MED/2019/034',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat1d',
    createdAt: DateTime(2024, 2, 5),
    distributorCount: 4,
    activeListings: 4,
  ),
  _MasterProduct(
    id: 'mp005',
    name: 'Metronidazole',
    brandName: 'Flagyl',
    description: 'Antibiotic and antiprotozoal for anaerobic infections.',
    dosageForm: DosageForm.tablet,
    strength: '400mg',
    packSize: '100 tabs',
    manufacturer: 'Sanofi Tanzania',
    regulatoryCode: 'TFDA/MED/2018/022',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat1',
    createdAt: DateTime(2024, 1, 15),
    distributorCount: 6,
    activeListings: 6,
  ),
  _MasterProduct(
    id: 'mp006',
    name: 'Doxycycline',
    brandName: null,
    description:
        'Tetracycline antibiotic used for malaria prophylaxis and bacterial infections.',
    dosageForm: DosageForm.capsule,
    strength: '100mg',
    packSize: '50 caps',
    manufacturer: 'Rene Industries Tanzania',
    regulatoryCode: 'TFDA/MED/2021/003',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat1',
    createdAt: DateTime(2024, 3, 1),
    distributorCount: 3,
    activeListings: 3,
  ),
  _MasterProduct(
    id: 'mp007',
    name: 'Ceftriaxone',
    brandName: 'Rocephin',
    description:
        'Third-generation cephalosporin for severe bacterial infections.',
    dosageForm: DosageForm.injection,
    strength: '1g/vial',
    packSize: '1 vial',
    manufacturer: 'Roche East Africa',
    regulatoryCode: 'TFDA/MED/2020/041',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat1b',
    createdAt: DateTime(2024, 2, 20),
    distributorCount: 5,
    activeListings: 4,
  ),
  _MasterProduct(
    id: 'mp008',
    name: 'Flucloxacillin',
    brandName: 'Floxapen',
    description:
        'Penicillinase-resistant penicillin for Staphylococcal infections.',
    dosageForm: DosageForm.capsule,
    strength: '250mg',
    packSize: '24 caps',
    manufacturer: 'GSK Tanzania',
    regulatoryCode: 'TFDA/MED/2019/008',
    requiresPrescription: true,
    isActive: false,
    categoryId: 'cat1a',
    createdAt: DateTime(2024, 1, 20),
    distributorCount: 2,
    activeListings: 0,
  ),

  // ── Analgesics ────────────────────────────────────────────────────────────
  _MasterProduct(
    id: 'mp009',
    name: 'Paracetamol',
    brandName: 'Panadol',
    description:
        'First-line analgesic and antipyretic for mild to moderate pain.',
    dosageForm: DosageForm.tablet,
    strength: '500mg',
    packSize: '100 tabs',
    manufacturer: 'GSK Tanzania',
    regulatoryCode: 'TFDA/MED/2017/001',
    requiresPrescription: false,
    isActive: true,
    categoryId: 'cat2c',
    createdAt: DateTime(2023, 11, 1),
    distributorCount: 7,
    activeListings: 7,
  ),
  _MasterProduct(
    id: 'mp010',
    name: 'Paracetamol Syrup',
    brandName: 'Calpol',
    description: 'Paediatric paracetamol suspension for fever and pain relief.',
    dosageForm: DosageForm.syrup,
    strength: '120mg/5ml',
    packSize: '100ml',
    manufacturer: 'GSK Tanzania',
    regulatoryCode: 'TFDA/MED/2017/002',
    requiresPrescription: false,
    isActive: true,
    categoryId: 'cat2c',
    createdAt: DateTime(2023, 11, 5),
    distributorCount: 6,
    activeListings: 6,
  ),
  _MasterProduct(
    id: 'mp011',
    name: 'Ibuprofen',
    brandName: 'Brufen',
    description: 'NSAID for pain, inflammation and fever.',
    dosageForm: DosageForm.tablet,
    strength: '400mg',
    packSize: '100 tabs',
    manufacturer: 'Abbott Laboratories',
    regulatoryCode: 'TFDA/MED/2018/010',
    requiresPrescription: false,
    isActive: true,
    categoryId: 'cat2a',
    createdAt: DateTime(2024, 1, 5),
    distributorCount: 5,
    activeListings: 5,
  ),
  _MasterProduct(
    id: 'mp012',
    name: 'Diclofenac Sodium',
    brandName: 'Voltaren',
    description: 'NSAID for musculoskeletal pain and arthritis.',
    dosageForm: DosageForm.tablet,
    strength: '50mg',
    packSize: '30 tabs',
    manufacturer: 'Novartis East Africa',
    regulatoryCode: 'TFDA/MED/2019/019',
    requiresPrescription: false,
    isActive: true,
    categoryId: 'cat2a',
    createdAt: DateTime(2024, 1, 8),
    distributorCount: 4,
    activeListings: 4,
  ),
  _MasterProduct(
    id: 'mp013',
    name: 'Diclofenac Injection',
    brandName: 'Voltaren IM',
    description: 'Injectable NSAID for acute severe pain.',
    dosageForm: DosageForm.injection,
    strength: '75mg/3ml',
    packSize: '5 ampoules',
    manufacturer: 'Novartis East Africa',
    regulatoryCode: 'TFDA/MED/2019/020',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat2a',
    createdAt: DateTime(2024, 1, 9),
    distributorCount: 3,
    activeListings: 3,
  ),

  // ── Antimalarials ─────────────────────────────────────────────────────────
  _MasterProduct(
    id: 'mp014',
    name: 'Artemether + Lumefantrine',
    brandName: 'Coartem',
    description:
        'First-line ACT for uncomplicated Plasmodium falciparum malaria.',
    dosageForm: DosageForm.tablet,
    strength: '20mg/120mg',
    packSize: '24 tabs',
    manufacturer: 'Novartis East Africa',
    regulatoryCode: 'TFDA/MED/2016/001',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat6',
    createdAt: DateTime(2023, 10, 1),
    distributorCount: 7,
    activeListings: 7,
  ),
  _MasterProduct(
    id: 'mp015',
    name: 'Artesunate',
    brandName: 'Guilin',
    description: 'Injectable artesunate for severe malaria.',
    dosageForm: DosageForm.injection,
    strength: '60mg/vial',
    packSize: '1 vial',
    manufacturer: 'Guilin Pharma',
    regulatoryCode: 'TFDA/MED/2018/044',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat6',
    createdAt: DateTime(2024, 2, 10),
    distributorCount: 4,
    activeListings: 3,
  ),
  _MasterProduct(
    id: 'mp016',
    name: 'Quinine Sulphate',
    brandName: null,
    description:
        'Alternative antimalarial for severe and chloroquine-resistant malaria.',
    dosageForm: DosageForm.tablet,
    strength: '300mg',
    packSize: '30 tabs',
    manufacturer: 'Rene Industries Tanzania',
    regulatoryCode: 'TFDA/MED/2017/033',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat6',
    createdAt: DateTime(2024, 1, 25),
    distributorCount: 3,
    activeListings: 3,
  ),

  // ── Vitamins & Supplements ────────────────────────────────────────────────
  _MasterProduct(
    id: 'mp017',
    name: 'Ferrous Sulphate',
    brandName: null,
    description: 'Iron supplement for iron-deficiency anaemia.',
    dosageForm: DosageForm.tablet,
    strength: '200mg',
    packSize: '100 tabs',
    manufacturer: 'Shelys Pharmaceuticals',
    regulatoryCode: 'TFDA/MED/2018/056',
    requiresPrescription: false,
    isActive: true,
    categoryId: 'cat3',
    createdAt: DateTime(2024, 1, 18),
    distributorCount: 5,
    activeListings: 5,
  ),
  _MasterProduct(
    id: 'mp018',
    name: 'Folic Acid',
    brandName: null,
    description:
        'B-vitamin essential in pregnancy to prevent neural tube defects.',
    dosageForm: DosageForm.tablet,
    strength: '5mg',
    packSize: '100 tabs',
    manufacturer: 'Shelys Pharmaceuticals',
    regulatoryCode: 'TFDA/MED/2018/057',
    requiresPrescription: false,
    isActive: true,
    categoryId: 'cat3',
    createdAt: DateTime(2024, 1, 18),
    distributorCount: 6,
    activeListings: 6,
  ),
  _MasterProduct(
    id: 'mp019',
    name: 'Vitamin C',
    brandName: 'Redoxon',
    description:
        'Ascorbic acid supplement for immune support and scurvy prevention.',
    dosageForm: DosageForm.tablet,
    strength: '500mg',
    packSize: '30 tabs',
    manufacturer: 'Bayer East Africa',
    regulatoryCode: 'TFDA/MED/2017/060',
    requiresPrescription: false,
    isActive: true,
    categoryId: 'cat3',
    createdAt: DateTime(2024, 1, 20),
    distributorCount: 6,
    activeListings: 6,
  ),
  _MasterProduct(
    id: 'mp020',
    name: 'Multivitamin Syrup',
    brandName: 'Vitabiotics',
    description: 'Paediatric multivitamin and mineral supplement.',
    dosageForm: DosageForm.syrup,
    strength: '5ml dose',
    packSize: '200ml',
    manufacturer: 'Vitabiotics Ltd',
    regulatoryCode: 'TFDA/MED/2019/071',
    requiresPrescription: false,
    isActive: true,
    categoryId: 'cat3',
    createdAt: DateTime(2024, 2, 14),
    distributorCount: 4,
    activeListings: 4,
  ),

  // ── Antifungals ───────────────────────────────────────────────────────────
  _MasterProduct(
    id: 'mp021',
    name: 'Fluconazole',
    brandName: 'Diflucan',
    description:
        'Triazole antifungal for candidal and cryptococcal infections.',
    dosageForm: DosageForm.capsule,
    strength: '150mg',
    packSize: '1 cap',
    manufacturer: 'Pfizer East Africa',
    regulatoryCode: 'TFDA/MED/2019/080',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat4',
    createdAt: DateTime(2024, 2, 22),
    distributorCount: 5,
    activeListings: 5,
  ),
  _MasterProduct(
    id: 'mp022',
    name: 'Clotrimazole',
    brandName: 'Canesten',
    description: 'Topical antifungal for skin and vaginal fungal infections.',
    dosageForm: DosageForm.cream,
    strength: '1%',
    packSize: '20g tube',
    manufacturer: 'Bayer East Africa',
    regulatoryCode: 'TFDA/MED/2018/081',
    requiresPrescription: false,
    isActive: true,
    categoryId: 'cat4',
    createdAt: DateTime(2024, 2, 23),
    distributorCount: 5,
    activeListings: 5,
  ),
  _MasterProduct(
    id: 'mp023',
    name: 'Nystatin',
    brandName: null,
    description: 'Polyene antifungal for oral and intestinal candidiasis.',
    dosageForm: DosageForm.drops,
    strength: '100,000 IU/ml',
    packSize: '30ml',
    manufacturer: 'Shelys Pharmaceuticals',
    regulatoryCode: 'TFDA/MED/2020/083',
    requiresPrescription: false,
    isActive: true,
    categoryId: 'cat4',
    createdAt: DateTime(2024, 3, 5),
    distributorCount: 3,
    activeListings: 3,
  ),

  // ── Cardiovascular ────────────────────────────────────────────────────────
  _MasterProduct(
    id: 'mp024',
    name: 'Enalapril',
    brandName: 'Renitec',
    description: 'ACE inhibitor for hypertension and heart failure.',
    dosageForm: DosageForm.tablet,
    strength: '10mg',
    packSize: '28 tabs',
    manufacturer: 'MSD East Africa',
    regulatoryCode: 'TFDA/MED/2019/090',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat5',
    createdAt: DateTime(2024, 3, 10),
    distributorCount: 4,
    activeListings: 4,
  ),
  _MasterProduct(
    id: 'mp025',
    name: 'Amlodipine',
    brandName: 'Norvasc',
    description: 'Calcium channel blocker for hypertension and angina.',
    dosageForm: DosageForm.tablet,
    strength: '5mg',
    packSize: '30 tabs',
    manufacturer: 'Pfizer East Africa',
    regulatoryCode: 'TFDA/MED/2019/091',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat5',
    createdAt: DateTime(2024, 3, 12),
    distributorCount: 4,
    activeListings: 4,
  ),
  _MasterProduct(
    id: 'mp026',
    name: 'Simvastatin',
    brandName: 'Zocor',
    description:
        'Statin for hypercholesterolaemia and cardiovascular risk reduction.',
    dosageForm: DosageForm.tablet,
    strength: '20mg',
    packSize: '28 tabs',
    manufacturer: 'MSD East Africa',
    regulatoryCode: 'TFDA/MED/2020/095',
    requiresPrescription: true,
    isActive: true,
    categoryId: 'cat5',
    createdAt: DateTime(2024, 3, 15),
    distributorCount: 3,
    activeListings: 3,
  ),

  // ── Gastrointestinal ──────────────────────────────────────────────────────
  _MasterProduct(
    id: 'mp027',
    name: 'Omeprazole',
    brandName: 'Losec',
    description: 'Proton pump inhibitor for peptic ulcer and GERD.',
    dosageForm: DosageForm.capsule,
    strength: '20mg',
    packSize: '14 caps',
    manufacturer: 'AstraZeneca East Africa',
    regulatoryCode: 'TFDA/MED/2019/100',
    requiresPrescription: false,
    isActive: true,
    categoryId: 'cat7',
    createdAt: DateTime(2024, 3, 20),
    distributorCount: 6,
    activeListings: 6,
  ),
  _MasterProduct(
    id: 'mp028',
    name: 'Oral Rehydration Salts',
    brandName: 'ORS',
    description: 'Electrolyte solution for dehydration from diarrhoea.',
    dosageForm: DosageForm.powder,
    strength: '20.5g/sachet',
    packSize: '20 sachets',
    manufacturer: 'Shelys Pharmaceuticals',
    regulatoryCode: 'TFDA/MED/2017/101',
    requiresPrescription: false,
    isActive: true,
    categoryId: 'cat7',
    createdAt: DateTime(2024, 1, 30),
    distributorCount: 7,
    activeListings: 7,
  ),
  _MasterProduct(
    id: 'mp029',
    name: 'Metoclopramide',
    brandName: 'Maxolon',
    description: 'Antiemetic and prokinetic for nausea and vomiting.',
    dosageForm: DosageForm.tablet,
    strength: '10mg',
    packSize: '30 tabs',
    manufacturer: 'Sanofi Tanzania',
    regulatoryCode: 'TFDA/MED/2019/105',
    requiresPrescription: false,
    isActive: true,
    categoryId: 'cat7',
    createdAt: DateTime(2024, 3, 22),
    distributorCount: 4,
    activeListings: 4,
  ),
  // Inactive example
  _MasterProduct(
    id: 'mp030',
    name: 'Ranitidine',
    brandName: 'Zantac',
    description:
        'H2 blocker for peptic ulcer. WITHDRAWN from market — NDMA contamination.',
    dosageForm: DosageForm.tablet,
    strength: '150mg',
    packSize: '60 tabs',
    manufacturer: 'GSK Tanzania',
    regulatoryCode: 'TFDA/MED/2014/099',
    requiresPrescription: false,
    isActive: false,
    categoryId: 'cat7',
    createdAt: DateTime(2023, 6, 1),
    distributorCount: 0,
    activeListings: 0,
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class MasterProductCatalogPage extends StatefulWidget {
  const MasterProductCatalogPage({super.key});

  @override
  State<MasterProductCatalogPage> createState() =>
      _MasterProductCatalogPageState();
}

class _MasterProductCatalogPageState extends State<MasterProductCatalogPage> {
  // ── Filter / sort state ────────────────────────────────────────────────────
  String _search = '';
  String _selectedCategoryId = 'cat0';
  DosageForm? _dosageFilter;
  bool? _rxFilter; // null=all, true=Rx only, false=OTC only
  bool _showInactive = false;
  SortMode _sort = SortMode.mostDistributed;
  final Set<String> _selected = {};
  bool _showSearch = false;
  bool _categoryExpanded = false;

  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Derived data ───────────────────────────────────────────────────────────

  List<_MasterProduct> get _filtered {
    var list = _products.where((p) {
      // Category: match self + all children
      final catMatch =
          _selectedCategoryId == 'cat0' ||
          p.categoryId == _selectedCategoryId ||
          _categories.any(
            (c) => c.id == p.categoryId && c.parentId == _selectedCategoryId,
          );

      // Search
      final q = _search.toLowerCase();
      final searchMatch =
          q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          (p.brandName?.toLowerCase().contains(q) ?? false) ||
          p.manufacturer.toLowerCase().contains(q) ||
          (p.regulatoryCode?.toLowerCase().contains(q) ?? false) ||
          p.strength.toLowerCase().contains(q);

      // Dosage form
      final formMatch = _dosageFilter == null || p.dosageForm == _dosageFilter;

      // Rx filter
      final rxMatch = _rxFilter == null || p.requiresPrescription == _rxFilter;

      // Active filter
      final activeMatch = _showInactive || p.isActive;

      return catMatch && searchMatch && formMatch && rxMatch && activeMatch;
    }).toList();

    switch (_sort) {
      case SortMode.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
      case SortMode.mostDistributed:
        list.sort((a, b) => b.distributorCount.compareTo(a.distributorCount));
      case SortMode.newestFirst:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortMode.manufacturer:
        list.sort((a, b) => a.manufacturer.compareTo(b.manufacturer));
    }
    return list;
  }

  // KPIs
  int get _totalActive => _products.where((p) => p.isActive).length;
  int get _totalRx =>
      _products.where((p) => p.requiresPrescription && p.isActive).length;
  int get _totalOTC =>
      _products.where((p) => !p.requiresPrescription && p.isActive).length;
  int get _totalInactive => _products.where((p) => !p.isActive).length;

  Map<DosageForm, int> get _formBreakdown {
    final m = <DosageForm, int>{};
    for (final p in _products.where((p) => p.isActive)) {
      m[p.dosageForm] = (m[p.dosageForm] ?? 0) + 1;
    }
    return m;
  }

  // ── Selection ──────────────────────────────────────────────────────────────
  void _toggle(String id) => setState(
    () => _selected.contains(id) ? _selected.remove(id) : _selected.add(id),
  );

  bool get _hasFilters =>
      _dosageFilter != null || _rxFilter != null || _showInactive;

  // ── Snack ──────────────────────────────────────────────────────────────────
  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: _selected.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showBulkSheet(),
              icon: const Icon(Icons.checklist_rounded),
              label: Text('${_selected.length} selected'),
            )
          : FloatingActionButton.extended(
              onPressed: () => _showProductForm(null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Product'),
            ),
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader()),

          // ── KPI strip ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _KpiStrip(
              total: _products.length,
              active: _totalActive,
              rx: _totalRx,
              otc: _totalOTC,
              inactive: _totalInactive,
              formBreakdown: _formBreakdown,
            ),
          ),

          // ── Category rail ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _CategoryRail(
              categories: _categories,
              selectedId: _selectedCategoryId,
              expanded: _categoryExpanded,
              onSelect: (id) => setState(() => _selectedCategoryId = id),
              onToggleExpand: () =>
                  setState(() => _categoryExpanded = !_categoryExpanded),
            ),
          ),

          // ── Filter + sort bar ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _FilterBar(
              dosageFilter: _dosageFilter,
              rxFilter: _rxFilter,
              showInactive: _showInactive,
              sort: _sort,
              hasFilters: _hasFilters,
              resultCount: filtered.length,
              selectedCount: _selected.length,
              allSelected:
                  _selected.length == filtered.length && filtered.isNotEmpty,
              onDosageFilter: (d) => setState(() => _dosageFilter = d),
              onRxFilter: (r) => setState(() => _rxFilter = r),
              onToggleInactive: () =>
                  setState(() => _showInactive = !_showInactive),
              onSort: () => _showSortSheet(),
              onClearFilters: _clearFilters,
              onSelectAll: () => setState(() {
                if (_selected.length == filtered.length) {
                  _selected.clear();
                } else {
                  _selected.addAll(filtered.map((p) => p.id));
                }
              }),
              onFilter: () => _showFilterSheet(),
            ),
          ),

          // ── Product list ──────────────────────────────────────────────────
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                hasFilters:
                    _hasFilters ||
                    _search.isNotEmpty ||
                    _selectedCategoryId != 'cat0',
                onClear: () {
                  _clearFilters();
                  setState(() => _selectedCategoryId = 'cat0');
                },
              ),
            )
          else
            SliverList.separated(
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final p = filtered[i];
                return _ProductTile(
                  product: p,
                  isSelected: _selected.contains(p.id),
                  onTap: () => _selected.isNotEmpty
                      ? _toggle(p.id)
                      : _showProductDetail(p),
                  onLongPress: () => _toggle(p.id),
                  onEdit: () => _showProductForm(p),
                  onToggleActive: () => _snack(
                    p.isActive
                        ? 'Deactivated ${p.name}'
                        : 'Activated ${p.name}',
                  ),
                  onCopyCode: () {
                    if (p.regulatoryCode != null) {
                      Clipboard.setData(ClipboardData(text: p.regulatoryCode!));
                      _snack('Copied ${p.regulatoryCode}');
                    }
                  },
                );
              },
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.teal.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.science_outlined,
                                size: 12,
                                color: Colors.teal.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'GLOBAL REFERENCE DATABASE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.teal.shade700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Master Product Catalog',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Canonical pharmaceutical reference — all distributors list from here',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Search toggle
              IconButton.outlined(
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _search = '';
                      _searchCtrl.clear();
                    }
                  });
                },
                icon: Icon(
                  _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              IconButton.outlined(
                onPressed: () => _snack('Export to CSV / PDF'),
                icon: const Icon(Icons.download_outlined, size: 20),
                tooltip: 'Export',
              ),
            ],
          ),
          // Search bar
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _showSearch
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (q) => setState(() => _search = q),
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText:
                            'Search name, brand, TFDA code, manufacturer…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _search = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _clearFilters() => setState(() {
    _dosageFilter = null;
    _rxFilter = null;
    _showInactive = false;
    _search = '';
    _searchCtrl.clear();
    _showSearch = false;
  });

  // ── Sheets ─────────────────────────────────────────────────────────────────

  void _showProductDetail(_MasterProduct p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProductDetailSheet(
        product: p,
        category: _categories.firstWhere(
          (c) => c.id == p.categoryId,
          orElse: () =>
              const _Category(id: '', name: 'Uncategorised', productCount: 0),
        ),
        onEdit: () {
          Navigator.pop(context);
          _showProductForm(p);
        },
        onToggleActive: () {
          Navigator.pop(context);
          _snack(p.isActive ? 'Deactivated ${p.name}' : 'Activated ${p.name}');
        },
      ),
    );
  }

  void _showProductForm(_MasterProduct? p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProductFormSheet(
        existing: p,
        categories: _categories.where((c) => c.parentId != null).toList(),
        onSave:
            (
              name,
              brand,
              form,
              strength,
              pack,
              manufacturer,
              code,
              rx,
              categoryId,
            ) {
              Navigator.pop(context);
              _snack(
                p == null
                    ? 'Product "$name" added to master catalog'
                    : 'Updated "$name"',
              );
            },
      ),
    );
  }

  void _showBulkSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BulkSheet(
        count: _selected.length,
        onAction: (action) {
          Navigator.pop(context);
          setState(() => _selected.clear());
          _snack('$action applied');
        },
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SortSheet(
        current: _sort,
        onSelect: (s) {
          setState(() => _sort = s);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        dosageFilter: _dosageFilter,
        rxFilter: _rxFilter,
        showInactive: _showInactive,
        onApply: (d, rx, inactive) {
          setState(() {
            _dosageFilter = d;
            _rxFilter = rx;
            _showInactive = inactive;
          });
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _dosageFilter = null;
            _rxFilter = null;
            _showInactive = false;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── KPI Strip ────────────────────────────────────────────────────────────────

class _KpiStrip extends StatelessWidget {
  final int total, active, rx, otc, inactive;
  final Map<DosageForm, int> formBreakdown;

  const _KpiStrip({
    required this.total,
    required this.active,
    required this.rx,
    required this.otc,
    required this.inactive,
    required this.formBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Row 1
          Row(
            children: [
              _Kpi(
                value: '$total',
                label: 'Total Products',
                sublabel: 'in reference DB',
                icon: Icons.medication_outlined,
                color: Colors.teal,
                flex: 3,
                showBar: true,
                barValue: active / total,
              ),
              const SizedBox(width: 10),
              _Kpi(
                value: '$rx',
                label: 'Prescription',
                sublabel: 'Rx-only drugs',
                icon: Icons.receipt_outlined,
                color: Colors.red,
                flex: 2,
              ),
              const SizedBox(width: 10),
              _Kpi(
                value: '$otc',
                label: 'Over-the-Counter',
                sublabel: 'No Rx needed',
                icon: Icons.local_pharmacy_outlined,
                color: Colors.green,
                flex: 2,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: dosage form breakdown
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Dosage Form Breakdown',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (inactive > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$inactive inactive',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Segmented bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: DosageForm.values
                          .where((f) => (formBreakdown[f] ?? 0) > 0)
                          .map(
                            (f) => Expanded(
                              flex: formBreakdown[f]!,
                              child: Container(color: _formColor(f)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: DosageForm.values
                      .where((f) => (formBreakdown[f] ?? 0) > 0)
                      .map(
                        (f) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _formColor(f),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formEmoji(f),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${_formLabel(f)} (${formBreakdown[f]})',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String value, label, sublabel;
  final IconData icon;
  final Color color;
  final int flex;
  final bool showBar;
  final double barValue;

  const _Kpi({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.flex,
    this.showBar = false,
    this.barValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              sublabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (showBar) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: barValue,
                  minHeight: 3,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Category Rail ────────────────────────────────────────────────────────────

class _CategoryRail extends StatelessWidget {
  final List<_Category> categories;
  final String selectedId;
  final bool expanded;
  final ValueChanged<String> onSelect;
  final VoidCallback onToggleExpand;

  const _CategoryRail({
    required this.categories,
    required this.selectedId,
    required this.expanded,
    required this.onSelect,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Root categories (no parent)
    final roots = categories.where((c) => c.parentId == null).toList();
    // Children of selected root (if root selected)
    final selectedRoot = categories.firstWhere(
      (c) =>
          c.id == selectedId ||
          categories.any((ch) => ch.id == selectedId && ch.parentId == c.id),
      orElse: () => categories.first,
    );
    final children = expanded
        ? categories.where((c) => c.parentId == selectedRoot.id).toList()
        : <_Category>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Category',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onToggleExpand,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      expanded ? 'Collapse' : 'Sub-categories',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Root chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: roots.map((cat) {
                final isSelected = selectedId == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      onSelect(cat.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat.iconEmoji ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.08,
                                    ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${cat.productCount}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Sub-category chips (animated)
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: children.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.subdirectory_arrow_right_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          ...children.map((cat) {
                            final isSel = selectedId == cat.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  cat.name,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                selected: isSel,
                                onSelected: (_) => onSelect(cat.id),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final DosageForm? dosageFilter;
  final bool? rxFilter;
  final bool showInactive;
  final SortMode sort;
  final bool hasFilters;
  final int resultCount;
  final int selectedCount;
  final bool allSelected;
  final ValueChanged<DosageForm?> onDosageFilter;
  final ValueChanged<bool?> onRxFilter;
  final VoidCallback onToggleInactive;
  final VoidCallback onSort;
  final VoidCallback onClearFilters;
  final VoidCallback onSelectAll;
  final VoidCallback onFilter;

  const _FilterBar({
    required this.dosageFilter,
    required this.rxFilter,
    required this.showInactive,
    required this.sort,
    required this.hasFilters,
    required this.resultCount,
    required this.selectedCount,
    required this.allSelected,
    required this.onDosageFilter,
    required this.onRxFilter,
    required this.onToggleInactive,
    required this.onSort,
    required this.onClearFilters,
    required this.onSelectAll,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Count + controls row
          Row(
            children: [
              Text(
                selectedCount > 0
                    ? '$selectedCount of $resultCount selected'
                    : '$resultCount product${resultCount == 1 ? '' : 's'}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (hasFilters) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'filtered',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (selectedCount > 0)
                TextButton(
                  onPressed: onSelectAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    allSelected ? 'Deselect all' : 'Select all',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (hasFilters && selectedCount == 0)
                TextButton(
                  onPressed: onClearFilters,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              IconButton(
                onPressed: onSort,
                icon: const Icon(Icons.sort_rounded, size: 18),
                tooltip: 'Sort',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onFilter,
                icon: const Icon(Icons.tune_rounded, size: 18),
                tooltip: 'More filters',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          // Quick Rx/OTC toggle
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickChip(
                  label: 'All',
                  icon: Icons.medication_outlined,
                  selected: rxFilter == null,
                  onTap: () => onRxFilter(null),
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  label: 'Rx Only',
                  icon: Icons.receipt_outlined,
                  selected: rxFilter == true,
                  selectedColor: Colors.red,
                  onTap: () => onRxFilter(rxFilter == true ? null : true),
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  label: 'OTC',
                  icon: Icons.local_pharmacy_outlined,
                  selected: rxFilter == false,
                  selectedColor: Colors.green,
                  onTap: () => onRxFilter(rxFilter == false ? null : false),
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  label: 'Show Inactive',
                  icon: Icons.visibility_off_outlined,
                  selected: showInactive,
                  selectedColor: Colors.orange,
                  onTap: onToggleInactive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color? selectedColor;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.icon,
    required this.selected,
    this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selectedColor ?? colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? color : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product Tile ─────────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final _MasterProduct product;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onCopyCode;

  const _ProductTile({
    required this.product,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onToggleActive,
    required this.onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isInactive = !product.isActive;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dosage form icon block / check
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Container(
                      key: const ValueKey('chk'),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    )
                  : _DosageIcon(
                      key: const ValueKey('ico'),
                      form: product.dosageForm,
                      inactive: isInactive,
                    ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Rx badge + status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    product.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isInactive
                                          ? colorScheme.onSurface.withValues(
                                              alpha: 0.45,
                                            )
                                          : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (product.requiresPrescription) ...[
                                  const SizedBox(width: 6),
                                  _RxBadge(),
                                ],
                              ],
                            ),
                            if (product.brandName != null)
                              Text(
                                product.brandName!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Active / inactive chip
                      if (isInactive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'Inactive',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Spec row: strength · pack · form
                  Row(
                    children: [
                      _SpecPill(
                        label: product.strength,
                        icon: Icons.straighten_outlined,
                      ),
                      const SizedBox(width: 6),
                      _SpecPill(
                        label: product.packSize,
                        icon: Icons.inventory_2_outlined,
                      ),
                      const SizedBox(width: 6),
                      _SpecPill(
                        label: _formLabel(product.dosageForm),
                        icon: _formIcon(product.dosageForm),
                        color: _formColor(product.dosageForm),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Manufacturer + TFDA code + distributor count
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.factory_outlined,
                              size: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                product.manufacturer,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Distributor adoption count
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.hub_outlined,
                            size: 11,
                            color: product.distributorCount > 0
                                ? Colors.indigo
                                : colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.4,
                                  ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${product.distributorCount} dist.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: product.distributorCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: product.distributorCount > 0
                                  ? Colors.indigo
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.4,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // TFDA code
                  if (product.regulatoryCode != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: GestureDetector(
                        onTap: onCopyCode,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 11,
                              color: Colors.teal.shade600,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              product.regulatoryCode!,
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.copy_outlined,
                              size: 10,
                              color: Colors.teal.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // More menu
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (v) => switch (v) {
                'edit' => onEdit(),
                'toggle' => onToggleActive(),
                'copy_code' => onCopyCode(),
                _ => null,
              },
              itemBuilder: (_) => [
                _menuItem('edit', Icons.edit_outlined, 'Edit Product'),
                if (product.regulatoryCode != null)
                  _menuItem('copy_code', Icons.copy_outlined, 'Copy TFDA Code'),
                const PopupMenuDivider(),
                _menuItem(
                  'toggle',
                  product.isActive
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  product.isActive ? 'Deactivate' : 'Activate',
                  color: product.isActive ? Colors.orange : Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    Color? color,
  }) => PopupMenuItem(
    value: value,
    height: 44,
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: color != null ? FontWeight.w600 : null,
          ),
        ),
      ],
    ),
  );
}

// ─── Dosage Icon ──────────────────────────────────────────────────────────────

class _DosageIcon extends StatelessWidget {
  final DosageForm form;
  final bool inactive;

  const _DosageIcon({super.key, required this.form, required this.inactive});

  @override
  Widget build(BuildContext context) {
    final color = inactive ? Colors.grey.shade400 : _formColor(form);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_formEmoji(form), style: const TextStyle(fontSize: 18)),
          Text(
            _formLabel(form).split(' ').first,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Spec Pill ────────────────────────────────────────────────────────────────

class _SpecPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _SpecPill({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final c = color ?? colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: c),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rx Badge ─────────────────────────────────────────────────────────────────

class _RxBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Rx',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.red.shade700,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Product Detail Sheet ─────────────────────────────────────────────────────

class _ProductDetailSheet extends StatelessWidget {
  final _MasterProduct product;
  final _Category category;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _ProductDetailSheet({
    required this.product,
    required this.category,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _formColor(product.dosageForm);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Hero block
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DosageIcon(
                form: product.dosageForm,
                inactive: !product.isActive,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (product.requiresPrescription)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _RxBadge(),
                          ),
                      ],
                    ),
                    if (product.brandName != null)
                      Text(
                        '${product.brandName} (brand)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        _SpecPill(
                          label: product.strength,
                          icon: Icons.straighten_outlined,
                        ),
                        _SpecPill(
                          label: product.packSize,
                          icon: Icons.inventory_2_outlined,
                        ),
                        _SpecPill(
                          label: _formLabel(product.dosageForm),
                          icon: _formIcon(product.dosageForm),
                          color: color,
                        ),
                        if (!product.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Description
          if (product.description != null) ...[
            Text(
              'Description',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                product.description!,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Full spec table
          Text(
            'Full Specification',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _SpecTable(product: product, category: category),
          const SizedBox(height: 16),

          // Distributor adoption
          Text(
            'Distributor Adoption',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _AdoptionCard(
            distributorCount: product.distributorCount,
            activeListings: product.activeListings,
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Product'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggleActive,
                  icon: Icon(
                    product.isActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                  ),
                  label: Text(product.isActive ? 'Deactivate' : 'Activate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: product.isActive
                        ? Colors.orange
                        : Colors.green,
                    side: BorderSide(
                      color: product.isActive
                          ? Colors.orange.withValues(alpha: 0.4)
                          : Colors.green.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecTable extends StatelessWidget {
  final _MasterProduct product;
  final _Category category;

  const _SpecTable({required this.product, required this.category});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final rows = [
      ('Manufacturer', product.manufacturer, Icons.factory_outlined),
      (
        'Dosage Form',
        _formLabel(product.dosageForm),
        _formIcon(product.dosageForm),
      ),
      ('Strength', product.strength, Icons.straighten_outlined),
      ('Pack Size', product.packSize, Icons.inventory_2_outlined),
      ('Category', category.name, Icons.category_outlined),
      (
        'Prescription',
        product.requiresPrescription ? 'Required (Rx)' : 'Not required (OTC)',
        product.requiresPrescription
            ? Icons.receipt_outlined
            : Icons.local_pharmacy_outlined,
      ),
      (
        'TFDA Code',
        product.regulatoryCode ?? 'Not registered',
        Icons.verified_outlined,
      ),
      (
        'Status',
        product.isActive ? 'Active' : 'Inactive',
        product.isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final (label, value, icon) = entry.value;
          return Column(
            children: [
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 44,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 15,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: label == 'TFDA Code' ? 'monospace' : null,
                          color: label == 'TFDA Code'
                              ? Colors.teal.shade700
                              : label == 'Prescription' &&
                                    product.requiresPrescription
                              ? Colors.red.shade700
                              : label == 'Status' && !product.isActive
                              ? Colors.red
                              : label == 'Status'
                              ? Colors.green.shade700
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _AdoptionCard extends StatelessWidget {
  final int distributorCount;
  final int activeListings;

  const _AdoptionCard({
    required this.distributorCount,
    required this.activeListings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxOrgs = 7; // total orgs on platform

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$distributorCount of $maxOrgs organizations',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'have listed this product in their catalog',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.hub_outlined,
                  color: Colors.indigo.shade600,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: distributorCount / maxOrgs,
              minHeight: 8,
              color: Colors.indigo,
              backgroundColor: Colors.indigo.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _AdoptionStat(
                value: '$activeListings',
                label: 'Active listings',
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _AdoptionStat(
                value: '${distributorCount - activeListings}',
                label: 'Inactive listings',
                color: Colors.orange,
              ),
              const SizedBox(width: 16),
              _AdoptionStat(
                value: '${maxOrgs - distributorCount}',
                label: 'Not listed',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdoptionStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _AdoptionStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Product Form Sheet ───────────────────────────────────────────────────────

class _ProductFormSheet extends StatefulWidget {
  final _MasterProduct? existing;
  final List<_Category> categories;
  final void Function(
    String name,
    String? brand,
    DosageForm form,
    String strength,
    String pack,
    String manufacturer,
    String? code,
    bool rx,
    String categoryId,
  )
  onSave;

  const _ProductFormSheet({
    required this.existing,
    required this.categories,
    required this.onSave,
  });

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final _nameCtrl = TextEditingController(text: widget.existing?.name);
  late final _brandCtrl = TextEditingController(
    text: widget.existing?.brandName,
  );
  late final _strengthCtrl = TextEditingController(
    text: widget.existing?.strength,
  );
  late final _packCtrl = TextEditingController(text: widget.existing?.packSize);
  late final _mfgCtrl = TextEditingController(
    text: widget.existing?.manufacturer,
  );
  late final _codeCtrl = TextEditingController(
    text: widget.existing?.regulatoryCode,
  );
  late final _descCtrl = TextEditingController(
    text: widget.existing?.description,
  );
  DosageForm _form = DosageForm.tablet;
  bool _rx = false;
  String? _catId;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _form = widget.existing!.dosageForm;
      _rx = widget.existing!.requiresPrescription;
      _catId = widget.existing!.categoryId;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _brandCtrl,
      _strengthCtrl,
      _packCtrl,
      _mfgCtrl,
      _codeCtrl,
      _descCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _strengthCtrl.text.trim().isNotEmpty &&
      _packCtrl.text.trim().isNotEmpty &&
      _mfgCtrl.text.trim().isNotEmpty &&
      _catId != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.medication_outlined,
                    color: Colors.teal.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Master Product' : 'New Master Product',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Global pharmaceutical reference record',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Fields
            _field(
              'Generic Name *',
              _nameCtrl,
              Icons.medication_outlined,
              'e.g. Paracetamol',
            ),
            const SizedBox(height: 10),
            _field(
              'Brand Name',
              _brandCtrl,
              Icons.label_outlined,
              'e.g. Panadol (optional)',
            ),
            const SizedBox(height: 10),

            // Dosage form picker
            Text(
              'Dosage Form *',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: DosageForm.values.map((f) {
                final isSelected = _form == f;
                return GestureDetector(
                  onTap: () => setState(() => _form = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _formColor(f).withValues(alpha: 0.15)
                          : colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? _formColor(f)
                            : colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formEmoji(f),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formLabel(f),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isSelected
                                ? _formColor(f)
                                : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _field(
                    'Strength *',
                    _strengthCtrl,
                    Icons.straighten_outlined,
                    'e.g. 500mg',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    'Pack Size *',
                    _packCtrl,
                    Icons.inventory_2_outlined,
                    'e.g. 100 tabs',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _field(
              'Manufacturer *',
              _mfgCtrl,
              Icons.factory_outlined,
              'e.g. GSK Tanzania',
            ),
            const SizedBox(height: 10),
            _field(
              'TFDA Registration Code',
              _codeCtrl,
              Icons.verified_outlined,
              'e.g. TFDA/MED/2024/001',
            ),
            const SizedBox(height: 10),

            // Category
            DropdownButtonFormField<String>(
              value: _catId,
              decoration: _inputDeco(
                'Category *',
                Icons.category_outlined,
                context,
              ),
              hint: const Text('Select category'),
              items: widget.categories
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _catId = v),
            ),
            const SizedBox(height: 10),

            _field(
              'Description',
              _descCtrl,
              Icons.description_outlined,
              'Brief clinical description',
              maxLines: 3,
            ),
            const SizedBox(height: 14),

            // Prescription toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: _rx
                    ? Colors.red.withValues(alpha: 0.05)
                    : colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _rx
                      ? Colors.red.withValues(alpha: 0.25)
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: SwitchListTile(
                value: _rx,
                onChanged: (v) => setState(() => _rx = v),
                title: Text(
                  'Requires Prescription',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _rx ? Colors.red.shade700 : null,
                  ),
                ),
                subtitle: Text(
                  _rx
                      ? 'This is a prescription-only (Rx) drug'
                      : 'This is an over-the-counter (OTC) drug',
                  style: TextStyle(
                    fontSize: 11,
                    color: _rx
                        ? Colors.red.shade600
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                secondary: Icon(
                  _rx ? Icons.receipt_outlined : Icons.local_pharmacy_outlined,
                  color: _rx ? Colors.red : Colors.green,
                ),
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.red,
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _valid
                    ? () => widget.onSave(
                        _nameCtrl.text.trim(),
                        _brandCtrl.text.trim().isEmpty
                            ? null
                            : _brandCtrl.text.trim(),
                        _form,
                        _strengthCtrl.text.trim(),
                        _packCtrl.text.trim(),
                        _mfgCtrl.text.trim(),
                        _codeCtrl.text.trim().isEmpty
                            ? null
                            : _codeCtrl.text.trim(),
                        _rx,
                        _catId!,
                      )
                    : null,
                icon: Icon(
                  isEdit ? Icons.save_outlined : Icons.add_rounded,
                  size: 16,
                ),
                label: Text(isEdit ? 'Save Changes' : 'Add to Catalog'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          decoration: _inputDeco(hint, icon, context),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }
}

// ─── Bulk Sheet ───────────────────────────────────────────────────────────────

class _BulkSheet extends StatelessWidget {
  final int count;
  final void Function(String) onAction;

  const _BulkSheet({required this.count, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$count product${count == 1 ? '' : 's'} selected',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Apply an action to all selected products.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _BulkRow(
            Icons.visibility_outlined,
            'Activate All',
            Colors.green,
            () => onAction('Activated'),
          ),
          _BulkRow(
            Icons.visibility_off_outlined,
            'Deactivate All',
            Colors.orange,
            () => onAction('Deactivated'),
          ),
          _BulkRow(
            Icons.download_outlined,
            'Export to CSV',
            Colors.indigo,
            () => onAction('Export started'),
          ),
          _BulkRow(
            Icons.picture_as_pdf_outlined,
            'Export to PDF',
            Colors.teal,
            () => onAction('PDF export started'),
          ),
          const Divider(height: 20),
          _BulkRow(
            Icons.delete_outline_rounded,
            'Delete Selected',
            Colors.red,
            () => onAction('Deleted'),
          ),
        ],
      ),
    );
  }
}

class _BulkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BulkRow(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
    title: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
    ),
    trailing: Icon(
      Icons.chevron_right_rounded,
      color: Colors.grey.shade400,
      size: 18,
    ),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

// ─── Sort Sheet ───────────────────────────────────────────────────────────────

class _SortSheet extends StatelessWidget {
  final SortMode current;
  final ValueChanged<SortMode> onSelect;

  const _SortSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final opts = [
      (
        SortMode.mostDistributed,
        Icons.hub_outlined,
        'Most Distributed',
        'By distributor adoption',
      ),
      (
        SortMode.nameAsc,
        Icons.sort_by_alpha_rounded,
        'Name A → Z',
        'Alphabetical',
      ),
      (
        SortMode.newestFirst,
        Icons.calendar_today_outlined,
        'Newest First',
        'By date added',
      ),
      (
        SortMode.manufacturer,
        Icons.factory_outlined,
        'By Manufacturer',
        'Grouped by maker',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sort Products',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...opts.map((o) {
            final (mode, icon, label, sub) = o;
            final sel = current == mode;
            return ListTile(
              leading: Icon(
                icon,
                color: sel ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              title: Text(
                label,
                style: TextStyle(
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                  color: sel ? colorScheme.primary : null,
                ),
              ),
              subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
              trailing: sel
                  ? Icon(Icons.check_rounded, color: colorScheme.primary)
                  : null,
              onTap: () => onSelect(mode),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              selected: sel,
              selectedTileColor: colorScheme.primaryContainer.withValues(
                alpha: 0.3,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Filter Sheet ─────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final DosageForm? dosageFilter;
  final bool? rxFilter;
  final bool showInactive;
  final void Function(DosageForm?, bool?, bool) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.dosageFilter,
    required this.rxFilter,
    required this.showInactive,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  DosageForm? _form;
  bool? _rx;
  bool _inactive = false;

  @override
  void initState() {
    super.initState();
    _form = widget.dosageFilter;
    _rx = widget.rxFilter;
    _inactive = widget.showInactive;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Filter Products',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _form = null;
                      _rx = null;
                      _inactive = false;
                    });
                    widget.onClear();
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Dosage Form',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: DosageForm.values
                  .map(
                    (f) => FilterChip(
                      avatar: Text(_formEmoji(f)),
                      label: Text(_formLabel(f)),
                      selected: _form == f,
                      onSelected: (_) =>
                          setState(() => _form = _form == f ? null : f),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),

            Text(
              'Prescription Status',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Rx Only'),
                  selected: _rx == true,
                  onSelected: (_) =>
                      setState(() => _rx = _rx == true ? null : true),
                ),
                FilterChip(
                  label: const Text('OTC Only'),
                  selected: _rx == false,
                  onSelected: (_) =>
                      setState(() => _rx = _rx == false ? null : false),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Show Inactive Products',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Switch(
                  value: _inactive,
                  onChanged: (v) => setState(() => _inactive = v),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => widget.onApply(_form, _rx, _inactive),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClear;

  const _EmptyState({required this.hasFilters, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💊', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No products match' : 'Catalog is empty',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your filters or search.'
                  : 'Add the first master product to begin.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: onClear,
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Dosage form helpers (module-level) ───────────────────────────────────────

Color _formColor(DosageForm f) => switch (f) {
  DosageForm.tablet => Colors.blue,
  DosageForm.capsule => Colors.indigo,
  DosageForm.syrup => Colors.teal,
  DosageForm.injection => Colors.red,
  DosageForm.cream => Colors.orange,
  DosageForm.drops => Colors.cyan,
  DosageForm.powder => Colors.amber,
  DosageForm.inhaler => Colors.purple,
};

String _formLabel(DosageForm f) => switch (f) {
  DosageForm.tablet => 'Tablet',
  DosageForm.capsule => 'Capsule',
  DosageForm.syrup => 'Syrup',
  DosageForm.injection => 'Injection',
  DosageForm.cream => 'Cream',
  DosageForm.drops => 'Drops',
  DosageForm.powder => 'Powder',
  DosageForm.inhaler => 'Inhaler',
};

String _formEmoji(DosageForm f) => switch (f) {
  DosageForm.tablet => '💊',
  DosageForm.capsule => '💉',
  DosageForm.syrup => '🍶',
  DosageForm.injection => '💉',
  DosageForm.cream => '🧴',
  DosageForm.drops => '💧',
  DosageForm.powder => '🧂',
  DosageForm.inhaler => '🌬️',
};

IconData _formIcon(DosageForm f) => switch (f) {
  DosageForm.tablet => Icons.medication_outlined,
  DosageForm.capsule => Icons.medication_liquid_outlined,
  DosageForm.syrup => Icons.water_drop_outlined,
  DosageForm.injection => Icons.vaccines_outlined,
  DosageForm.cream => Icons.sanitizer_outlined,
  DosageForm.drops => Icons.opacity_outlined,
  DosageForm.powder => Icons.grain_outlined,
  DosageForm.inhaler => Icons.air_outlined,
};
