// customer_form_page.dart
// Changes in this version:
//   1. Location section: hierarchical Tanzania dropdowns
//      Country (fixed: Tanzania) → Region → District → Ward → Street
//      Each level resets the ones below it on change.
//      Levels with no static data (district/ward/street when unknown)
//      show a free-text fallback field instead.
//   2. Officer dropdown: uses `initialValue` guard + dedup.
//      The underlying dedup is in OfficerRemoteDataSourceImpl.getAll().
//      The form additionally guards against stale _selectedOfficerId
//      not matching any loaded officer (sets to null in that case).
//   3. Refresh button added to AppBar.
//   4. Both city and county controllers removed — replaced by
//      dropdown-selected values (_region, _district, _ward, _street).
//      The city field sent to the API is now the district value
//      and county is the region value for backwards compatibility.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/di/injection_container.dart';
import '../../../../core/data/tanzania_locations.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../../../officer/data/datasources/officer_remote_datasource.dart';
import '../../../officer/domain/entities/officer_entity.dart';

enum CustomerFormMode { create, edit }

class CustomerFormPage extends StatefulWidget {
  final CustomerFormMode mode;
  final String? id;
  const CustomerFormPage({
    super.key,
    this.mode = CustomerFormMode.create,
    this.id,
  });
  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _whatsappCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  // Free-text fallbacks when static data doesn't cover the selected level
  final _wardFreeCtl = TextEditingController();
  final _streetFreeCtl = TextEditingController();
  final _gpsLatCtl = TextEditingController();
  final _gpsLngCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  final _contactNameCtl = TextEditingController();
  final _contactPhoneCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmPassCtl = TextEditingController();

  bool _enableAppLogin = false;

  String _customerType = 'b2b';
  String? _category;
  String? _tier;
  String? _contactRole;
  String? _selectedOfficerId;

  // Location state
  // Country is always Tanzania.
  String? _region;
  String? _district;
  String? _ward;
  String? _street;

  bool _isSubmitting = false;
  bool _fieldsPopulated = false;
  bool _gpsLoading = false;
  bool get _isEdit => widget.mode == CustomerFormMode.edit;
  bool get _hasValidGps =>
      double.tryParse(_gpsLatCtl.text.trim()) != null &&
      double.tryParse(_gpsLngCtl.text.trim()) != null;

  List<OfficerEntity> _officers = [];
  bool _officersLoading = true;

