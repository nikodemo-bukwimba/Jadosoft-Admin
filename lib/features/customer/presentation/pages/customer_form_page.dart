// customer_form_page.dart
// ─────────────────────────────────────────────────────────────
// Fixes applied:
//   1. GPS: switched from `location` package (throws MissingPluginException
//      on channel Iyokone/Location) to `geolocator` which is already used
//      by the officer app and works on all platforms.
//   2. Password section: enabled for edit mode too — allows setting/changing
//      the customer's platform login password after initial creation.
//   3. Officer loading: uses the pharma officers endpoint
//      (GET /pharma/orgs/{orgId}/officers) via OfficerRemoteDataSource
//      which returns PmOfficer records. Previously used org members endpoint
//      which caused parse failures and "No implementation found" exceptions.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/di/injection_container.dart';
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
  final _cityCtl = TextEditingController();
  final _countyCtl = TextEditingController();
  final _gpsLatCtl = TextEditingController();
  final _gpsLngCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  final _contactNameCtl = TextEditingController();
  final _contactPhoneCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmPassCtl = TextEditingController();

  // App login toggle — enabled for both create AND edit
  bool _enableAppLogin = false;

  String _customerType = 'b2b';
  String? _category;
  String? _tier;
  String? _contactRole;
  String? _selectedOfficerId;

  bool _isSubmitting = false;
  bool _fieldsPopulated = false;
  bool _gpsLoading = false;
  bool get _isEdit => widget.mode == CustomerFormMode.edit;
  bool get _hasValidGps =>
      double.tryParse(_gpsLatCtl.text.trim()) != null &&
      double.tryParse(_gpsLngCtl.text.trim()) != null;

  // Officer loading state
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

  /// Load officers via the pharma officers endpoint.
  /// Falls back silently if the endpoint is unavailable.
  Future<void> _loadOfficers() async {
    try {
      final ds = sl<OfficerRemoteDataSource>();
      final result = await ds.getAll();
      if (mounted) {
        setState(() {
          _officers = result.items;
          _officersLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _officersLoading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtl,
      _phoneCtl,
      _emailCtl,
      _whatsappCtl,
      _addressCtl,
      _cityCtl,
      _countyCtl,
      _gpsLatCtl,
      _gpsLngCtl,
      _notesCtl,
      _contactNameCtl,
      _contactPhoneCtl,
      _passwordCtl,
      _confirmPassCtl,
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
      _cityCtl.text = item.city ?? '';
      _countyCtl.text = item.county ?? '';
      _gpsLatCtl.text = item.latitude?.toString() ?? '';
      _gpsLngCtl.text = item.longitude?.toString() ?? '';
      _notesCtl.text = item.notes ?? '';
      _customerType = item.customerType;
      _category = _categories.contains(item.category) ? item.category : null;
      _tier = _tiers.contains(item.tier) ? item.tier : null;
      _selectedOfficerId = item.assignedOfficerId;
      final pc = item.primaryContact;
      if (pc != null) {
        _contactNameCtl.text = pc.name;
        _contactPhoneCtl.text = pc.phone ?? '';
        _contactRole = pc.role;
      }
      _fieldsPopulated = true;
    }
  }

  // ── GPS capture using geolocator (replaces location package) ──
  // geolocator is already in pubspec (used by officer app) and does not
  // throw MissingPluginException on the Iyokone/Location channel.

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Customer' : 'New Customer')),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerDetailLoaded) {
            setState(() => _populateFields(state));
          }
          if (state is CustomerOperationSuccess) {
            setState(() => _isSubmitting = false);
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

                    // ── Location ──
                    _sectionLabel(context, 'Location'),
                    const SizedBox(height: 8),
                    _field(
                      _addressCtl,
                      'Address',
                      Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              _cityCtl,
                              'City',
                              Icons.location_city,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _field(
                              _countyCtl,
                              'County / Region',
                              Icons.map_outlined,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _field(_cityCtl, 'City', Icons.location_city),
                      const SizedBox(height: 16),
                      _field(_countyCtl, 'County / Region', Icons.map_outlined),
                    ],
                    const SizedBox(height: 16),
                    // GPS header row
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
                    _officersLoading
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<String>(
                            initialValue:
                                _officers.any(
                                  (o) => o.actorId == _selectedOfficerId,
                                )
                                ? _selectedOfficerId
                                : null,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Assigned Officer',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            items: _officers
                                .where(
                                  (o) =>
                                      o.effectiveStatus == 'active' ||
                                      o.actorId == _selectedOfficerId,
                                )
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
                            onChanged: (v) =>
                                setState(() => _selectedOfficerId = v),
                            validator: (v) {
                              // Officer required on create; optional on edit
                              if (!_isEdit && (v == null || v.isEmpty)) {
                                return 'Assigned officer is required';
                              }
                              return null;
                            },
                          ),
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

                    // ── App Login Credentials ─────────────────────────────
                    // Available on BOTH create and edit modes.
                    // On edit: only sets the password — does not create a new
                    // platform user if one already exists.
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _sectionLabel(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w700,
    ),
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
    value: value,
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
            child: Text(e[0].toUpperCase() + e.substring(1)),
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
              address: _addressCtl.text.trim(),
              city: _cityCtl.text.trim(),
              county: _countyCtl.text.trim(),
              latitude: lat,
              longitude: lng,
              notes: _notesCtl.text.trim(),
              category: _category,
              tier: _tier,
              assignedOfficerId: _selectedOfficerId,
            ),
            // Pass password if the toggle is on
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
            address: _addressCtl.text.trim(),
            city: _cityCtl.text.trim(),
            county: _countyCtl.text.trim(),
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
