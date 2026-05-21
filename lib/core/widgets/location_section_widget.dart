// lib/core/widgets/location_section_widget.dart
//
// Tanzania location hierarchy widget — officer & admin apps.
//
// Country  : always static (read-only InputDecorator).
// Region   : free-text + searchable picker when static data exists.
// District : free-text + searchable picker when static data exists.
// Ward     : free-text + searchable picker when static data exists.
// Street   : free-text + searchable picker when static data exists.
//
// Each level below Country is a TextFormField that the user can type into
// directly.  When TanzaniaLocations has a list for that level a dropdown
// arrow icon is shown as a suffix; tapping it opens the searchable bottom-
// sheet picker and fills the text field with the chosen value.
// A clear (×) icon is shown whenever the field is non-empty.
//
// Cascade: changing a level clears all levels below it.
// Visibility: District is shown once Region has any text, Ward once District
// has any text, Street once Ward has any text.

import 'package:flutter/material.dart';
import '../data/tanzania_locations.dart';

// ── LocationValue ─────────────────────────────────────────────────────────────

class LocationValue {
  final String country;
  final String? region;
  final String? district;
  final String? ward;
  final String? street;

  /// Maps to the API's `city` field.
  String get effectiveCity => district ?? ward ?? '';

  /// Maps to the API's `county` field.
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
  }) =>
      LocationValue(
        country: country ?? this.country,
        region: region ?? this.region,
        district: clearDistrict ? null : (district ?? this.district),
        ward: clearWard ? null : (ward ?? this.ward),
        street: clearStreet ? null : (street ?? this.street),
      );

  /// Reconstruct from the flat city/county strings stored in the API.
  factory LocationValue.fromApiFields({String? city, String? county}) {
    final resolvedRegion =
        (county != null && TanzaniaLocations.regions.contains(county))
            ? county
            : county; // keep even if not in static list (free-text case)

    String? resolvedDistrict;
    if (resolvedRegion != null && city != null) {
      final districts = TanzaniaLocations.getDistricts(resolvedRegion);
      resolvedDistrict =
          (districts.isNotEmpty && districts.contains(city)) ? city : city;
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

// ── LocationSectionWidget ─────────────────────────────────────────────────────

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
  // One controller per editable level.
  final _regionCtl = TextEditingController();
  final _districtCtl = TextEditingController();
  final _wardCtl = TextEditingController();
  final _streetCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncControllersFromValue(widget.value);
  }

  @override
  void didUpdateWidget(LocationSectionWidget old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _syncControllersFromValue(widget.value);
    }
  }

  /// Push LocationValue into controllers without triggering onChanged.
  void _syncControllersFromValue(LocationValue v) {
    _set(_regionCtl, v.region ?? '');
    _set(_districtCtl, v.district ?? '');
    _set(_wardCtl, v.ward ?? '');
    _set(_streetCtl, v.street ?? '');
  }

  void _set(TextEditingController ctl, String value) {
    if (ctl.text != value) ctl.text = value;
  }

  @override
  void dispose() {
    _regionCtl.dispose();
    _districtCtl.dispose();
    _wardCtl.dispose();
    _streetCtl.dispose();
    super.dispose();
  }

  // ── Change handlers ─────────────────────────────────────────

  void _onRegionChanged(String v) {
    _districtCtl.clear();
    _wardCtl.clear();
    _streetCtl.clear();
    widget.onChanged(LocationValue(region: v.trim().isEmpty ? null : v.trim()));
  }

  void _onDistrictChanged(String v) {
    _wardCtl.clear();
    _streetCtl.clear();
    widget.onChanged(widget.value.copyWith(
      district: v.trim().isEmpty ? null : v.trim(),
      clearWard: true,
      clearStreet: true,
    ));
  }

  void _onWardChanged(String v) {
    _streetCtl.clear();
    widget.onChanged(widget.value.copyWith(
      ward: v.trim().isEmpty ? null : v.trim(),
      clearStreet: true,
    ));
  }

  void _onStreetChanged(String v) {
    widget.onChanged(widget.value.copyWith(
      street: v.trim().isEmpty ? null : v.trim(),
    ));
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final v = widget.value;

    // Suggestions are only used for the picker icon; the field is always
    // editable regardless of whether suggestions are available.
    final regionSuggestions = TanzaniaLocations.regions;
    final districtSuggestions = v.region != null
        ? TanzaniaLocations.getDistricts(v.region!)
        : <String>[];
    final wardSuggestions = v.district != null
        ? TanzaniaLocations.getWards(v.district!)
        : <String>[];
    final streetSuggestions =
        v.ward != null ? TanzaniaLocations.getStreets(v.ward!) : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Country — always Tanzania, truly read-only
        _StaticField(
          label: 'Country',
          value: TanzaniaLocations.country,
          icon: Icons.public,
        ),
        const SizedBox(height: 16),

        // Region
        _ComboLevelField(
          controller: _regionCtl,
          label: 'Region',
          icon: Icons.map_outlined,
          suggestions: regionSuggestions,
          onChanged: _onRegionChanged,
        ),

        // District — visible once region has any text
        if ((v.region ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          _ComboLevelField(
            controller: _districtCtl,
            label: 'District / City',
            icon: Icons.location_city,
            suggestions: districtSuggestions,
            onChanged: _onDistrictChanged,
          ),
        ],

        // Ward — visible once district has any text
        if ((v.district ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          _ComboLevelField(
            controller: _wardCtl,
            label: 'Ward',
            icon: Icons.villa_outlined,
            suggestions: wardSuggestions,
            onChanged: _onWardChanged,
          ),
        ],

        // Street — visible once ward has any text
        if ((v.ward ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          _ComboLevelField(
            controller: _streetCtl,
            label: 'Street',
            icon: Icons.signpost_outlined,
            suggestions: streetSuggestions,
            onChanged: _onStreetChanged,
          ),
        ],
      ],
    );
  }
}

// ── _ComboLevelField ──────────────────────────────────────────────────────────
//
// A TextFormField that always accepts free-text input.
// When [suggestions] is non-empty a dropdown-arrow suffix opens the
// searchable bottom-sheet picker.  A clear (×) suffix is shown whenever
// the field is non-empty.

class _ComboLevelField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;

  const _ComboLevelField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.suggestions,
    required this.onChanged,
  });

  @override
  State<_ComboLevelField> createState() => _ComboLevelFieldState();
}

class _ComboLevelFieldState extends State<_ComboLevelField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _openPicker() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SearchablePicker(
        label: widget.label,
        items: widget.suggestions,
        selected: widget.controller.text.isEmpty ? null : widget.controller.text,
      ),
    );
    if (picked != null && mounted) {
      widget.controller.text = picked;
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    final hasSuggestions = widget.suggestions.isNotEmpty;

    return TextFormField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(widget.icon),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clear button — shown when field has content
            if (hasText)
              GestureDetector(
                onTap: () {
                  widget.controller.clear();
                  widget.onChanged('');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.clear, size: 18),
                ),
              ),
            // Picker button — shown when static suggestions are available
            if (hasSuggestions)
              GestureDetector(
                onTap: _openPicker,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8, left: 4),
                  child: Icon(Icons.arrow_drop_down),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── _StaticField ──────────────────────────────────────────────────────────────

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

// ── _SearchablePicker ─────────────────────────────────────────────────────────

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
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
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
                      padding: EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
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