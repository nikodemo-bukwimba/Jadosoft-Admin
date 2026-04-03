import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/organization_event.dart';
import '../bloc/organization_state.dart';
import 'branch_tab.dart';
import 'role_tab.dart';
import 'member_tab.dart';
import 'delegation_tab.dart';
import 'permission_request_tab.dart';
import 'create_organization_page.dart';
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

  /// Tracks if we're viewing members for a specific branch.
  /// null = root org, non-null = branch ID.
  String? _viewingBranchMembers;

  /// Prevents _onTabChanged from overwriting a branch-scoped member load
  /// when the tab switch is triggered programmatically from branch view.
  bool _skipNextMemberLoad = false;

  static const _tabs = [
    Tab(icon: Icon(Icons.account_tree_outlined), text: 'Branches'),
    Tab(icon: Icon(Icons.admin_panel_settings_outlined), text: 'Roles'),
    Tab(icon: Icon(Icons.people_outlined), text: 'Members'),
    Tab(icon: Icon(Icons.swap_horiz_outlined), text: 'Delegations'),
    Tab(icon: Icon(Icons.lock_open_outlined), text: 'Requests'),
  ];

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
      case 0:
        bloc.add(BranchesLoadRequested());
        break;
      case 1:
        bloc.add(RolesLoadRequested());
        break;
      case 2:
        // If switching to Members tab from branch view, skip reload
        if (_skipNextMemberLoad) {
          _skipNextMemberLoad = false;
          return;
        }
        // Normal tab switch — load root org members, clear branch context
        _viewingBranchMembers = null;
        bloc.add(MembersLoadRequested());
        break;
      case 3:
        bloc.add(DelegationsLoadRequested());
        break;
      case 4:
        bloc.add(PermissionRequestsLoadRequested());
        break;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<Widget> _appBarActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.mail_outlined),
        tooltip: 'Accept Invitation',
        onPressed: () => AcceptInvitationDialog.show(context),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocConsumer<OrganizationBloc, OrganizationState>(
      listener: (c, s) {
        if (s is OrganizationOperationSuccess) {
          ScaffoldMessenger.of(
            c,
          ).showSnackBar(SnackBar(content: Text(s.message)));
          if (_viewingBranchMembers != null) {
            c.read<OrganizationBloc>().add(
              MembersLoadRequested(orgId: _viewingBranchMembers),
            );
          } else {
            _onTabChanged();
          }
          // Always refresh branches so member counts update
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
        // Do NOT auto-switch to Members tab on MembersLoaded anymore.
        // The switch is handled by the branch callback directly.
      },
      builder: (c, s) {
        if (s is NoOrganizationState) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Organization'),
              actions: _appBarActions(c),
            ),
            body: const CreateOrganizationPage(),
          );
        }
        if (s is OrgLoaded && s.org.isPending)
          return _pendingApprovalView(c, s.org);
        if (s is OrgLoaded && s.org.isRejected) return _rejectedView(c, s.org);
        if (s is OrgLoaded && s.org.isSuspended)
          return _suspendedView(c, s.org);
        if (s is OrganizationLoading || s is OrganizationInitial) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Organization'),
              actions: _appBarActions(c),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
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
                    // Load branch-scoped members
                    _viewingBranchMembers = branchId;
                    _skipNextMemberLoad = true;
                    c.read<OrganizationBloc>().add(
                      MembersLoadRequested(orgId: branchId),
                    );
                    _tabController!.animateTo(2);
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
                'Your organization "${org.name}" has been submitted and is waiting for platform admin approval.',
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
              const SizedBox(height: 12),
              if (org.rejectionReason != null) ...[
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
                        Expanded(
                          child: Text(
                            org.rejectionReason!,
                            style: Theme.of(c).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Please contact platform support or create a new organization.',
                textAlign: TextAlign.center,
                style: Theme.of(c).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suspendedView(BuildContext c, OrganizationEntity org) {
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
                Icons.pause_circle_outline,
                size: 72,
                color: Colors.orange.withOpacity(0.6),
              ),
              const SizedBox(height: 24),
              Text(
                'Organization Suspended',
                style: Theme.of(c).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your organization "${org.name}" has been suspended by the platform admin. Please contact support.',
                textAlign: TextAlign.center,
                style: Theme.of(c).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
