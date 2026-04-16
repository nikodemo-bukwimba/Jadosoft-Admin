// member_card_tile.dart
import 'package:flutter/material.dart';
import '../../domain/entities/org_member_entity.dart';

class MemberCardTile extends StatelessWidget {
  final OrgMemberEntity member;
  final void Function(String userId)? onSuspend;
  final void Function(String userId)? onActivate;
  final void Function(String userId)? onRemove;
  final void Function(OrgMemberEntity member)? onManageAccount;

  const MemberCardTile({
    super.key,
    required this.member,
    this.onSuspend,
    this.onActivate,
    this.onRemove,
    this.onManageAccount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = switch (member.status) {
      MemberStatus.active => Colors.green,
      MemberStatus.suspended => Colors.red,
      _ => Colors.orange,
    };
    final roleIcon = switch (member.roleCategory) {
      'owner' => Icons.star_rounded,
      'manager' => Icons.manage_accounts_rounded,
      'officer' => Icons.badge_rounded,
      _ => Icons.person_rounded,
    };
    final roleColor = switch (member.roleCategory) {
      'owner' => Colors.amber.shade700,
      'manager' => scheme.primary,
      'officer' => Colors.teal,
      _ => scheme.onSurfaceVariant,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────
            CircleAvatar(
              radius: 22,
              backgroundColor: roleColor.withOpacity(0.15),
              child: Icon(roleIcon, color: roleColor, size: 22),
            ),
            const SizedBox(width: 12),

            // ── Info ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    member.name.isNotEmpty ? member.name : member.email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  // Email
                  Text(
                    member.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Chips row
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      // Role chip
                      _Chip(
                        label: member.roleName,
                        color: roleColor,
                        icon: roleIcon,
                      ),
                      // Branch chip (show if branch name available)
                      if (member.orgName != null && member.orgName!.isNotEmpty)
                        _Chip(
                          label: member.orgName!,
                          color: Colors.blueGrey,
                          icon: Icons.store_outlined,
                        ),
                      // Status chip
                      _Chip(
                        label: member.status.name,
                        color: statusColor,
                        icon: switch (member.status) {
                          MemberStatus.active => Icons.check_circle_outline,
                          MemberStatus.suspended => Icons.pause_circle_outline,
                          _ => Icons.mail_outline,
                        },
                      ),
                      // Level chip
                      _Chip(
                        label: 'L${member.authorityLevel}',
                        color: scheme.onSurfaceVariant,
                        icon: Icons.trending_up,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Actions menu ─────────────────────────────────
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
              onSelected: (v) => switch (v) {
                'suspend' => onSuspend?.call(member.userId),
                'activate' => onActivate?.call(member.userId),
                'remove' => onRemove?.call(member.userId),
                'manage' => onManageAccount?.call(member),
                _ => null,
              },
              itemBuilder: (_) => [
                // Manage account — always available
                const PopupMenuItem(
                  value: 'manage',
                  child: Row(
                    children: [
                      Icon(Icons.manage_accounts, size: 18),
                      SizedBox(width: 10),
                      Text('Manage Account'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                if (member.isActive)
                  const PopupMenuItem(
                    value: 'suspend',
                    child: Row(
                      children: [
                        Icon(
                          Icons.pause_circle_outline,
                          size: 18,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 10),
                        Text('Suspend'),
                      ],
                    ),
                  ),
                if (member.isSuspended)
                  const PopupMenuItem(
                    value: 'activate',
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: Colors.green,
                        ),
                        SizedBox(width: 10),
                        Text('Activate'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_remove_outlined,
                        size: 18,
                        color: Colors.red,
                      ),
                      SizedBox(width: 10),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Chip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
