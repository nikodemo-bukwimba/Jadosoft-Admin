import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../../../officer/data/datasources/officer_mock_datasource.dart';
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
  final _businessNameCtl = TextEditingController();
  final _fullOfficeNameCtl = TextEditingController();
  final _ownerNameCtl = TextEditingController();
  final _officialPhoneCtl = TextEditingController();
  final _contactPersonCtl = TextEditingController();
  final _contactPersonPhoneCtl = TextEditingController();
  final _officeAddressCtl = TextEditingController();
  final _gpsLatCtl = TextEditingController();
  final _gpsLngCtl = TextEditingController();
  String? _selectedOfficerId;

  bool _isSubmitting = false;
  bool _fieldsPopulated = false;
  bool _gpsLoading = false;
  bool get _isEdit => widget.mode == CustomerFormMode.edit;

  List<OfficerEntity> _officers = [];
  bool _officersLoading = true;

  bool get _hasValidGps {
    final lat = double.tryParse(_gpsLatCtl.text.trim());
    final lng = double.tryParse(_gpsLngCtl.text.trim());
    return lat != null && lng != null;
  }

  @override
  void initState() {
    super.initState();
    _loadOfficers();
    if (!_isEdit) _captureGps();
  }

  Future<void> _loadOfficers() async {
    try {
      final ds = OfficerMockDataSource();
      final list = await ds.getAll();
      if (mounted) {
        setState(() {
          _officers = list;
          _officersLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _officersLoading = false);
    }
  }

  Future<void> _captureGps() async {
    if (!mounted) return;
    setState(() => _gpsLoading = true);
    try {
      final loc = Location();
      bool serviceEnabled = await loc.serviceEnabled();
      if (!serviceEnabled) serviceEnabled = await loc.requestService();

      PermissionStatus permission = await loc.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await loc.requestPermission();
      }
      if (permission != PermissionStatus.granted) {
        if (mounted) setState(() => _gpsLoading = false);
        return;
      }
      final data = await loc.getLocation();
      if (mounted) {
        setState(() {
          _gpsLatCtl.text = data.latitude?.toStringAsFixed(6) ?? '';
          _gpsLngCtl.text = data.longitude?.toStringAsFixed(6) ?? '';
          _gpsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _openInMap() async {
    final lat = double.tryParse(_gpsLatCtl.text.trim());
    final lng = double.tryParse(_gpsLngCtl.text.trim());
    if (lat == null || lng == null) return;

    final label = Uri.encodeComponent(
      _businessNameCtl.text.trim().isNotEmpty
          ? _businessNameCtl.text.trim()
          : 'Customer Location',
    );

    final gmaps = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');

    if (await canLaunchUrl(gmaps)) {
      await launchUrl(gmaps, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(geo)) {
      await launchUrl(geo);
    }
  }

  @override
  void dispose() {
    _businessNameCtl.dispose();
    _fullOfficeNameCtl.dispose();
    _ownerNameCtl.dispose();
    _officialPhoneCtl.dispose();
    _contactPersonCtl.dispose();
    _contactPersonPhoneCtl.dispose();
    _officeAddressCtl.dispose();
    _gpsLatCtl.dispose();
    _gpsLngCtl.dispose();
    super.dispose();
  }

  void _populateFields(CustomerState state) {
    if (_isEdit && !_fieldsPopulated && state is CustomerDetailLoaded) {
      final item = state.item;
      _businessNameCtl.text = item.businessName;
      _fullOfficeNameCtl.text = item.fullOfficeName ?? '';
      _ownerNameCtl.text = item.ownerName;
      _officialPhoneCtl.text = item.officialPhone;
      _contactPersonCtl.text = item.contactPerson ?? '';
      _contactPersonPhoneCtl.text = item.contactPersonPhone ?? '';
      _officeAddressCtl.text = item.officeAddress ?? '';
      _gpsLatCtl.text = item.gpsLat?.toString() ?? '';
      _gpsLngCtl.text = item.gpsLng?.toString() ?? '';
      _selectedOfficerId = item.assignedOfficerId;
      _fieldsPopulated = true;
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
          if (state is CustomerDetailLoaded)
            setState(() => _populateFields(state));
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
                    // ── Business Info ───────────────────────────────────
                    _sectionLabel(context, 'Business Information'),
                    const SizedBox(height: 8),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              _businessNameCtl,
                              'Business Name',
                              Icons.store,
                              required: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _field(
                              _fullOfficeNameCtl,
                              'Full Office Name',
                              Icons.business,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _field(
                        _businessNameCtl,
                        'Business Name',
                        Icons.store,
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        _fullOfficeNameCtl,
                        'Full Office Name',
                        Icons.business,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── Owner & Contact ─────────────────────────────────
                    _sectionLabel(context, 'Owner & Contact'),
                    const SizedBox(height: 8),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              _ownerNameCtl,
                              'Owner Name',
                              Icons.person,
                              required: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _field(
                              _officialPhoneCtl,
                              'Official Phone',
                              Icons.phone,
                              required: true,
                              keyboard: TextInputType.phone,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _field(
                        _ownerNameCtl,
                        'Owner Name',
                        Icons.person,
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        _officialPhoneCtl,
                        'Official Phone',
                        Icons.phone,
                        required: true,
                        keyboard: TextInputType.phone,
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              _contactPersonCtl,
                              'Contact Person',
                              Icons.people_outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _field(
                              _contactPersonPhoneCtl,
                              'Contact Phone',
                              Icons.phone_forwarded_outlined,
                              keyboard: TextInputType.phone,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _field(
                        _contactPersonCtl,
                        'Contact Person',
                        Icons.people_outline,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        _contactPersonPhoneCtl,
                        'Contact Phone',
                        Icons.phone_forwarded_outlined,
                        keyboard: TextInputType.phone,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── Location ────────────────────────────────────────
                    _sectionLabel(context, 'Location'),
                    const SizedBox(height: 8),
                    _field(
                      _officeAddressCtl,
                      'Office Address',
                      Icons.location_on_outlined,
                      maxLines: 2,
                    ),
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
                        // "Open in Map" — only visible when coords are filled
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

                    // Lat / Lng fields
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

                    // ── Officer Assignment ──────────────────────────────
                    _sectionLabel(context, 'Officer Assignment'),
                    const SizedBox(height: 8),
                    _officersLoading
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<String>(
                            value: _selectedOfficerId,
                            isExpanded: true, // ← fixes the overflow
                            decoration: const InputDecoration(
                              labelText: 'Assigned Officer',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            items: _officers
                                .where((o) => o.effectiveStatus == 'active')
                                .map(
                                  (o) => DropdownMenuItem(
                                    value: o.userId,
                                    child: Text(
                                      '${o.displayName} (${o.orgRoleName ?? ''})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedOfficerId = v),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Assigned officer is required';
                              return null;
                            },
                          ),
                    const SizedBox(height: 32),

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

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _field(
    TextEditingController ctl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextFormField(
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
  }

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
              businessName: _businessNameCtl.text.trim(),
              fullOfficeName: _fullOfficeNameCtl.text.trim(),
              ownerName: _ownerNameCtl.text.trim(),
              officialPhone: _officialPhoneCtl.text.trim(),
              contactPerson: _contactPersonCtl.text.trim(),
              contactPersonPhone: _contactPersonPhoneCtl.text.trim(),
              officeAddress: _officeAddressCtl.text.trim(),
              gpsLat: lat,
              gpsLng: lng,
              assignedOfficerId: _selectedOfficerId ?? '',
            ),
          ),
        );
      }
    } else {
      context.read<CustomerBloc>().add(
        CustomerCreateRequested(
          CreateCustomerParams(
            businessName: _businessNameCtl.text.trim(),
            fullOfficeName: _fullOfficeNameCtl.text.trim(),
            ownerName: _ownerNameCtl.text.trim(),
            officialPhone: _officialPhoneCtl.text.trim(),
            contactPerson: _contactPersonCtl.text.trim(),
            contactPersonPhone: _contactPersonPhoneCtl.text.trim(),
            officeAddress: _officeAddressCtl.text.trim(),
            gpsLat: lat,
            gpsLng: lng,
            assignedOfficerId: _selectedOfficerId ?? '',
          ),
        ),
      );
    }
  }
}
