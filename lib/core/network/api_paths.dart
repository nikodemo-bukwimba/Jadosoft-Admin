// api_paths.dart
// ─────────────────────────────────────────────────────────────
// Single source of truth for ALL API endpoint paths.
//
// Organised by module matching the Nexora API documentation:
//   - Auth           (no org scope)
//   - Platform Admin  (no org scope — platform-wide)
//   - Org Management  (org-scoped)
//   - Pharma Vertical (org-scoped)
//   - Commerce        (org-scoped)
//   - Finance         (org-scoped)
//   - Communications  (mixed)
//   - Notifications   (user-scoped)
//   - Workflows       (mixed)
//
// Usage:
//   final path = ApiPaths.pharma.customers(orgId);
//   _dio.get(path);
// ─────────────────────────────────────────────────────────────

class ApiPaths {
  ApiPaths._();

  static const auth = _AuthPaths();
  static const admin = _AdminPaths();
  static const orgs = _OrgPaths();
  static const pharma = _PharmaPaths();
  static const commerce = _CommercePaths();
  static const finance = _FinancePaths();
  static const communications = _CommunicationsPaths();
  static const notifications = _NotificationPaths();
  static const inventory = _InventoryPaths();
  static const workflows = _WorkflowPaths();
}

// ── Auth (no org scope) ─────────────────────────────────────

class _AuthPaths {
  const _AuthPaths();

  String get login => '/auth/login';
  String get logout => '/auth/logout';
  String get register => '/auth/register';
  String get me => '/auth/me';
  String get refreshToken => '/auth/refresh-token';
  String permissions(String orgId) => 'orgs/$orgId/permissions';
}

// ── Platform Admin (platform-wide, requires platform role) ──

class _AdminPaths {
  const _AdminPaths();

  // Staff
  String get staff => '/admin/staff';
  String staffRole(String userId, String roleName) =>
      '/admin/staff/$userId/$roleName';

  // Organizations
  String get orgsList => '/admin/orgs';
  String org(String id) => '/admin/orgs/$id';
  String approveOrg(String id) => '/admin/orgs/$id/approve';
  String rejectOrg(String id) => '/admin/orgs/$id/reject';
  String suspendOrg(String id) => '/admin/orgs/$id/suspend';
  String reactivateOrg(String id) => '/admin/orgs/$id/reactivate';

  // Users
  String get users => '/admin/users';
  String userStatus(String id) => '/admin/users/$id/status';

  // Audit
  String get audit => '/admin/audit';

  // Tiers & Flags
  String get tiers => '/admin/tiers';
  String get flags => '/admin/flags';
  String flag(String key) => '/admin/flags/$key';

  // Dashboard (needs to be built by API team)
  String get dashboard => '/admin/dashboard';
}

// ── Organization Management ─────────────────────────────────

class _OrgPaths {
  const _OrgPaths();

  String get create => 'orgs';
  String org(String id) => 'orgs/$id';
  String tree(String id) => 'orgs/$id/tree';
  String branches(String orgId) => 'orgs/$orgId/branches';
  String members(String orgId) => 'orgs/$orgId/members';
  String inviteMembers(String orgId) => 'orgs/$orgId/members/invite';
  String member(String orgId, String userId) => 'orgs/$orgId/members/$userId';
  String roles(String orgId) => 'orgs/$orgId/roles';
  String rolePermissions(String orgId, String roleId) =>
      'orgs/$orgId/roles/$roleId/permissions';
  String permissions(String orgId) => 'orgs/$orgId/permissions';
  String delegations(String orgId) => 'orgs/$orgId/delegations';
  String delegation(String orgId, String id) => 'orgs/$orgId/delegations/$id';
  String permissionRequests(String orgId) => 'orgs/$orgId/permission-requests';
  String approveRequest(String orgId, String id) =>
      'orgs/$orgId/permission-requests/$id/approve';
  String denyRequest(String orgId, String id) =>
      'orgs/$orgId/permission-requests/$id/deny';
}

// ── Pharma Marketing Vertical (all org-scoped) ─────────────

class _PharmaPaths {
  const _PharmaPaths();

  // Customers
  String customers(String orgId) => '/pharma/orgs/$orgId/customers';
  String customer(String id) => '/pharma/customers/$id';
  String customerContacts(String customerId) =>
      '/pharma/customers/$customerId/contacts';
  String contact(String id) => '/pharma/contacts/$id';

  // Visits
  String visits(String orgId) => '/pharma/orgs/$orgId/visits';
  String visit(String id) => '/pharma/visits/$id';
  String visitCheckIn(String orgId) => '/pharma/orgs/$orgId/visits/check-in';
  String visitCheckOut(String id) => '/pharma/visits/$id/check-out';
  String visitAttachments(String id) => '/pharma/visits/$id/attachments';
  // Admin review (needs to be built by API team)
  String visitReview(String id) => '/pharma/visits/$id/review';
  String visitFlag(String id) => '/pharma/visits/$id/flag';
  String visitUnflag(String id) => '/pharma/visits/$id/unflag';

  // Weekly Plans
  String plans(String orgId) => '/pharma/orgs/$orgId/plans';
  String plan(String id) => '/pharma/plans/$id';
  String planSubmit(String id) => '/pharma/plans/$id/submit';
  String planApprove(String id) => '/pharma/plans/$id/approve';
  String planReject(String id) => '/pharma/plans/$id/reject';
  String planItems(String id) => '/pharma/plans/$id/items';

