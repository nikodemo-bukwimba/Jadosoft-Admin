// lib/features/organization/presentation/pages/organization_hub_page.dart
//
// FIX 1 — Invitation filter indicator stuck on "Pending"
// ─────────────────────────────────────────────────────────────────────
// Root cause:
//   The outer BlocConsumer.builder returned a *brand-new* loading Scaffold
//   every time OrganizationLoading was emitted — even for sub-tab loads
//   (InvitationsLoadRequested, MembersLoadRequested, etc.).
//   This destroyed and recreated the TabBarView on every filter tap, which
//   reset _InvitationsBodyState._statusFilter back to 'pending'.
//
// Fix:
//   Add `_orgLoaded` bool to the State.  Once the active hub has been shown
//   at least once, OrganizationLoading/OrganizationInitial no longer replace
//   the hub Scaffold with a bare spinner.  The individual tab BlocBuilders
//   (which already check for OrganizationLoading) show their own local
//   spinners — which is the correct, intended behaviour.
//
//   `_orgLoaded` is reset to false when an org-level transition occurs
//   (NoOrg, pending, rejected, suspended) so the initial-load screen still
//   appears correctly on first open or after a hard reset.
// ─────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/organization_event.dart';
import '../bloc/organization_state.dart';
import '../pages/branch_tab.dart';
import '../pages/role_tab.dart';
import '../pages/member_tab.dart';
import '../pages/invitations_tab.dart';
import '../pages/delegation_tab.dart';
import '../pages/permission_request_tab.dart';
import '../pages/create_organization_page.dart';
import 'accept_invitation_dialog.dart';
import '../widgets/org_header_card.dart';
import '../../domain/entities/organization_entity.dart';

class OrganizationHubPage extends StatefulWidget {
  const OrganizationHubPage({super.key});
  @override
  State<OrganizationHubPage> createState() => _OrganizationHubPageState();
}