  static const _categories = [
    'clinic',
    'hospital',
    'pharmacy',
    'wholesaler',
    'other',
  ];
  static const _tiers = ['standard', 'silver', 'gold', 'platinum'];
  static const _contactRoles = [
    'owner',
    'pharmacist',
    'doctor',
    'nurse',
    'procurement',
    'manager',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _loadOfficers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _captureGps();
    });
  }

  Future<void> _loadOfficers() async {
    if (mounted) setState(() => _officersLoading = true);
    try {
      final ds = sl<OfficerRemoteDataSource>();
      final result = await ds.getAll();
      if (mounted) {
        setState(() {
          _officers = result.items;
          _officersLoading = false;
          // Guard: if the pre-selected officer is no longer in the list, clear.
          if (_selectedOfficerId != null &&
              !_officers.any((o) => o.actorId == _selectedOfficerId)) {
            _selectedOfficerId = null;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _officersLoading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtl, _phoneCtl, _emailCtl, _whatsappCtl, _addressCtl,
      _wardFreeCtl, _streetFreeCtl, _gpsLatCtl, _gpsLngCtl, _notesCtl,
      _contactNameCtl, _contactPhoneCtl, _passwordCtl, _confirmPassCtl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _populateFields(CustomerState state) {
    if (_isEdit && !_fieldsPopulated && state is CustomerDetailLoaded) {
      final item = state.item;
      _nameCtl.text = item.name;
      _phoneCtl.text = item.phone ?? '';
      _emailCtl.text = item.email ?? '';
      _whatsappCtl.text = item.whatsappNumber ?? '';
      _addressCtl.text = item.address ?? '';
      _gpsLatCtl.text = item.latitude?.toString() ?? '';
      _gpsLngCtl.text = item.longitude?.toString() ?? '';
      _notesCtl.text = item.notes ?? '';
      _customerType = item.customerType;
      _category = _categories.contains(item.category) ? item.category : null;
      _tier = _tiers.contains(item.tier) ? item.tier : null;
      _selectedOfficerId = item.assignedOfficerId;

      // Populate location from stored county (region) and city (district)
      final storedRegion = item.county; // county stored as region
      final storedDistrict = item.city; // city stored as district

      if (storedRegion != null &&
          TanzaniaLocations.regions.contains(storedRegion)) {
        _region = storedRegion;
        final districts = TanzaniaLocations.getDistricts(storedRegion);
        if (storedDistrict != null && districts.contains(storedDistrict)) {
          _district = storedDistrict;
        } else if (storedDistrict != null && storedDistrict.isNotEmpty) {
          // District not in static list — show in free-text ward fallback
          _district = null;
          _wardFreeCtl.text = storedDistrict;
        }
      } else if (storedRegion != null && storedRegion.isNotEmpty) {
        _wardFreeCtl.text = storedRegion;
      }

      final pc = item.primaryContact;
      if (pc != null) {
        _contactNameCtl.text = pc.name;
        _contactPhoneCtl.text = pc.phone ?? '';
        _contactRole = pc.role;
      }
      _fieldsPopulated = true;

      // After populating, guard officer selection
      if (_selectedOfficerId != null &&
          _officers.isNotEmpty &&
          !_officers.any((o) => o.actorId == _selectedOfficerId)) {
        _selectedOfficerId = null;
      }
    }
  }

  // ── GPS capture ───────────────────────────────────────────

  Future<void> _captureGps() async {
    if (!mounted) return;
    setState(() => _gpsLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _gpsLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS service is disabled')),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _gpsLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission permanently denied. Enable it in Settings.',
              ),
            ),
          );
        }
        return;
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        if (mounted) setState(() => _gpsLoading = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _gpsLatCtl.text = position.latitude.toStringAsFixed(6);
          _gpsLngCtl.text = position.longitude.toStringAsFixed(6);
          _gpsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _gpsLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('GPS error: $e')));
      }
    }
  }

  Future<void> _openInMap() async {
    final lat = double.tryParse(_gpsLatCtl.text.trim());
    final lng = double.tryParse(_gpsLngCtl.text.trim());
    if (lat == null || lng == null) return;
    final gmaps = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(gmaps)) {
      await launchUrl(gmaps, mode: LaunchMode.externalApplication);
    }
  }

  // ── Location helpers ──────────────────────────────────────

  /// The effective "city" value sent to the API — district if selected,
  /// otherwise the free-text ward field.
  String get _effectiveCity =>
      _district ?? _wardFreeCtl.text.trim();

  /// The effective "county" value sent to the API — region if selected,
  /// otherwise the free-text ward field.
  String get _effectiveCounty => _region ?? '';

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Customer' : 'New Customer'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload',
              onPressed: () {
                if (widget.id != null) {
                  setState(() => _fieldsPopulated = false);
                  context
                      .read<CustomerBloc>()
                      .add(CustomerLoadOneRequested(widget.id!));
                }
                _loadOfficers();
              },
            ),
        ],
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          _populateFields(state);
          if (state is CustomerOperationSuccess) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.of(context).pop(true);
          }
          if (state is CustomerFailure) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (_isEdit && state is CustomerLoading && !_fieldsPopulated) {
            return const Center(child: CircularProgressIndicator());
          }
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide
                    ? MediaQuery.of(context).size.width * 0.1
                    : 16,
                vertical: 16,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Customer Type + Name ──
                    _sectionLabel(context, 'Customer Information'),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'b2b',
                          label: Text('B2B'),
                          icon: Icon(Icons.store),
                        ),
                        ButtonSegment(
                          value: 'b2c',
                          label: Text('B2C'),
                          icon: Icon(Icons.person),
                        ),
                      ],
                      selected: {_customerType},
                      onSelectionChanged: (s) =>
                          setState(() => _customerType = s.first),
                    ),
                    const SizedBox(height: 16),
                    _field(
                      _nameCtl,
                      _customerType == 'b2b' ? 'Business Name' : 'Full Name',
                      Icons.store,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_customerType == 'b2b') ...[
                            Expanded(
                              child: _dropdown(
                                'Category',
                                _categories,
                                _category,
                                (v) => setState(() => _category = v),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: _dropdown(
                              'Tier',
                              _tiers,
                              _tier,
                              (v) => setState(() => _tier = v),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      if (_customerType == 'b2b') ...[
                        _dropdown(
                          'Category',
                          _categories,
                          _category,
                          (v) => setState(() => _category = v),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _dropdown(
                        'Tier',
                        _tiers,
                        _tier,
                        (v) => setState(() => _tier = v),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── Communication ──
                    _sectionLabel(context, 'Communication'),
                    const SizedBox(height: 8),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              _phoneCtl,
                              'Phone',
                              Icons.phone,
                              keyboard: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _field(
                              _emailCtl,
                              'Email',
                              Icons.email_outlined,
                              keyboard: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _field(
                        _phoneCtl,
                        'Phone',
                        Icons.phone,
                        keyboard: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        _emailCtl,
                        'Email',
                        Icons.email_outlined,
                        keyboard: TextInputType.emailAddress,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _field(
                      _whatsappCtl,
                      'WhatsApp Number',
                      Icons.chat,
                      keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // ── Primary Contact Person ──
                    _sectionLabel(context, 'Primary Contact Person'),
                    const SizedBox(height: 8),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              _contactNameCtl,
                              'Contact Name',
                              Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _dropdown(
                              'Role',
                              _contactRoles,
                              _contactRole,
                              (v) => setState(() => _contactRole = v),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _field(
                        _contactNameCtl,
                        'Contact Name',
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _dropdown(
                        'Role',
                        _contactRoles,
                        _contactRole,
                        (v) => setState(() => _contactRole = v),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _field(
                      _contactPhoneCtl,
                      'Contact Phone',
                      Icons.phone_forwarded_outlined,
                      keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // ── Location ──────────────────────────────────────────
                    _sectionLabel(context, 'Location'),
                    const SizedBox(height: 8),

                    // Country (fixed)
                    _staticField(
                      'Country',
                      TanzaniaLocations.country,
                      Icons.public,
                    ),
                    const SizedBox(height: 16),

                    // Region
                    _dropdown(
                      'Region',
                      TanzaniaLocations.regions,
                      _region,
                      (v) => setState(() {
                        _region = v;
                        // Reset children
                        _district = null;
                        _ward = null;
                        _street = null;
                        _wardFreeCtl.clear();
                        _streetFreeCtl.clear();
                      }),
                    ),
                    const SizedBox(height: 16),

                    // District — shown only when region is selected
                    if (_region != null) ...[
                      () {
                        final dList =
                            TanzaniaLocations.getDistricts(_region!);
                        if (dList.isEmpty) {
                          // No static districts — free-text
                          return _field(
                            _wardFreeCtl,
                            'District / City',
                            Icons.location_city,
                          );
                        }
                        return _dropdown(
                          'District / City',
                          dList,
                          _district,
                          (v) => setState(() {
                            _district = v;
                            _ward = null;
                            _street = null;
                            _wardFreeCtl.clear();
                            _streetFreeCtl.clear();
                          }),
                        );
                      }(),
                      const SizedBox(height: 16),
                    ],

                    // Ward — shown only when district is selected
                    if (_district != null) ...[
                      () {
                        final wList =
                            TanzaniaLocations.getWards(_district!);
                        if (wList.isEmpty) {
                          return _field(
                            _wardFreeCtl,
                            'Ward',
                            Icons.map_outlined,
                          );
                        }
                        return _dropdown(
                          'Ward',
                          wList,
                          _ward,
                          (v) => setState(() {
                            _ward = v;
                            _street = null;
                            _streetFreeCtl.clear();
                          }),
                        );
                      }(),
                      const SizedBox(height: 16),
                    ],

                    // Street — shown only when ward is selected
                    if (_ward != null) ...[
                      () {
                        final sList =
                            TanzaniaLocations.getStreets(_ward!);
                        if (sList.isEmpty) {
                          return _field(
                            _streetFreeCtl,
                            'Street',
                            Icons.signpost_outlined,
                          );
                        }
                        return _dropdown(
                          'Street',
                          sList,
                          _street,
                          (v) => setState(() => _street = v),
                        );
                      }(),
                      const SizedBox(height: 16),
                    ],

                    // Full address (optional free-text)
                    _field(
                      _addressCtl,
                      'Full Address (optional)',
                      Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // GPS
                    Row(
                      children: [
                        Text(
                          'GPS Coordinates',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const Spacer(),
                        if (_gpsLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          TextButton.icon(
                            onPressed: _captureGps,
                            icon: const Icon(Icons.my_location, size: 16),
                            label: const Text('Auto-capture'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        ValueListenableBuilder(
                          valueListenable: _gpsLatCtl,
                          builder: (_, __, ___) => ValueListenableBuilder(
                            valueListenable: _gpsLngCtl,
                            builder: (_, __, ___) => _hasValidGps
                                ? TextButton.icon(
                                    onPressed: _openInMap,
                                    icon: const Icon(
                                      Icons.map_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Open in Map'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              _gpsLatCtl,
                              'Latitude',
                              Icons.gps_fixed,
                              keyboard: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _field(
                              _gpsLngCtl,
                              'Longitude',
                              Icons.gps_fixed,
                              keyboard: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _field(
                        _gpsLatCtl,
                        'Latitude',
                        Icons.gps_fixed,
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _field(
                        _gpsLngCtl,
                        'Longitude',
                        Icons.gps_fixed,
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── Officer Assignment ──
                    _sectionLabel(context, 'Officer Assignment'),
                    const SizedBox(height: 8),
                    _buildOfficerDropdown(),
                    const SizedBox(height: 24),

                    // ── Notes ──
                    _sectionLabel(context, 'Notes'),
                    const SizedBox(height: 8),
                    _field(
                      _notesCtl,
                      'Internal notes',
                      Icons.notes,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // ── App Login Credentials ──
                    _sectionLabel(context, 'Customer App Login'),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _enableAppLogin,
                      title: Text(
                        _isEdit
                            ? 'Change App Login Password'
                            : 'Enable Customer App Login',
                      ),
                      subtitle: Text(
                        _isEdit
                            ? 'Set a new password for the customer app'
                            : 'Set a password so customer can log into jadosoft-lite',
                      ),
                      onChanged: (v) => setState(() => _enableAppLogin = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_enableAppLogin) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                          helperText: 'Min 8 characters',
                        ),
                        validator: (v) {
                          if (!_enableAppLogin) return null;
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 8) return 'At least 8 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPassCtl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) {
                          if (!_enableAppLogin) return null;
                          if (v != _passwordCtl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEdit
                            ? 'Password will be updated for the existing account.'
                            : 'Email above will be used as the login credential.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_isEdit ? Icons.save : Icons.store_outlined),
                      label: Text(_isEdit ? 'Save Changes' : 'Create Customer'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Officer dropdown ──────────────────────────────────────
  // Guards against duplicate actorId values from the API by
  // using the deduped list from OfficerRemoteDataSourceImpl.
  // Additionally clears the selected value if not found in list.

  Widget _buildOfficerDropdown() {
    if (_officersLoading) return const LinearProgressIndicator();

    // Build the eligible list: active officers + the currently assigned one
    final eligible = _officers
        .where(
          (o) =>
              o.effectiveStatus == 'active' ||
              o.actorId == _selectedOfficerId,
        )
        .toList();

    // Ensure the selected value exists exactly once in the items
    final validSelection =
        eligible.where((o) => o.actorId == _selectedOfficerId).length == 1
            ? _selectedOfficerId
            : null;

    // Sync state if the guard cleared the value
    if (validSelection != _selectedOfficerId) {
      // Schedule post-frame to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedOfficerId = validSelection);
      });
    }

    return DropdownButtonFormField<String>(
      value: validSelection,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Assigned Officer',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.badge_outlined),
      ),
      items: eligible
          .map(
            (o) => DropdownMenuItem(
              value: o.actorId,
              child: Text(
                '${o.displayName} (${o.orgRoleName ?? ""})'
                '${o.effectiveStatus != "active" ? " (inactive)" : ""}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedOfficerId = v),
      validator: (v) {
        if (!_isEdit && (v == null || v.isEmpty)) {
          return 'Assigned officer is required';
        }
        return null;
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w700,
    ),
  );

  /// A read-only display field (not a real form field)
  Widget _staticField(String label, String value, IconData icon) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      prefixIcon: Icon(icon),
    ),
    child: Text(value),
  );

  Widget _field(
    TextEditingController ctl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) => TextFormField(
    controller: ctl,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      prefixIcon: Icon(icon),
    ),
    keyboardType: keyboard,
    maxLines: maxLines,
    textCapitalization: keyboard == null
        ? TextCapitalization.words
        : TextCapitalization.none,
    validator: required
        ? (v) {
            if (v == null || v.trim().isEmpty) return '$label is required';
            return null;
          }
        : null,
  );

  Widget _dropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String>(
    value: items.contains(value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      prefixIcon: const Icon(Icons.arrow_drop_down),
    ),
    items: items
        .map(
          (e) => DropdownMenuItem(
            value: e,
            child: Text(
              e[0].toUpperCase() + e.substring(1),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: onChanged,
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final lat = double.tryParse(_gpsLatCtl.text.trim());
    final lng = double.tryParse(_gpsLngCtl.text.trim());

    // Build structured location string from hierarchy
    final locationParts = <String>[
      if (_street != null && _street!.isNotEmpty) _street!,
      if (_streetFreeCtl.text.trim().isNotEmpty) _streetFreeCtl.text.trim(),
      if (_ward != null && _ward!.isNotEmpty) _ward!,
      if (_wardFreeCtl.text.trim().isNotEmpty) _wardFreeCtl.text.trim(),
    ];
    final structuredAddress = locationParts.isNotEmpty
        ? locationParts.join(', ')
        : _addressCtl.text.trim();
    final finalAddress = _addressCtl.text.trim().isNotEmpty
        ? _addressCtl.text.trim()
        : structuredAddress;

    if (_isEdit) {
      final s = context.read<CustomerBloc>().state;
      if (s is CustomerDetailLoaded) {
        context.read<CustomerBloc>().add(
          CustomerUpdateRequested(
            s.item.copyWith(
              name: _nameCtl.text.trim(),
              phone: _phoneCtl.text.trim(),
              email: _emailCtl.text.trim(),
              whatsappNumber: _whatsappCtl.text.trim(),
              address: finalAddress,
              city: _effectiveCity,    // district
              county: _effectiveCounty, // region
              country: TanzaniaLocations.country,
              latitude: lat,
              longitude: lng,
              notes: _notesCtl.text.trim(),
              category: _category,
              tier: _tier,
              assignedOfficerId: _selectedOfficerId,
            ),
            appPassword: _enableAppLogin ? _passwordCtl.text : null,
            appPasswordConfirmation: _enableAppLogin
                ? _confirmPassCtl.text
                : null,
          ),
        );
      }
    } else {
      context.read<CustomerBloc>().add(
        CustomerCreateRequested(
          CreateCustomerParams(
            name: _nameCtl.text.trim(),
            customerType: _customerType,
            category: _category,
            tier: _tier,
            phone: _phoneCtl.text.trim(),
            email: _emailCtl.text.trim(),
            whatsappNumber: _whatsappCtl.text.trim(),
            address: finalAddress,
            city: _effectiveCity,
            county: _effectiveCounty,
            latitude: lat,
            longitude: lng,
            notes: _notesCtl.text.trim(),
            contactName: _contactNameCtl.text.trim(),
            contactRole: _contactRole,
            contactPhone: _contactPhoneCtl.text.trim(),
            assignedOfficerId: _selectedOfficerId,
            appPassword: _enableAppLogin ? _passwordCtl.text : null,
            appPasswordConfirmation: _enableAppLogin
                ? _confirmPassCtl.text
                : null,
          ),
        ),
      );
    }
  }
}