  // Daily Reports
  String reports(String orgId) => '/pharma/orgs/$orgId/reports';
  String get reportToday => '/pharma/reports/today';
  String report(String id) => '/pharma/reports/$id';
  String reportSubmit(String id) => '/pharma/reports/$id/submit';
  String reportApprove(String id) => '/pharma/reports/$id/approve';
  String reportReject(String id) => '/pharma/reports/$id/reject';

  // Product Updates (maps to Promotions in the admin plan)
  String productUpdates(String orgId) => '/pharma/orgs/$orgId/product-updates';
  String productUpdate(String id) => '/pharma/product-updates/$id';
  String publishUpdate(String id) => '/pharma/product-updates/$id/publish';
  String updateStats(String id) => '/pharma/product-updates/$id/stats';

  // Officers (dedicated endpoints — needs to be built by API team)
  // In the meantime, officers are managed via org members + admin users
  String officers(String orgId) => '/pharma/orgs/$orgId/officers';
  String officer(String actorId) => '/pharma/officers/$actorId';

  // Dashboard (needs to be built by API team)
  String marketingDashboard(String orgId) =>
      '/pharma/orgs/$orgId/dashboard/marketing';
}

// ── Commerce (org-scoped) ───────────────────────────────────

class _CommercePaths {
  const _CommercePaths();

  // Products
  String products(String orgId) => '/commerce/orgs/$orgId/products';
  String product(String id) => '/commerce/products/$id';
  // Transition endpoints (may need API team to build)
  String publishProduct(String id) => '/commerce/products/$id/publish';
  String archiveProduct(String id) => '/commerce/products/$id/archive';

  // Categories (needs to be built by API team)
  String categories(String orgId) => '/commerce/orgs/$orgId/categories';
  String category(String id) => '/commerce/categories/$id';

  // Orders
  String orders(String orgId) => '/commerce/orgs/$orgId/orders';
  String order(String id) => '/commerce/orders/$id';
  String confirmOrder(String id) => '/commerce/orders/$id/confirm';
  String processingOrder(String id) => '/commerce/orders/$id/processing';
  String shipOrder(String id) => '/commerce/orders/$id/ship';
  String deliverOrder(String id) => '/commerce/orders/$id/deliver';
  String cancelOrder(String id) => '/commerce/orders/$id/cancel';

  // Basket
  String basket(String orgId) => '/commerce/orgs/$orgId/basket';

  // Dashboard (needs to be built by API team)
  String salesDashboard(String orgId) =>
      '/commerce/orgs/$orgId/dashboard/sales';
}

// ── Finance (org-scoped) ────────────────────────────────────

class _FinancePaths {
  const _FinancePaths();

  String subscriptions(String orgId) => '/finance/org-subscriptions/$orgId';
  // Payments (needs confirmation from API team on exact paths)
  String payments(String orgId) => '/finance/orgs/$orgId/payments';
  String payment(String id) => '/finance/payments/$id';
}

// ── Communications ──────────────────────────────────────────

class _CommunicationsPaths {
  const _CommunicationsPaths();

  String get conversations => '/communications/conversations';
  String conversation(String id) => '/communications/conversations/$id';
  String messages(String conversationId) =>
      '/communications/conversations/$conversationId/messages';
  String get broadcasts => '/communications/broadcasts';
  String get groups => '/communications/groups';
}

// ── Notifications (user-scoped for normal, admin for monitoring) ─

class _NotificationPaths {
  const _NotificationPaths();

  String get list => '/notifications';
  String single(String id) => '/notifications/$id';
  String markRead(String id) => '/notifications/$id/read';
  String get markAllRead => '/notifications/read-all';
  String get devices => '/notifications/devices';
  String get preferences => '/notifications/preferences';
  String preference(String type) => '/notifications/preferences/$type';

  // Admin-level (needs to be built by API team)
  String get adminList => '/admin/notifications';
  String adminRetry(String id) => '/admin/notifications/$id/retry';
}

// ── Inventory ───────────────────────────────────────────────

class _InventoryPaths {
  const _InventoryPaths();

  String warehouses(String orgId) => '/inventory/orgs/$orgId/warehouses';
  String warehouse(String id) => '/inventory/warehouses/$id';
  String receive(String warehouseId) =>
      '/inventory/warehouses/$warehouseId/receive';
  String batches(String orgId) => '/inventory/orgs/$orgId/batches';
  String batch(String id) => '/inventory/batches/$id';
  String alerts(String orgId) => '/inventory/orgs/$orgId/alerts';
}

// ── Workflows ───────────────────────────────────────────────

class _WorkflowPaths {
  const _WorkflowPaths();

  String get list => '/workflows';
  String single(String id) => '/workflows/$id';
  String runs(String id) => '/workflows/$id/runs';
  String run(String runId) => '/workflows/runs/$runId';
}

// ── Exports (needs to be built by API team) ─────────────────

class ExportPaths {
  ExportPaths._();

  static const String request = '/exports/request';
  static String status(String id) => '/exports/$id/status';
  static String download(String id) => '/exports/$id/download';
}