class _OrganizationHubPageState extends State<OrganizationHubPage>
    with TickerProviderStateMixin {
  TabController? _tabController;
  String? _viewingBranchMembers;
  bool _skipNextMemberLoad = false;

  // ── FIX: track whether the active hub scaffold has been rendered ───
  // Once true, OrganizationLoading no longer tears down the TabBarView.
  // Each individual tab handles its own per-tab loading indicator.
  bool _orgLoaded = false;

  static const _tabs = [
    Tab(icon: Icon(Icons.account_tree_outlined), text: 'Branches'),
    Tab(icon: Icon(Icons.admin_panel_settings_outlined), text: 'Roles'),
    Tab(icon: Icon(Icons.people_outlined), text: 'Members'),
    Tab(icon: Icon(Icons.mail_outlined), text: 'Invitations'),
    Tab(icon: Icon(Icons.swap_horiz_outlined), text: 'Delegations'),
    Tab(icon: Icon(Icons.lock_open_outlined), text: 'Requests'),
  ];

  static const int _kBranches = 0;
  static const int _kRoles = 1;
  static const int _kMembers = 2;
  static const int _kInvitations = 3;
  static const int _kDelegations = 4;
  static const int _kRequests = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController!.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController == null || !_tabController!.indexIsChanging) return;
    final bloc = context.read<OrganizationBloc>();
    switch (_tabController!.index) {
      case _kBranches:
        bloc.add(BranchesLoadRequested());
      case _kRoles:
        bloc.add(RolesLoadRequested());
      case _kMembers:
        if (_skipNextMemberLoad) {
          _skipNextMemberLoad = false;
          return;
        }
        _viewingBranchMembers = null;
        bloc.add(MembersLoadRequested());
      case _kInvitations:
        bloc.add(InvitationsLoadRequested());
      case _kDelegations:
        bloc.add(DelegationsLoadRequested());
      case _kRequests:
        bloc.add(PermissionRequestsLoadRequested());
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<Widget> _appBarActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.mail_outlined),
      tooltip: 'Accept Invitation',
      onPressed: () => AcceptInvitationDialog.show(context),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocConsumer<OrganizationBloc, OrganizationState>(
      listener: (c, s) {
        if (s is OrganizationOperationSuccess) {
          ScaffoldMessenger.of(
            c,
          ).showSnackBar(SnackBar(content: Text(s.message)));
          if (_tabController?.index == _kMembers) {
            c.read<OrganizationBloc>().add(
              MembersLoadRequested(orgId: _viewingBranchMembers),
            );
          }
          c.read<OrganizationBloc>().add(BranchesLoadRequested());
        }

        if (s is OrganizationFailure) {
          ScaffoldMessenger.of(c).showSnackBar(
            SnackBar(content: Text(s.message), backgroundColor: scheme.error),
          );
        }

        if (s is OrgCreatedSuccess) {
          ScaffoldMessenger.of(c).showSnackBar(
            const SnackBar(
              content: Text(
                'Organization created! Awaiting platform admin approval.',
              ),
            ),
          );
          c.read<OrganizationBloc>().add(OrgLoadRequested());
        }

        if (s is InvitationAccepted) {
          ScaffoldMessenger.of(c).showSnackBar(
            SnackBar(content: Text(s.message), backgroundColor: Colors.green),
          );
          c.read<OrganizationBloc>().add(OrgLoadRequested());
        }

        // ── Token sheet — handled here at hub level (stable Scaffold) ──
        if (s is MemberInvitedWithToken) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            InvitationTokenSheet.show(
              context,
              email: s.email,
              token: s.token,
              orgName: s.orgName,
            );
            context.read<OrganizationBloc>()
              ..add(MembersLoadRequested(orgId: _viewingBranchMembers))
              ..add(InvitationsLoadRequested());
          });
        }
      },

      // ── FIX: builder ────────────────────────────────────────────────
      // Once the active hub has been shown (_orgLoaded == true),
      // OrganizationLoading/OrganizationInitial must NOT replace the hub
      // with a bare-spinner Scaffold.  Sub-tab operations emit these states
      // and the per-tab BlocBuilders handle the local spinners themselves.
      builder: (c, s) {
        // ── Org-level states that need a dedicated top-level screen ───
        if (s is NoOrganizationState) {
          _orgLoaded = false;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Organization'),
              actions: _appBarActions(c),
            ),
            body: const CreateOrganizationPage(),
          );
        }

        if (s is OrgLoaded && s.org.isPending) {
          _orgLoaded = false;
          return _pendingApprovalView(c, s.org);
        }

        if (s is OrgLoaded && s.org.isRejected) {
          _orgLoaded = false;
          return _rejectedView(c, s.org);
        }

        if (s is OrgLoaded && s.org.isSuspended) {
          _orgLoaded = false;
          return _suspendedView(c, s.org);
        }

        // ── Initial loading — only show bare spinner before first load ─
        if ((s is OrganizationLoading || s is OrganizationInitial) &&
            !_orgLoaded) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Organization'),
              actions: _appBarActions(c),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // ── Active hub — any other state (including OrganizationLoading
        //   for sub-tab ops) keeps the hub alive so tab state is preserved.
        _orgLoaded = true;
        return _buildActiveHub(c, s);
      },
    );
  }

  Widget _buildActiveHub(BuildContext c, OrganizationState s) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization'),
        actions: _appBarActions(c),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
        ),
      ),
      body: Column(
        children: [
          BlocBuilder<OrganizationBloc, OrganizationState>(
            buildWhen: (_, s) => s is OrgLoaded,
            builder: (c, s) {
              if (s is OrgLoaded) return OrgHeaderCard(org: s.org);
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                BranchTab(
                  onSwitchToMembers: (branchId) {
                    _viewingBranchMembers = branchId;
                    _skipNextMemberLoad = true;
                    c.read<OrganizationBloc>().add(
                      MembersLoadRequested(orgId: branchId),
                    );
                    _tabController!.animateTo(_kMembers);
                  },
                ),
                const RoleTab(),
                MemberTab(
                  viewingBranchId: _viewingBranchMembers,
                  onBackToRootMembers: () {
                    setState(() => _viewingBranchMembers = null);
                    c.read<OrganizationBloc>().add(MembersLoadRequested());
                  },
                ),
                const InvitationsTab(),
                const DelegationTab(),
                const PermissionRequestTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingApprovalView(BuildContext c, OrganizationEntity org) {
    final scheme = Theme.of(c).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization'),
        actions: _appBarActions(c),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_top,
                size: 72,
                color: Colors.orange.withOpacity(0.6),
              ),
              const SizedBox(height: 24),
              Text(
                'Awaiting Approval',
                style: Theme.of(c).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your organization "${org.name}" has been submitted and is '
                'waiting for platform admin approval.',
                textAlign: TextAlign.center,
                style: Theme.of(c).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () =>
                    c.read<OrganizationBloc>().add(OrgLoadRequested()),
                icon: const Icon(Icons.refresh),
                label: const Text('Check Status'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rejectedView(BuildContext c, OrganizationEntity org) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization'),
        actions: _appBarActions(c),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cancel_outlined,
                size: 72,
                color: Colors.red.withOpacity(0.6),
              ),
              const SizedBox(height: 24),
              Text(
                'Organization Rejected',
                style: Theme.of(c).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              if (org.rejectionReason != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.red.withOpacity(0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(org.rejectionReason!)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () =>
                    c.read<OrganizationBloc>().add(OrgLoadRequested()),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suspendedView(BuildContext c, OrganizationEntity org) {
    final scheme = Theme.of(c).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization'),
        actions: _appBarActions(c),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, size: 72, color: scheme.error.withOpacity(0.6)),
              const SizedBox(height: 24),
              Text(
                'Organization Suspended',
                style: Theme.of(c).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.error,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your organization "${org.name}" has been suspended. '
                'Contact platform support.',
                textAlign: TextAlign.center,
                style: Theme.of(c).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () =>
                    c.read<OrganizationBloc>().add(OrgLoadRequested()),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
