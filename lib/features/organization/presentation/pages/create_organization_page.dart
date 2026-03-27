import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/organization_event.dart';
import '../bloc/organization_state.dart';

/// Shown when the user has no organization yet.
/// After creating, the org goes to "pending" status until platform admin approves.
class CreateOrganizationPage extends StatefulWidget {
  const CreateOrganizationPage({super.key});
  @override
  State<CreateOrganizationPage> createState() => _CreateOrganizationPageState();
}

class _CreateOrganizationPageState extends State<CreateOrganizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _selectedType = 'company';
  bool _isSubmitting = false;

  static const _orgTypes = [
    ('company', 'Company', Icons.business),
    ('ngo', 'NGO', Icons.volunteer_activism),
    ('government', 'Government', Icons.account_balance),
    ('individual', 'Individual', Icons.person),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    context.read<OrganizationBloc>().add(OrgCreateRequested({
      'name': _nameCtrl.text.trim(),
      'type': _selectedType,
      if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      if (_websiteCtrl.text.trim().isNotEmpty) 'website': _websiteCtrl.text.trim(),
      if (_addressCtrl.text.trim().isNotEmpty) 'address': _addressCtrl.text.trim(),
    }));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Organization')),
      body: BlocListener<OrganizationBloc, OrganizationState>(
        listener: (c, s) {
          if (s is OrganizationFailure) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s.message), backgroundColor: scheme.error));
          }
          // OrgCreatedSuccess is handled by parent hub page
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ── Welcome header ────────────────────────────────
              Icon(Icons.business_outlined, size: 64, color: scheme.primary.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text('Create Your Organization', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Set up your organization to start managing branches, officers, customers, and marketing operations.',
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 6),
                    Text('Requires platform admin approval', style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Form ──────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Organization name
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Organization Name *',
                        hintText: 'e.g. Barick Pharmacy Ltd',
                        prefixIcon: Icon(Icons.business),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Organization name is required';
                        if (v.trim().length < 2) return 'Name must be at least 2 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Type selector
                    Text('Organization Type', style: tt.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _orgTypes.map((t) {
                        final selected = _selectedType == t.$1;
                        return ChoiceChip(
                          label: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(t.$3, size: 16, color: selected ? scheme.onPrimary : scheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(t.$2),
                          ]),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedType = t.$1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What does your organization do?',
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        hintText: '+255 xxx xxx xxx',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Website
                    TextFormField(
                      controller: _websiteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Website',
                        hintText: 'https://www.example.com',
                        prefixIcon: Icon(Icons.language),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'City, Region, Country',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 32),

                    // Submit
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: const Text('Submit for Approval'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
