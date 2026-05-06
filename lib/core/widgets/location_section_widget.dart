// lib/core/widgets/location_section_widget.dart
//
// Reusable Tanzania location hierarchy widget.
// Used by CustomerFormPage in both jadosoft-admin and jadosoft-officer.
//
// Hierarchy: Country (fixed) → Region (dropdown) → District (dropdown or text)
//            → Ward (dropdown or text) → Street (dropdown or text)
//
// Rule: if static data exists for a level, show a DropdownButtonFormField
//       with a search box in the menu. If no data exists, show a plain
//       TextFormField so the user can type freely.
//
// The widget is controlled externally via [LocationValue] and notifies
// the parent via [onChanged].

import 'package:flutter/material.dart';
import '../data/tanzania_locations.dart';

/// Immutable snapshot of the selected location hierarchy.
class LocationValue {
  final String country;
  final String? region;
  final String? district;
  final String? ward;
  final String? street;

  /// The "city" field sent to the API is the district (or ward free-text).
  String get effectiveCity => district ?? ward ?? '';

  /// The "county" field sent to the API is the region.
  String get effectiveCounty => region ?? '';

  const LocationValue({
    this.country = TanzaniaLocations.country,
    this.region,
    this.district,
    this.ward,
    this.street,
  });

  LocationValue copyWith({
    String? country,
    String? region,
    String? district,
    String? ward,
    String? street,
    bool clearDistrict = false,
    bool clearWard = false,
    bool clearStreet = false,
  }) {
    return LocationValue(
      country: country ?? this.country,
      region: region ?? this.region,
      district: clearDistrict ? null : (district ?? this.district),
      ward: clearWard ? null : (ward ?? this.ward),
      street: clearStreet ? null : (street ?? this.street),
    );
  }

  /// Build a LocationValue from the raw city/county strings stored in the API.
  factory LocationValue.fromApiFields({String? city, String? county}) {
    String? resolvedRegion;
    String? resolvedDistrict;

    if (county != null && TanzaniaLocations.regions.contains(county)) {
      resolvedRegion = county;
    }
    if (resolvedRegion != null && city != null) {
      final districts = TanzaniaLocations.getDistricts(resolvedRegion);
      if (districts.contains(city)) {
        resolvedDistrict = city;
      }
    }
    return LocationValue(
      region: resolvedRegion,
      district: resolvedDistrict,
    );
  }

  @override
  String toString() =>
      'LocationValue(region: $region, district: $district, ward: $ward, street: $street)';
}

/// The full location section widget — drop into a Form Column.
class LocationSectionWidget extends StatefulWidget {
  final LocationValue value;
  final ValueChanged<LocationValue> onChanged;

  const LocationSectionWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<LocationSectionWidget> createState() => _LocationSectionWidgetState();
}

