// lib/core/widgets/location_section_widget.dart

import 'package:flutter/material.dart';
import '../data/tanzania_locations.dart';

// ── LocationValue ─────────────────────────────────────────────────────────────

class LocationValue {
  final String country;
  final String? region;
  final String? district;
  final String? ward;
  final String? street;

  String get effectiveCity => district ?? ward ?? '';
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

  factory LocationValue.fromApiFields({
    String? city,
    String? county,
    String? ward,
    String? street,
  }) {
    return LocationValue(
      region:   (county != null && county.isNotEmpty) ? county : null,
      district: (city   != null && city.isNotEmpty)   ? city   : null,
      ward:     (ward   != null && ward.isNotEmpty)   ? ward   : null,
      street:   (street != null && street.isNotEmpty) ? street : null,
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
  final _regionCtl   = TextEditingController();
  final _districtCtl = TextEditingController();
  final _wardCtl     = TextEditingController();
  final _streetCtl   = TextEditingController();

  // Track which fields are focused so we never overwrite them
  // from didUpdateWidget while the user is actively editing.
  final _regionFocus   = FocusNode();
  final _districtFocus = FocusNode();
  final _wardFocus     = FocusNode();
  final _streetFocus   = FocusNode();

  @override
  void initState() {
    super.initState();
    _syncControllersFromValue(widget.value);
  }

  @override
  void didUpdateWidget(LocationSectionWidget old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      // Only overwrite a controller when that field does NOT have focus.
      // While focused the controller IS the source of truth — the parent
      // value will catch up on commit (focus-loss / picker / × button).
      _setIfUnfocused(_regionCtl,   _regionFocus,   widget.value.region   ?? '');
      _setIfUnfocused(_districtCtl, _districtFocus, widget.value.district ?? '');
      _setIfUnfocused(_wardCtl,     _wardFocus,     widget.value.ward     ?? '');
      _setIfUnfocused(_streetCtl,   _streetFocus,   widget.value.street   ?? '');
    }
  }

  void _syncControllersFromValue(LocationValue v) {
    _regionCtl.text   = v.region   ?? '';
    _districtCtl.text = v.district ?? '';
    _wardCtl.text     = v.ward     ?? '';
    _streetCtl.text   = v.street   ?? '';
  }

  void _setIfUnfocused(TextEditingController ctl, FocusNode fn, String value) {
    if (!fn.hasFocus && ctl.text != value) {
      ctl.text = value;
    }
  }

  @override
  void dispose() {
    _regionCtl.dispose();
    _districtCtl.dispose();
    _wardCtl.dispose();
    _streetCtl.dispose();
    _regionFocus.dispose();
    _districtFocus.dispose();
    _wardFocus.dispose();
    _streetFocus.dispose();
    super.dispose();
  }

  // ── Change handlers ─────────────────────────────────────────
  // onChanged  → raw value, fires every keystroke (spaces allowed)
  // onCommit   → trimmed value, fires on focus-loss / picker / × button

  void _onRegionChanged(String v) {
    // Cascade: clear siblings immediately in the controllers so the
    // cascade fields vanish visually while the user is still typing.
    _districtCtl.clear();
    _wardCtl.clear();
    _streetCtl.clear();
    widget.onChanged(LocationValue(region: v.isEmpty ? null : v));
  }

  void _onRegionCommit(String v) {
    final t = v.trim();
    _districtCtl.clear();
    _wardCtl.clear();
    _streetCtl.clear();
    widget.onChanged(LocationValue(region: t.isEmpty ? null : t));
  }

  void _onDistrictChanged(String v) {
    _wardCtl.clear();
    _streetCtl.clear();
    widget.onChanged(widget.value.copyWith(
      district: v.isEmpty ? null : v,
      clearWard: true,
      clearStreet: true,
    ));
  }

  void _onDistrictCommit(String v) {
    final t = v.trim();
    _wardCtl.clear();
    _streetCtl.clear();
    widget.onChanged(widget.value.copyWith(
      district: t.isEmpty ? null : t,
      clearWard: true,
      clearStreet: true,
    ));
  }

  void _onWardChanged(String v) {
    _streetCtl.clear();
    widget.onChanged(widget.value.copyWith(
      ward: v.isEmpty ? null : v,
      clearStreet: true,
    ));
  }

  void _onWardCommit(String v) {
    final t = v.trim();
    _streetCtl.clear();
    widget.onChanged(widget.value.copyWith(
      ward: t.isEmpty ? null : t,
      clearStreet: true,
    ));
  }

  void _onStreetChanged(String v) {
    widget.onChanged(widget.value.copyWith(street: v.isEmpty ? null : v));
  }

  void _onStreetCommit(String v) {
    final t = v.trim();
    widget.onChanged(widget.value.copyWith(street: t.isEmpty ? null : t));
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final v = widget.value;

    final regionSuggestions   = TanzaniaLocations.regions;
    final districtSuggestions = v.region   != null ? TanzaniaLocations.getDistricts(v.region!.trim())   : <String>[];
    final wardSuggestions     = v.district != null ? TanzaniaLocations.getWards(v.district!.trim())     : <String>[];
    final streetSuggestions   = v.ward     != null ? TanzaniaLocations.getStreets(v.ward!.trim())       : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StaticField(label: 'Country', value: TanzaniaLocations.country, icon: Icons.public),
        const SizedBox(height: 16),

        _ComboLevelField(
          controller:  _regionCtl,
          focusNode:   _regionFocus,
          label:       'Region',
          icon:        Icons.map_outlined,
          suggestions: regionSuggestions,
          onChanged:   _onRegionChanged,
          onCommit:    _onRegionCommit,
        ),

        if ((v.region ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _ComboLevelField(
            controller:  _districtCtl,
            focusNode:   _districtFocus,
            label:       'District / Council',
            icon:        Icons.location_city,
            suggestions: districtSuggestions,
            onChanged:   _onDistrictChanged,
            onCommit:    _onDistrictCommit,
          ),
        ],

        if ((v.district ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _ComboLevelField(
            controller:  _wardCtl,
            focusNode:   _wardFocus,
            label:       'Ward',
            icon:        Icons.villa_outlined,
            suggestions: wardSuggestions,
            onChanged:   _onWardChanged,
            onCommit:    _onWardCommit,
          ),
        ],

        if ((v.ward ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _ComboLevelField(
            controller:  _streetCtl,
            focusNode:   _streetFocus,
            label:       'Street',
            icon:        Icons.signpost_outlined,
            suggestions: streetSuggestions,
            onChanged:   _onStreetChanged,
            onCommit:    _onStreetCommit,
          ),
        ],
      ],
    );
  }
}

// ── _ComboLevelField ──────────────────────────────────────────────────────────

class _ComboLevelField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCommit;

  const _ComboLevelField({
    required this.controller,
    required this.focusNode,
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
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    widget.focusNode.addListener(() {
      // Commit trimmed value on focus-loss.
      if (!widget.focusNode.hasFocus) {
        widget.onCommit(widget.controller.text);
      }
      // Rebuild so the × icon appears/disappears correctly.
      if (mounted) setState(() {});
    });
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
        label:    widget.label,
        items:    widget.suggestions,
        selected: widget.controller.text.isEmpty ? null : widget.controller.text,
      ),
    );
    if (picked != null && mounted) {
      widget.controller.text = picked;
      widget.onCommit(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText        = widget.controller.text.isNotEmpty;
    final hasSuggestions = widget.suggestions.isNotEmpty;

    return TextFormField(
      controller:         widget.controller,
      focusNode:          widget.focusNode,
      onChanged:          widget.onChanged,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText:  widget.label,
        border:     const OutlineInputBorder(),
        prefixIcon: Icon(widget.icon),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasText)
              GestureDetector(
                onTap: () {
                  widget.controller.clear();
                  widget.onCommit('');
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

  const _StaticField({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText:  label,
        border:     const OutlineInputBorder(),
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

  const _SearchablePicker({required this.label, required this.items, required this.selected});

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
    final maxH   = MediaQuery.of(context).size.height * 0.7;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtl,
                autofocus:  true,
                decoration: InputDecoration(
                  hintText:   'Search…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchCtl.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Text('No results found.', textAlign: TextAlign.center),
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