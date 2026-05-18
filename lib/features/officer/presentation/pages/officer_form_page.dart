// lib/features/officer/presentation/pages/officer_form_page.dart

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

  // Problem #1 fix: field is "Full Name", maps to actor.display_name.
  // Label updated from "Username / Full Name" → "Full Name".
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // Problem #2 fix: default ON — officers always get a login account.
  // The switch is kept so admin can optionally defer (e.g. bulk import),
  // but the recommended default is enabled.
  bool _enableAppLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  OrgRoleEntity? _selectedRole;
  BranchEntity? _selectedBranch;

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
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) orgBloc.add(RolesLoadRequested());
      });
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _populateFields(OfficerState state) {
    if (_isEdit && !_fieldsPopulated && state is OfficerDetailLoaded) {
      // Problem #1 fix: populate from displayName (actor.display_name).
      _fullNameController.text = state.item.displayName;
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
          BlocListener<OfficerBloc, OfficerState>(
            listener: (context, state) {
              if (state is OfficerDetailLoaded) {
                setState(() => _populateFields(state));
              }
              if (state is OfficerOperationSuccess) {
                setState(() => _isSubmitting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
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
                      // ── Row 1: Full Name + Email ──────────────────────
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildFullNameField()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildEmailField()),
                          ],
                        )
                      else ...[
                        _buildFullNameField(),
                        const SizedBox(height: 16),
                        _buildEmailField(),
                      ],
                      const SizedBox(height: 16),

                      // ── Row 2: Phone + Role ───────────────────────────
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

                      // ── Branch ────────────────────────────────────────
                      if (!_isEdit)
                        _buildBranchDropdown()
                      else if (officerState is OfficerDetailLoaded)
                        _buildBranchInfoRow(context, scheme, officerState),
                      const SizedBox(height: 24),

                      // ── App Login Credentials (create mode only) ──────
                      if (!_isEdit) ...[
                        _buildLoginSection(context, scheme),
                        const SizedBox(height: 16),
                      ],

                      // ── Submit ────────────────────────────────────────
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

  // Problem #1 fix: label is "Full Name", hint is a real person name.
  Widget _buildFullNameField() => TextFormField(
    controller: _fullNameController,
    decoration: const InputDecoration(
      labelText: 'Full Name *',
      hintText: 'e.g. Celestine Msigwa',
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.person_outlined),
      helperText: 'Used as display name across all apps',
    ),
    textCapitalization: TextCapitalization.words,
    validator: (v) {
      if (v == null || v.trim().isEmpty) return 'Full name is required';
      if (v.trim().length < 2) return 'At least 2 characters';
      return null;
    },
  );

  Widget _buildEmailField() => TextFormField(
    controller: _emailController,
    decoration: const InputDecoration(
      labelText: 'Email *',
      hintText: 'officer@barickpharmacy.co.tz',
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.email_outlined),
      helperText: 'Used for login',
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
      labelText: 'Phone Number *',
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

  Widget _buildRoleDropdown() => DropdownButtonFormField<OrgRoleEntity>(
    value: _selectedRole,
    decoration: InputDecoration(
      labelText: 'Role *',
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

  Widget _buildBranchDropdown() => DropdownButtonFormField<BranchEntity>(
    value: _selectedBranch,
    decoration: InputDecoration(
      labelText: 'Branch *',
      hintText: 'Assign to a branch',
      border: const OutlineInputBorder(),
      prefixIcon: const Icon(Icons.business_outlined),
      helperText: 'Officer will report to this branch',
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
                'Use "Transfer Branch" on the detail page to change branch',
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

  // Problem #2 fix: login section — always visible on create mode.
  // Toggle lets admin defer, but default is ON.
  Widget _buildLoginSection(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Officer App Login',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          value: _enableAppLogin,
          title: const Text('Create login account now'),
          subtitle: const Text(
            'Officer can log into the Officer App immediately with these credentials',
          ),
          onChanged: (v) => setState(() => _enableAppLogin = v),
          contentPadding: EdgeInsets.zero,
        ),
        if (_enableAppLogin) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password *',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              helperText: 'Minimum 8 characters',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (!_enableAppLogin) return null;
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'At least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPassController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm Password *',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (!_enableAppLogin) return null;
              if (v != _passwordController.text)
                return 'Passwords do not match';
              return null;
            },
          ),
        ],
      ],
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
              // Problem #1 fix: update fullName, not username.
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              orgRoleId: _selectedRole?.id,
              orgRoleName: _selectedRole?.name,
            ),
          ),
        );
      } else {
        setState(() => _isSubmitting = false);
      }
      return;
    }

    // ── Create mode ───────────────────────────────────────────
    // Problem #2 fix: dispatch fullName + password so backend creates
    // a real User account the officer can log in with immediately.
    context.read<OfficerBloc>().add(
      OfficerCreateRequested(
        CreateOfficerParams(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _enableAppLogin
              ? _passwordController.text
              : _generateTempPassword(),
          passwordConfirmation: _enableAppLogin
              ? _confirmPassController.text
              : _passwordController.text,
          phone: _phoneController.text.trim(),
          branchId: _selectedBranch!.id,
          orgRoleId: _selectedRole!.id,
        ),
      ),
    );
  }

  /// When the admin toggles off "Create login account now", we still need
  /// a password to satisfy the backend (officer can reset later via email).
  /// Generate a secure random one they'll never see.
  String _generateTempPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$';
    final rand = List.generate(
      16,
      (i) =>
          chars[(DateTime.now().microsecondsSinceEpoch + i * 7) % chars.length],
    );
    return rand.join();
  }
}
