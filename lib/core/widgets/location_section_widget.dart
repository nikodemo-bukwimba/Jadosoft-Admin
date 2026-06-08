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
// Each level below Country is a TextFormField the user can type into
// directly.  When TanzaniaLocations has a list for that level a dropdown
// arrow icon is shown as a suffix; tapping it opens the searchable bottom-
// sheet picker and fills the text field with the chosen value.
// A clear (×) icon is shown whenever the field is non-empty.
//
// Cascade: changing a level clears all levels below it.
// Visibility: District shown once Region has any text, Ward once District
// has any text, Street once Ward has any text.
//
// FIX (blank-space): change handlers now pass the raw typed value to
// onChanged — trimming only happens when the value is committed (i.e.
// when the picker is used or the field loses focus).  This lets users
// type multi-word place names (e.g. "Dar es Salaam") without spaces
// being stripped mid-word.

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
  }) => LocationValue(
    country: country ?? this.country,
    region: region ?? this.region,
    district: clearDistrict ? null : (district ?? this.district),
    ward: clearWard ? null : (ward ?? this.ward),
    street: clearStreet ? null : (street ?? this.street),
  );

  /// Reconstruct from the flat city/county/ward/street strings stored in
  /// the API.  All four fields are accepted so edit-mode restoration works
  /// correctly with the full Tanzania hierarchy.
  factory LocationValue.fromApiFields({
    String? city,
    String? county,
    String? ward,
    String? street,
  }) {
    // county → region (kept even when not in static list — free-text case)
    final resolvedRegion = county?.isNotEmpty == true ? county : null;

    // city → district (kept even when not in static list — free-text case)
    final resolvedDistrict =
        (resolvedRegion != null && city?.isNotEmpty == true) ? city : null;

    // ward / street passed through directly
    final resolvedWard = ward?.isNotEmpty == true ? ward : null;
    final resolvedStreet = street?.isNotEmpty == true ? street : null;

    return LocationValue(
      region: resolvedRegion,
      district: resolvedDistrict,
      ward: resolvedWard,
      street: resolvedStreet,
    );
  }

  @override
  String toString() =>
      'LocationValue(region: $region, district: $district, '
      'ward: $ward, street: $street)';
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
  //
  // KEY FIX: pass the RAW typed string (not trimmed) to onChanged so
  // the user can type spaces between words.  We only convert an empty /
  // whitespace-only string to null so the cascade/visibility logic still
  // works correctly.  Trimming happens automatically when the picker is
  // used (picker always returns a clean string) and in _submit() on the
  // form page via .text.trim().

  void _onRegionChanged(String v) {
    _districtCtl.clear();
    _wardCtl.clear();
    _streetCtl.clear();
    widget.onChanged(LocationValue(region: v.isEmpty ? null : v));
  }

  void _onDistrictChanged(String v) {
    _wardCtl.clear();
    _streetCtl.clear();
    widget.onChanged(
      widget.value.copyWith(
        district: v.isEmpty ? null : v,
        clearWard: true,
        clearStreet: true,
      ),
    );
  }

  void _onWardChanged(String v) {
    _streetCtl.clear();
    widget.onChanged(
      widget.value.copyWith(ward: v.isEmpty ? null : v, clearStreet: true),
    );
  }

  void _onStreetChanged(String v) {
    widget.onChanged(widget.value.copyWith(street: v.isEmpty ? null : v));
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final v = widget.value;

    final regionSuggestions = TanzaniaLocations.regions;
    final districtSuggestions = v.region != null
        ? TanzaniaLocations.getDistricts(v.region!.trim())
        : <String>[];
    final wardSuggestions = v.district != null
        ? TanzaniaLocations.getWards(v.district!.trim())
        : <String>[];
    final streetSuggestions = v.ward != null
        ? TanzaniaLocations.getStreets(v.ward!.trim())
        : <String>[];

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
          onCommit: (v) => _onRegionChanged(v.trim()),
        ),

        // District — visible once region has any non-whitespace text
        if ((v.region ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _ComboLevelField(
            controller: _districtCtl,
            label: 'District / Council',
            icon: Icons.location_city,
            suggestions: districtSuggestions,
            onChanged: _onDistrictChanged,
            onCommit: (v) => _onDistrictChanged(v.trim()),
          ),
        ],

        // Ward — visible once district has any non-whitespace text
        if ((v.district ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _ComboLevelField(
            controller: _wardCtl,
            label: 'Ward',
            icon: Icons.villa_outlined,
            suggestions: wardSuggestions,
            onChanged: _onWardChanged,
            onCommit: (v) => _onWardChanged(v.trim()),
          ),
        ],

        // Street — visible once ward has any non-whitespace text
        if ((v.ward ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _ComboLevelField(
            controller: _streetCtl,
            label: 'Street',
            icon: Icons.signpost_outlined,
            suggestions: streetSuggestions,
            onChanged: _onStreetChanged,
            onCommit: (v) => _onStreetChanged(v.trim()),
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
//
// [onChanged] receives the raw value on every keystroke (spaces allowed).
// [onCommit]  receives the trimmed value on focus-loss and picker selection.

class _ComboLevelField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCommit;

  const _ComboLevelField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.suggestions,
    required this.onChanged,
    required this.onCommit,
  });

  @override
  State<_ComboLevelField> createState() => _ComboLevelFieldState();
}

class _ComboLevelFieldState extends State<_ComboLevelField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    _focusNode = FocusNode()
      ..addListener(() {
        // On focus loss, commit the trimmed value so the parent LocationValue
        // is tidy even when the user typed trailing spaces.
        if (!_focusNode.hasFocus) {
          widget.onCommit(widget.controller.text);
        }
      });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focusNode.dispose();
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
        selected: widget.controller.text.isEmpty
            ? null
            : widget.controller.text,
      ),
    );
    if (picked != null && mounted) {
      // Picker always provides a clean trimmed string — commit directly.
      widget.controller.text = picked;
      widget.onCommit(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    final hasSuggestions = widget.suggestions.isNotEmpty;

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      // Pass raw value so spaces are preserved while typing.
      onChanged: widget.onChanged,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(widget.icon),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          : widget.items.where((e) => e.toLowerCase().contains(q)).toList();
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
