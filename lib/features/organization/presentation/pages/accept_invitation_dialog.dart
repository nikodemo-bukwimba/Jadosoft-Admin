import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/organization_event.dart';


/// Shown alongside the Create Organization option when the user has no org.
/// Allows entering an invitation token from email to join an existing org.
class AcceptInvitationDialog {
  static void show(BuildContext context) {
    final tokenCtrl = TextEditingController();
    final bloc = context.read<OrganizationBloc>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Invitation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enter the invitation token you received via email to join an organization.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tokenCtrl,
              decoration: const InputDecoration(
                labelText: 'Invitation Token *',
                hintText: 'Paste your token here',
                prefixIcon: Icon(Icons.vpn_key_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              minLines: 1,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              final token = tokenCtrl.text.trim();
              if (token.isEmpty) return;
              Navigator.pop(ctx);
              bloc.add(InvitationAcceptRequested(token));
            },
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}