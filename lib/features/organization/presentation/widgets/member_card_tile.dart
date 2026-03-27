import 'package:flutter/material.dart';
import '../../domain/entities/org_member_entity.dart';

class MemberCardTile extends StatelessWidget {
  final OrgMemberEntity member;
  final void Function(String userId)? onSuspend;
  final void Function(String userId)? onActivate;
  final void Function(String userId)? onRemove;
  const MemberCardTile({super.key, required this.member, this.onSuspend, this.onActivate, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = switch (member.status) { MemberStatus.active => Colors.green, MemberStatus.suspended => Colors.red, _ => Colors.orange };
    return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      CircleAvatar(radius: 20, backgroundColor: scheme.primaryContainer,
        child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?', style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(member.email, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(
            color: scheme.primaryContainer, borderRadius: BorderRadius.circular(6)),
            child: Text(member.roleName, style: TextStyle(fontSize: 10, color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600))),
          const SizedBox(width: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(member.status.name, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600))),
          const SizedBox(width: 6),
          Text('Lvl ${member.authorityLevel}', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
        ]),
      ])),
      PopupMenuButton<String>(
        onSelected: (v) { switch(v) {
          case 'suspend': onSuspend?.call(member.userId); break;
          case 'activate': onActivate?.call(member.userId); break;
          case 'remove': onRemove?.call(member.userId); break;
        }},
        itemBuilder: (_) => [
          if (member.isActive) const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
          if (member.isSuspended) const PopupMenuItem(value: 'activate', child: Text('Activate')),
          const PopupMenuItem(value: 'remove', child: Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    ])));
  }
}
