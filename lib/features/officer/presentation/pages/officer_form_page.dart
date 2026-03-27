// officer_form_page.dart
// ─────────────────────────────────────────────────────────────
// Changes from original:
//   • Branch dropdown added (replaces TODO_BRANCH_ID hardcode).
//   • _BranchOption holds id + display name for the dropdown.
//   • Branch is required on create; hidden on edit (reassign
//     is a separate operation via OfficerReassignBranchRequested).
//   • Responsive layout: branch dropdown sits beside role dropdown
//     on wide screens, stacked on narrow screens.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/officer_form_node.dart';
import '../bloc/officer_bloc.dart';
import '../bloc/officer_event.dart';
import '../bloc/officer_state.dart';
import '../../domain/usecases/create_officer_usecase.dart';

// ── Branch option ────────────────────────────────────────────
// TODO: Replace with data fetched from GET /orgs/{rootOrgId}/branches
// when that endpoint is available. Until then this mirrors the
// branches present in OfficerMockDataSource._store.
class _BranchOption {
  final String id;
  final String name;
  const _BranchOption(this.id, this.name);
}

class OfficerFormPage extends StatefulWidget {
  final OfficerFormNode mode;
  final String? id;
  const OfficerFormPage({super.key, this.mode = OfficerFormNode.create, this.id});
  @override
  State<OfficerFormPage> createState() => _OfficerFormPageState();
}

class _OfficerFormPageState extends State<OfficerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedRole;
  _BranchOption? _selectedBranch;

  // TODO: Replace with dynamic roles from GET /orgs/{orgId}/roles
  static const _roles = [
    'Senior Marketing Officer',
    'Marketing Officer',
    'Junior Marketing Officer',
  ];

  // TODO: Replace with GET /orgs/{rootOrgId}/branches
  static const _branches = [
    _BranchOption('branch-mbeya', 'Mbeya Branch'),
    _BranchOption('branch-dar', 'Dar es Salaam Branch'),
    _BranchOption('branch-dodoma', 'Dodoma Branch'),
    _BranchOption('branch-arusha', 'Arusha Branch'),
  ];

  bool _isSubmitting = false;
  bool _fieldsPopulated = false;
  bool get _isEdit => widget.mode == OfficerFormNode.edit;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _populateFields(OfficerState state) {
    if (_isEdit && !_fieldsPopulated && state is OfficerDetailLoaded) {
      _nameController.text = state.item.displayName;
      _emailController.text = state.item.email;
      _phoneController.text = state.item.phone ?? '';
      _selectedRole =
          _roles.contains(state.item.orgRoleName) ? state.item.orgRoleName : null;
      // On edit, branch is read-only (shown as info, not editable).
      // Use OfficerReassignBranchRequested for branch changes.
      _fieldsPopulated = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Officer' : 'New Officer')),
      body: BlocConsumer<OfficerBloc, OfficerState>(
        listener: (context, state) {
          if (state is OfficerDetailLoaded) {
            setState(() => _populateFields(state));
          }
          if (state is OfficerOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is OfficerFailure) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: scheme.error),
            );
          }
        },
        builder: (context, state) {
          if (_isEdit && state is OfficerLoading && !_fieldsPopulated) {
            return const Center(child: CircularProgressIndicator());
          }
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? MediaQuery.of(context).size.width * 0.1 : 16,
                vertical: 16,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Name / Email row ──────────────────────
                    if (isWide)
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: _buildNameField()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildEmailField()),
                      ])
                    else ...[
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildEmailField(),
                    ],
                    const SizedBox(height: 16),

                    // ── Phone / Role row ──────────────────────
                    if (isWide)
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: _buildPhoneField()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildRoleDropdown()),
                      ])
                    else ...[
                      _buildPhoneField(),
                      const SizedBox(height: 16),
                      _buildRoleDropdown(),
                    ],
                    const SizedBox(height: 16),

                    // ── Branch (create only) ──────────────────
                    if (!_isEdit) _buildBranchDropdown(),

                    // ── Branch info row (edit only) ───────────
                    if (_isEdit && state is OfficerDetailLoaded)
                      _buildBranchInfoRow(context, scheme, state),

                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_isEdit ? Icons.save : Icons.person_add),
                      label: Text(_isEdit ? 'Save Changes' : 'Create Officer'),
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

  // ── Field builders ────────────────────────────────────────

  Widget _buildNameField() => TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Username / Full Name',
          hintText: 'e.g. celestine.msigwa',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person_outlined),
        ),
        textCapitalization: TextCapitalization.words,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Name is required';
          if (v.trim().length < 2) return 'At least 2 characters';
          return null;
        },
      );

  Widget _buildEmailField() => TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(
          labelText: 'Email',
          hintText: 'officer@barickpharmacy.co.tz',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.email_outlined),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Email is required';
          if (!v.contains('@')) return 'Enter a valid email';
          return null;
        },
      );

  Widget _buildPhoneField() => TextFormField(
        controller: _phoneController,
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          hintText: '+255 7XX XXX XXX',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.phone_outlined),
        ),
        keyboardType: TextInputType.phone,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Phone is required';
          return null;
        },
      );

  Widget _buildRoleDropdown() => DropdownButtonFormField<String>(
        value: _selectedRole,
        decoration: const InputDecoration(
          labelText: 'Role',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.badge_outlined),
        ),
        items: _roles
            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
            .toList(),
        onChanged: (v) => setState(() => _selectedRole = v),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Role is required';
          return null;
        },
      );

  Widget _buildBranchDropdown() => DropdownButtonFormField<_BranchOption>(
        value: _selectedBranch,
        decoration: const InputDecoration(
          labelText: 'Branch',
          hintText: 'Assign to a branch',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.business_outlined),
          helperText: 'The officer will report to this branch admin/manager',
        ),
        items: _branches
            .map((b) => DropdownMenuItem(
                  value: b,
                  child: Text(b.name),
                ))
            .toList(),
        onChanged: (v) => setState(() => _selectedBranch = v),
        validator: (v) {
          if (v == null) return 'Branch is required';
          return null;
        },
      );

  Widget _buildBranchInfoRow(
      BuildContext context, ColorScheme scheme, OfficerDetailLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Row(children: [
        Icon(Icons.business_outlined, color: scheme.onSurfaceVariant, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Branch',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            Text(
              state.item.branchName ?? state.item.branchId,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ]),
        ),
        Tooltip(
          message: 'Use "Reassign Branch" on the detail page to change branch',
          child: Icon(Icons.lock_outline, size: 16, color: scheme.outlineVariant),
        ),
      ]),
    );
  }

  // ── Submit ────────────────────────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    if (_isEdit) {
      final currentState = context.read<OfficerBloc>().state;
      if (currentState is OfficerDetailLoaded) {
        context.read<OfficerBloc>().add(OfficerUpdateRequested(
          currentState.item.copyWith(
            username: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            orgRoleName: _selectedRole,
          ),
        ));
      }
    } else {
      context.read<OfficerBloc>().add(OfficerCreateRequested(CreateOfficerParams(
        email: _emailController.text.trim(),
        username: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        branchId: _selectedBranch!.id,
        orgRoleId: _selectedRole ?? '', // TODO: map role name → role ID from API
      )));
    }
  }
}