class _LocationSectionWidgetState extends State<LocationSectionWidget> {
  // Free-text controllers for levels that lack static data.
  // They are only visible / used when the corresponding dropdown list is empty.
  final _districtFreeCtl = TextEditingController();
  final _wardFreeCtl = TextEditingController();
  final _streetFreeCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncFreeTextFromValue(widget.value);
  }

  @override
  void didUpdateWidget(LocationSectionWidget old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _syncFreeTextFromValue(widget.value);
    }
  }

  void _syncFreeTextFromValue(LocationValue v) {
    // Only populate free-text controllers when the value is NOT in static data.
    if (v.region != null) {
      final dList = TanzaniaLocations.getDistricts(v.region!);
      if (dList.isEmpty && v.district != null) {
        _districtFreeCtl.text = v.district!;
      }
      if (v.district != null) {
        final wList = TanzaniaLocations.getWards(v.district!);
        if (wList.isEmpty && v.ward != null) {
          _wardFreeCtl.text = v.ward!;
        }
        if (v.ward != null) {
          final sList = TanzaniaLocations.getStreets(v.ward!);
          if (sList.isEmpty && v.street != null) {
            _streetFreeCtl.text = v.street!;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _districtFreeCtl.dispose();
    _wardFreeCtl.dispose();
    _streetFreeCtl.dispose();
    super.dispose();
  }

  // ── Notify helpers ────────────────────────────────────────

  void _onRegionChanged(String? v) {
    _districtFreeCtl.clear();
    _wardFreeCtl.clear();
    _streetFreeCtl.clear();
    widget.onChanged(LocationValue(region: v));
  }

  void _onDistrictSelected(String? v) {
    _wardFreeCtl.clear();
    _streetFreeCtl.clear();
    widget.onChanged(
      widget.value.copyWith(
        district: v,
        clearWard: true,
        clearStreet: true,
      ),
    );
  }

  void _onDistrictTyped(String v) {
    widget.onChanged(
      widget.value.copyWith(
        district: v.trim().isEmpty ? null : v.trim(),
        clearWard: true,
        clearStreet: true,
      ),
    );
  }

  void _onWardSelected(String? v) {
    _streetFreeCtl.clear();
    widget.onChanged(
      widget.value.copyWith(ward: v, clearStreet: true),
    );
  }

  void _onWardTyped(String v) {
    widget.onChanged(
      widget.value.copyWith(
        ward: v.trim().isEmpty ? null : v.trim(),
        clearStreet: true,
      ),
    );
  }

  void _onStreetSelected(String? v) {
    widget.onChanged(widget.value.copyWith(street: v));
  }

  void _onStreetTyped(String v) {
    widget.onChanged(
      widget.value.copyWith(street: v.trim().isEmpty ? null : v.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value;

    final districtList =
        v.region != null ? TanzaniaLocations.getDistricts(v.region!) : <String>[];
    final wardList =
        v.district != null ? TanzaniaLocations.getWards(v.district!) : <String>[];
    final streetList =
        v.ward != null ? TanzaniaLocations.getStreets(v.ward!) : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Country (always Tanzania, read-only)
        _StaticField(
          label: 'Country',
          value: TanzaniaLocations.country,
          icon: Icons.public,
        ),
        const SizedBox(height: 16),

        // Region
        _SearchableDropdown(
          label: 'Region',
          icon: Icons.map_outlined,
          items: TanzaniaLocations.regions,
          value: v.region,
          onChanged: _onRegionChanged,
        ),

        // District — only shown after region is selected
        if (v.region != null) ...[
          const SizedBox(height: 16),
          if (districtList.isNotEmpty)
            _SearchableDropdown(
              label: 'District / City',
              icon: Icons.location_city,
              items: districtList,
              value: v.district,
              onChanged: _onDistrictSelected,
            )
          else
            _FreeTextField(
              controller: _districtFreeCtl,
              label: 'District / City',
              icon: Icons.location_city,
              hint: 'Type district name',
              onChanged: _onDistrictTyped,
            ),
        ],

        // Ward — only shown after district is selected or typed
        if (v.district != null && v.district!.isNotEmpty) ...[
          const SizedBox(height: 16),
          if (wardList.isNotEmpty)
            _SearchableDropdown(
              label: 'Ward',
              icon: Icons.villa_outlined,
              items: wardList,
              value: v.ward,
              onChanged: _onWardSelected,
            )
          else
            _FreeTextField(
              controller: _wardFreeCtl,
              label: 'Ward',
              icon: Icons.villa_outlined,
              hint: 'Type ward name',
              onChanged: _onWardTyped,
            ),
        ],

        // Street — only shown after ward is selected or typed
        if (v.ward != null && v.ward!.isNotEmpty) ...[
          const SizedBox(height: 16),
          if (streetList.isNotEmpty)
            _SearchableDropdown(
              label: 'Street',
              icon: Icons.signpost_outlined,
              items: streetList,
              value: v.street,
              onChanged: _onStreetSelected,
            )
          else
            _FreeTextField(
              controller: _streetFreeCtl,
              label: 'Street',
              icon: Icons.signpost_outlined,
              hint: 'Type street name',
              onChanged: _onStreetTyped,
            ),
        ],
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

/// Read-only static display field.
class _StaticField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StaticField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      child: Text(value),
    );
  }
}

/// Free-text field with a helper hint.
class _FreeTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final ValueChanged<String> onChanged;

  const _FreeTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        suffixIcon: const Tooltip(
          message: 'No list available — type manually',
          child: Icon(Icons.edit_outlined, size: 16),
        ),
      ),
    );
  }
}

/// Dropdown with an inline search box at the top of the menu.
class _SearchableDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _SearchableDropdown({
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Guard: value must be in items or null
    final safeValue = (value != null && items.contains(value)) ? value : null;

    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (safeValue != null)
                GestureDetector(
                  onTap: () => onChanged(null),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.clear, size: 16),
                  ),
                ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        child: Text(
          safeValue ?? '',
          style: safeValue == null
              ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
              : null,
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SearchablePicker(
        label: label,
        items: items,
        selected: value,
      ),
    );
    if (picked != null) onChanged(picked);
  }
}

/// The bottom sheet content — a filterable list.
class _SearchablePicker extends StatefulWidget {
  final String label;
  final List<String> items;
  final String? selected;

  const _SearchablePicker({
    required this.label,
    required this.items,
    required this.selected,
  });

  @override
  State<_SearchablePicker> createState() => _SearchablePickerState();
}

class _SearchablePickerState extends State<_SearchablePicker> {
  final _searchCtl = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtl.addListener(_filter);
  }

  void _filter() {
    final q = _searchCtl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items
              .where((e) => e.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxH = MediaQuery.of(context).size.height * 0.7;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select ${widget.label}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            // Search box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchCtl.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtered.isEmpty ? 1 : _filtered.length,
                itemBuilder: (_, i) {
                  if (_filtered.isEmpty) {
                    return const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Text(
                        'No results found.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final item = _filtered[i];
                  return ListTile(
                    title: Text(item),
                    selected: item == widget.selected,
                    selectedColor: scheme.primary,
                    selectedTileColor: scheme.primary.withValues(alpha: 0.08),
                    trailing: item == widget.selected
                        ? Icon(Icons.check, color: scheme.primary, size: 18)
                        : null,
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}