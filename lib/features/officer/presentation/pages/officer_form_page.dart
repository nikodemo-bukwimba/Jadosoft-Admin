// officer_form_page.dart
// ─────────────────────────────────────────────────────────────
// Integration changes:
//   • _branches: replaced static list with live GET /orgs/{rootOrgId}/tree
//     via OrganizationBloc (BranchesLoadRequested).
//   • _roles: replaced static list with live GET /orgs/{orgId}/roles
//     via OrganizationBloc (RolesLoadRequested).
//   • orgRoleId is now the actual role.id (not role.name) sent to API.
//   • Both dropdowns show loading/error states gracefully.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../organization/domain/entities/branch_entity.dart';
import '../../../organization/domain/entities/org_role_entity.dart';
import '../../../organization/presentation/bloc/organization_bloc.dart';
import '../../../organization/presentation/bloc/organization_event.dart';
import '../../../organization/presentation/bloc/organization_state.dart';
import '../enums/officer_form_node.dart';
import '../bloc/officer_bloc.dart';
import '../bloc/officer_event.dart';
import '../bloc/officer_state.dart';
import '../../domain/usecases/create_officer_usecase.dart';

class OfficerFormPage extends StatefulWidget {
  final OfficerFormNode mode;
  final String? id;
  const OfficerFormPage({
    super.key,
    this.mode = OfficerFormNode.create,
    this.id,
  });

  @override
  State<OfficerFormPage> createState() => _OfficerFormPageState();
}

class _OfficerFormPageState extends State<OfficerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  OrgRoleEntity? _selectedRole;
  BranchEntity? _selectedBranch;

  // ── Local cache — persists across org state changes ───────
  List<BranchEntity> _branches = [];
  List<OrgRoleEntity> _roles = [];
  bool _branchesLoaded = false;
  bool _rolesLoaded = false;

  bool _isSubmitting = false;
  bool _fieldsPopulated = false;
  bool get _isEdit => widget.mode == OfficerFormNode.edit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orgBloc = context.read<OrganizationBloc>();
      orgBloc.add(BranchesLoadRequested());
      // Small delay so branches response arrives before roles overwrites loading state
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) orgBloc.add(RolesLoadRequested());
      });
    });
  }

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
      try {
        _selectedRole = _roles.firstWhere((r) => r.id == state.item.orgRoleId);
      } catch (_) {
        _selectedRole = null;
      }
      _fieldsPopulated = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Officer' : 'New Officer')),
      body: MultiBlocListener(
        listeners: [
          // ── Cache branches when they arrive ──────────────
          BlocListener<OrganizationBloc, OrganizationState>(
            listener: (context, state) {
              if (state is BranchesLoaded) {
                setState(() {
                  _branches = state.branches;
                  _branchesLoaded = true;
                });
              }
              if (state is RolesLoaded) {
                setState(() {
                  _roles = state.roles;
                  _rolesLoaded = true;
                });
              }
            },
          ),
          // ── Officer bloc listener ────────────────────────
          BlocListener<OfficerBloc, OfficerState>(
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
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: scheme.error,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<OfficerBloc, OfficerState>(
          builder: (context, officerState) {
            if (_isEdit &&
                officerState is OfficerLoading &&
                !_fieldsPopulated) {
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
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildNameField()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildEmailField()),
                          ],
                        )
                      else ...[
                        _buildNameField(),
                        const SizedBox(height: 16),
                        _buildEmailField(),
                      ],
                      const SizedBox(height: 16),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildPhoneField()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildRoleDropdown()),
                          ],
                        )
                      else ...[
                        _buildPhoneField(),
                        const SizedBox(height: 16),
                        _buildRoleDropdown(),
                      ],
                      const SizedBox(height: 16),
                      if (!_isEdit) _buildBranchDropdown(),
                      if (_isEdit && officerState is OfficerDetailLoaded)
                        _buildBranchInfoRow(context, scheme, officerState),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(_isEdit ? Icons.save : Icons.person_add),
                        label: Text(
                          _isEdit ? 'Save Changes' : 'Create Officer',
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<OrgRoleEntity>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Role',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.badge_outlined),
        suffixIcon: !_rolesLoaded
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      items: _roles
          .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
          .toList(),
      onChanged: _rolesLoaded ? (v) => setState(() => _selectedRole = v) : null,
      validator: (v) => v == null ? 'Role is required' : null,
    );
  }

  Widget _buildBranchDropdown() {
    return DropdownButtonFormField<BranchEntity>(
      value: _selectedBranch,
      decoration: InputDecoration(
        labelText: 'Branch',
        hintText: 'Assign to a branch',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.business_outlined),
        helperText: 'The officer will report to this branch admin/manager',
        suffixIcon: !_branchesLoaded
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      items: _branches
          .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
          .toList(),
      onChanged: _branchesLoaded
          ? (v) => setState(() => _selectedBranch = v)
          : null,
      validator: (v) => v == null ? 'Branch is required' : null,
    );
  }

  Widget _buildBranchInfoRow(
    BuildContext context,
    ColorScheme scheme,
    OfficerDetailLoaded state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.business_outlined,
            color: scheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Branch',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  state.item.branchName ?? state.item.branchId,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Tooltip(
            message:
                'Use "Reassign Branch" on the detail page to change branch',
            child: Icon(
              Icons.lock_outline,
              size: 16,
              color: scheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Submit ────────────────────────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    if (_isEdit) {
      final currentState = context.read<OfficerBloc>().state;
      if (currentState is OfficerDetailLoaded) {
        context.read<OfficerBloc>().add(
          OfficerUpdateRequested(
            currentState.item.copyWith(
              username: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              orgRoleId: _selectedRole?.id,
              orgRoleName: _selectedRole?.name,
            ),
          ),
        );
      }
    } else {
      context.read<OfficerBloc>().add(
        OfficerCreateRequested(
          CreateOfficerParams(
            email: _emailController.text.trim(),
            username: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            branchId: _selectedBranch!.id,
            orgRoleId: _selectedRole!.id,
          ),
        ),
      );
    }
  }
}
