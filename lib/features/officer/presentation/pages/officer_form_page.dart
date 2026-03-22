import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/officer_form_node.dart';
import '../bloc/officer_bloc.dart';
import '../bloc/officer_event.dart';
import '../bloc/officer_state.dart';
import '../../domain/usecases/create_officer_usecase.dart';

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
  // TODO: Replace with dynamic roles from GET /orgs/{orgId}/roles
  static const _roles = ['Senior Marketing Officer', 'Marketing Officer', 'Junior Marketing Officer'];
  // TODO: Add branch dropdown populated from GET /orgs/{rootOrgId}/branches
  String _selectedBranchId = 'TODO_BRANCH_ID';

  bool _isSubmitting = false;
  bool _fieldsPopulated = false;
  bool get _isEdit => widget.mode == OfficerFormNode.edit;

  @override
  void dispose() { _nameController.dispose(); _emailController.dispose(); _phoneController.dispose(); super.dispose(); }

  void _populateFields(OfficerState state) {
    if (_isEdit && !_fieldsPopulated && state is OfficerDetailLoaded) {
      _nameController.text = state.item.displayName;
      _emailController.text = state.item.email;
      _phoneController.text = state.item.phone ?? '';
      _selectedRole = _roles.contains(state.item.orgRoleName) ? state.item.orgRoleName : null;
      _selectedBranchId = state.item.branchId;
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
          if (state is OfficerDetailLoaded) setState(() => _populateFields(state));
          if (state is OfficerOperationSuccess) { setState(() => _isSubmitting = false); Navigator.of(context).pop(true); }
          if (state is OfficerFailure) { setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: scheme.error)); }
        },
        builder: (context, state) {
          if (_isEdit && state is OfficerLoading && !_fieldsPopulated) return const Center(child: CircularProgressIndicator());
          return Form(key: _formKey, child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isWide ? MediaQuery.of(context).size.width * 0.1 : 16, vertical: 16),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (isWide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _buildNameField()), const SizedBox(width: 16), Expanded(child: _buildEmailField()),
                ]) else ...[ _buildNameField(), const SizedBox(height: 16), _buildEmailField() ],
                const SizedBox(height: 16),
                if (isWide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _buildPhoneField()), const SizedBox(width: 16), Expanded(child: _buildRoleDropdown()),
                ]) else ...[ _buildPhoneField(), const SizedBox(height: 16), _buildRoleDropdown() ],
                const SizedBox(height: 32),
                FilledButton.icon(onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_isEdit ? Icons.save : Icons.person_add),
                  label: Text(_isEdit ? 'Save Changes' : 'Create Officer')),
                const SizedBox(height: 32),
              ],
            )),
          ));
        },
      ),
    );
  }

  Widget _buildNameField() => TextFormField(controller: _nameController,
    decoration: const InputDecoration(labelText: 'Username / Full Name', hintText: 'e.g. celestine.msigwa',
      border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outlined)),
    textCapitalization: TextCapitalization.words,
    validator: (v) { if (v == null || v.trim().isEmpty) return 'Name is required'; if (v.trim().length < 2) return 'At least 2 characters'; return null; });

  Widget _buildEmailField() => TextFormField(controller: _emailController,
    decoration: const InputDecoration(labelText: 'Email', hintText: 'officer@barickpharmacy.co.tz',
      border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
    keyboardType: TextInputType.emailAddress,
    validator: (v) { if (v == null || v.trim().isEmpty) return 'Email is required'; if (!v.contains('@')) return 'Enter a valid email'; return null; });

  Widget _buildPhoneField() => TextFormField(controller: _phoneController,
    decoration: const InputDecoration(labelText: 'Phone Number', hintText: '+255 7XX XXX XXX',
      border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined)),
    keyboardType: TextInputType.phone,
    validator: (v) { if (v == null || v.trim().isEmpty) return 'Phone is required'; return null; });

  Widget _buildRoleDropdown() => DropdownButtonFormField<String>(
    value: _selectedRole,
    decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge_outlined)),
    items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
    onChanged: (v) => setState(() => _selectedRole = v),
    validator: (v) { if (v == null || v.isEmpty) return 'Role is required'; return null; });

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    if (_isEdit) {
      final currentState = context.read<OfficerBloc>().state;
      if (currentState is OfficerDetailLoaded) {
        context.read<OfficerBloc>().add(OfficerUpdateRequested(
          currentState.item.copyWith(username: _nameController.text.trim(), email: _emailController.text.trim(),
            phone: _phoneController.text.trim(), orgRoleName: _selectedRole)));
      }
    } else {
      context.read<OfficerBloc>().add(OfficerCreateRequested(CreateOfficerParams(
        email: _emailController.text.trim(), username: _nameController.text.trim(),
        phone: _phoneController.text.trim(), branchId: _selectedBranchId,
        orgRoleId: _selectedRole ?? '', // TODO: map role name to role ID from API
      )));
    }
  }
}
