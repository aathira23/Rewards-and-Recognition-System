import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../injection_container.dart';

/// HR Approvals & Allocation page — three tabs:
///  1. Award Approvals  (approve / reject nominations)
///  2. Conversion Requests  (approve / reject point conversions)
///  3. Budget Allocation  (allocate budget to managers)
class HrApprovalsPage extends StatefulWidget {
  const HrApprovalsPage({super.key});

  @override
  State<HrApprovalsPage> createState() => _HrApprovalsPageState();
}

class _HrApprovalsPageState extends State<HrApprovalsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Award nominations
  List<Map<String, dynamic>> _nominations = [];
  bool _nomLoading = true;

  // Conversion requests
  List<Map<String, dynamic>> _conversions = [];
  bool _convLoading = true;

  // Managers for budget allocation
  List<Map<String, dynamic>> _managers = [];
  bool _mgLoading = true;

  String _nomFilter = 'ALL'; // ALL, PENDING, APPROVED, REJECTED

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _loadNominations();
    _loadConversions();
    _loadManagers();
  }

  Future<void> _loadNominations() async {
    setState(() => _nomLoading = true);
    try {
      final client = sl<ApiClient>();
      final res = await client.get(ApiConstants.nominations);
      final data = res.data['data'] ?? [];
      setState(() {
        _nominations = (data is List) ? data.cast<Map<String, dynamic>>() : [];
        _nomLoading = false;
      });
    } catch (e) {
      setState(() {
        _nomLoading = false;
      });
    }
  }

  Future<void> _loadConversions() async {
    setState(() => _convLoading = true);
    try {
      final client = sl<ApiClient>();
      final res = await client.get(ApiConstants.pointsConversions);
      final data = res.data['data'] ?? [];
      setState(() {
        _conversions = (data is List) ? data.cast<Map<String, dynamic>>() : [];
        _convLoading = false;
      });
    } catch (e) {
      setState(() {
        _convLoading = false;
      });
    }
  }

  Future<void> _loadManagers() async {
    setState(() => _mgLoading = true);
    try {
      final client = sl<ApiClient>();
      final res = await client.get(ApiConstants.users);
      final data = res.data['data'] ?? res.data ?? [];
      final all = (data is List)
          ? data.cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      setState(() {
        _managers = all
            .where((u) =>
                (u['role']?.toString().toUpperCase() == 'MANAGER') ||
                (u['role']?.toString().toUpperCase() == 'DEPT_HEAD'))
            .toList();
        _mgLoading = false;
      });
    } catch (e) {
      setState(() {
        _mgLoading = false;
      });
    }
  }

  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainer,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Approvals & Allocation',
                          style: AppTextStyles.pageTitle()),
                      const SizedBox(height: 4),
                      Text(
                        'Review nominations, conversion requests & allocate budgets',
                        style: AppTextStyles.body(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                _RefreshBtn(onTap: _loadAll),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: theme.colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: AppTextStyles.bodyBold(),
                unselectedLabelStyle: AppTextStyles.bodyMedium(),
                dividerHeight: 0,
                tabs: [
                  _TabWithBadge(
                      label: 'Award Approvals',
                      count: _nominations
                          .where((n) =>
                              n['status'] == 'PENDING' &&
                              n['next_required_level']
                                      ?.toString()
                                      .toUpperCase() ==
                                  'HR')
                          .length),
                  _TabWithBadge(
                      label: 'Payroll Encashment',
                      count: _conversions
                          .where((c) => c['status'] == 'PENDING')
                          .length),
                  const Tab(text: 'Budget Allocation'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAwardApprovalsTab(theme),
                _buildConversionsTab(theme),
                _buildBudgetAllocationTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 1 — Award Approvals
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAwardApprovalsTab(ThemeData theme) {
    if (_nomLoading) return const Center(child: CircularProgressIndicator());

    final filtered = _nomFilter == 'ALL'
        ? _nominations
        : _nomFilter == 'PENDING'
            ? _nominations
                .where((n) =>
                    n['status'] == 'PENDING' &&
                    n['next_required_level']?.toString().toUpperCase() == 'HR')
                .toList()
            : _nominations.where((n) => n['status'] == _nomFilter).toList();

    final pendingCount = _nominations
        .where((n) =>
            n['status'] == 'PENDING' &&
            n['next_required_level']?.toString().toUpperCase() == 'HR')
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          Row(
            children: [
              _FilterChip(
                  label: 'All (${_nominations.length})',
                  isActive: _nomFilter == 'ALL',
                  onTap: () => setState(() => _nomFilter = 'ALL')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Pending ($pendingCount)',
                  isActive: _nomFilter == 'PENDING',
                  onTap: () => setState(() => _nomFilter = 'PENDING')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Approved',
                  isActive: _nomFilter == 'APPROVED',
                  onTap: () => setState(() => _nomFilter = 'APPROVED')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Rejected',
                  isActive: _nomFilter == 'REJECTED',
                  onTap: () => setState(() => _nomFilter = 'REJECTED')),
            ],
          ),
          const SizedBox(height: 16),

          if (filtered.isEmpty)
            _EmptyBlock(
                icon: Icons.inbox_rounded,
                text: 'No ${_nomFilter.toLowerCase()} nominations'),

          ...filtered.map((nom) => _buildNominationCard(nom, theme)),
        ],
      ),
    );
  }

  Widget _buildNominationCard(Map<String, dynamic> nom, ThemeData theme) {
    final status = nom['status']?.toString() ?? 'PENDING';
    final isPending = status == 'PENDING';
    // Only show action buttons when it is specifically HR's turn to act
    final isForHR = isPending &&
        nom['next_required_level']?.toString().toUpperCase() == 'HR';
    final nomineeName = nom['nominee']?['name'] ??
        nom['nominee_name'] ??
        'User #${nom['nominee_id']}';
    final nominatorName = nom['nominator']?['name'] ??
        nom['nominator_name'] ??
        'User #${nom['nominator_id']}';
    final awardType = nom['award_type']?['name'] ??
        nom['award_type_name'] ??
        'Award #${nom['award_type_id']}';
    final justification = nom['justification']?.toString() ?? '';
    final points = nom['points_awarded'] ?? nom['award_type']?['points'] ?? 0;
    final createdAt = nom['created_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isPending ? Colors.orange.shade100 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.emoji_events_rounded,
                    color: Colors.amber.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(awardType, style: AppTextStyles.cardTitle()),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        children: [
                          TextSpan(
                              text: nomineeName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const TextSpan(text: '  nominated by  '),
                          TextSpan(text: nominatorName),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _NomStatusBadge(nom: nom),
                  const SizedBox(height: 4),
                  Text('$points pts',
                      style: AppTextStyles.smallBold(
                          color: theme.colorScheme.primary)),
                ],
              ),
            ],
          ),
          if (justification.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(justification,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(_formatDate(createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              const Spacer(),
              if (isForHR) ...[
                OutlinedButton.icon(
                  onPressed: () => _showNomActionDialog(nom['id'], false),
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showNomActionDialog(nom['id'], true),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showNomActionDialog(int nominationId, bool isApprove) {
    final commentsC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: isApprove ? 'Approve Nomination' : 'Reject Nomination',
        maxWidth: 420,
        content: TextField(
          controller: commentsC,
          decoration: const InputDecoration(
            labelText: 'Comments (optional)',
            hintText: 'Add a note...',
          ),
          maxLines: 3,
        ),
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final client = sl<ApiClient>();
                await client.post(
                  '${ApiConstants.nominations}/$nominationId/action',
                  data: {
                    'action': isApprove ? 'APPROVE' : 'REJECT',
                    if (commentsC.text.isNotEmpty) 'comments': commentsC.text,
                  },
                );
                _loadNominations();
                _snack(
                    isApprove ? 'Nomination approved' : 'Nomination rejected');
              } catch (e) {
                _snack('Error: $e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 2 — Conversion Requests
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildConversionsTab(ThemeData theme) {
    if (_convLoading) return const Center(child: CircularProgressIndicator());

    final pending =
        _conversions.where((c) => c['status'] == 'PENDING').toList();
    final resolved =
        _conversions.where((c) => c['status'] != 'PENDING').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending section
          Row(
            children: [
              Text('Pending Requests', style: AppTextStyles.label()),
              const SizedBox(width: 8),
              if (pending.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${pending.length}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade700)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (pending.isEmpty)
            _EmptyBlock(
                icon: Icons.check_circle_outline,
                text: 'All caught up — no pending requests'),

          ...pending
              .map((c) => _buildConversionCard(c, theme, isPending: true)),

          if (resolved.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Resolved', style: AppTextStyles.label()),
            const SizedBox(height: 12),
            ...resolved
                .take(20)
                .map((c) => _buildConversionCard(c, theme, isPending: false)),
            if (resolved.length > 20)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    'Showing 20 of ${resolved.length} resolved requests',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversionCard(Map<String, dynamic> c, ThemeData theme,
      {required bool isPending}) {
    final id = c['id'] ?? 0;
    final userName = c['user_name'] ?? 'Unknown';
    final type = c['conversion_type'] ?? '';
    final points = c['points_converted'] ?? 0;
    final cash = c['cash_amount'] ?? 0;
    final status = c['status'] ?? 'PENDING';
    final date = c['requested_at']?.toString() ?? '';

    final isPayroll = type.toString().toUpperCase() == 'PAYROLL';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isPending ? Colors.orange.shade100 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isPayroll ? Colors.green : Colors.blue)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPayroll ? Icons.payments_rounded : Icons.volunteer_activism,
              color: isPayroll ? Colors.green : Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('$type  •  $points pts  →  \$${_fmtMoney(cash)}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(_formatDate(date),
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          if (isPending) ...[
            OutlinedButton(
              onPressed: () => _actionConversion(id, 'REJECT'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Reject'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _actionConversion(id, 'APPROVE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
          ] else
            _NomStatusBadge(nom: {'status': status}),
        ],
      ),
    );
  }

  Future<void> _actionConversion(int id, String action) async {
    try {
      final client = sl<ApiClient>();
      await client.post('${ApiConstants.pointsConversions}/$id/action',
          data: {'action': action});
      _loadConversions();
      _snack('Conversion ${action.toLowerCase()}d');
    } catch (e) {
      _snack('Error: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 3 — Budget Allocation
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBudgetAllocationTab(ThemeData theme) {
    if (_mgLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Allocate points to manager wallets. Only managers can reward employees from their budget.',
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Individual allocation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildIndividualAllocationCard(theme)),
              const SizedBox(width: 20),
              Expanded(child: _buildBulkAllocationCard(theme)),
            ],
          ),

          const SizedBox(height: 24),

          // Manager list
          Text('Managers', style: AppTextStyles.label()),
          const SizedBox(height: 4),
          Text('Select a manager below to quickly allocate budget',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 12),

          if (_managers.isEmpty)
            _EmptyBlock(icon: Icons.people_outline, text: 'No managers found'),

          if (_managers.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: _managers.asMap().entries.map((entry) {
                  final m = entry.value;
                  final isLast = entry.key == _managers.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Text(
                            (m['name']?.toString() ?? '?')[0].toUpperCase(),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['name']?.toString() ?? '',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                '${m['email'] ?? ''} • ${m['role'] ?? ''}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showQuickAllocateDialog(m),
                          icon: const Icon(Icons.add_rounded, size: 14),
                          label: const Text('Allocate'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildIndividualAllocationCard(ThemeData theme) {
    final managerIdC = TextEditingController();
    final pointsC = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_rounded,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Individual Allocation', style: AppTextStyles.cardTitle()),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: managerIdC,
            decoration: const InputDecoration(
              labelText: 'Manager User ID',
              hintText: 'Enter ID',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pointsC,
            decoration: const InputDecoration(
              labelText: 'Points to Allocate',
              hintText: 'e.g. 500',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final mId = int.tryParse(managerIdC.text);
                final pts = int.tryParse(pointsC.text);
                if (mId == null || pts == null || pts <= 0) {
                  _snack('Please enter valid values', isError: true);
                  return;
                }
                try {
                  final client = sl<ApiClient>();
                  await client.post(ApiConstants.managerAllocate,
                      data: {'manager_id': mId, 'points': pts});
                  managerIdC.clear();
                  pointsC.clear();
                  _snack('Allocated $pts points to manager');
                } catch (e) {
                  _snack('Error: $e', isError: true);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              child: const Text('Allocate Budget'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkAllocationCard(ThemeData theme) {
    final pointsC = TextEditingController();
    final deptIdC = TextEditingController();
    String? roleFilter;

    return StatefulBuilder(builder: (ctx, setLocalState) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Bulk Allocation', style: AppTextStyles.cardTitle()),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pointsC,
              decoration: const InputDecoration(
                labelText: 'Points per Manager',
                hintText: 'e.g. 1000',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deptIdC,
              decoration: const InputDecoration(
                labelText: 'Department ID (optional)',
                hintText: 'Filter by department',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: roleFilter,
              decoration: const InputDecoration(
                labelText: 'Role Filter',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Managers')),
                DropdownMenuItem(value: 'MANAGER', child: Text('Managers')),
                DropdownMenuItem(value: 'DEPT_HEAD', child: Text('Dept Heads')),
              ],
              onChanged: (v) => setLocalState(() => roleFilter = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final pts = int.tryParse(pointsC.text);
                  if (pts == null || pts <= 0) {
                    _snack('Enter valid points', isError: true);
                    return;
                  }
                  try {
                    final client = sl<ApiClient>();
                    final data = <String, dynamic>{'points': pts};
                    if (deptIdC.text.isNotEmpty) {
                      data['department_id'] = int.tryParse(deptIdC.text);
                    }
                    if (roleFilter != null) {
                      data['role_filter'] = roleFilter;
                    }
                    final res = await client
                        .post(ApiConstants.managerBulkAllocate, data: data);
                    final count = res.data['data']?['updated_wallets'] ?? 0;
                    pointsC.clear();
                    deptIdC.clear();
                    _snack('Allocated to $count wallets');
                  } catch (e) {
                    _snack('Error: $e', isError: true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('Bulk Allocate'),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showQuickAllocateDialog(Map<String, dynamic> manager) {
    final pointsC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Allocate to ${manager['name']}',
            style: AppTextStyles.sectionTitle()),
        content: SizedBox(
          width: 340,
          child: TextField(
            controller: pointsC,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Points',
              hintText: 'Enter amount to allocate',
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final pts = int.tryParse(pointsC.text);
              if (pts == null || pts <= 0) {
                _snack('Enter valid points', isError: true);
                return;
              }
              Navigator.of(ctx).pop();
              try {
                final client = sl<ApiClient>();
                await client.post(ApiConstants.managerAllocate,
                    data: {'manager_id': manager['id'], 'points': pts});
                _snack('Allocated $pts pts to ${manager['name']}');
              } catch (e) {
                _snack('Error: $e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Allocate'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────
  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
    }
  }

  String _fmtMoney(dynamic val) {
    final n = double.tryParse(val.toString()) ?? 0;
    return n.toStringAsFixed(2);
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ═════════════════════════════════════════════════════════════════════
//  Reusable private widgets
// ═════════════════════════════════════════════════════════════════════

class _RefreshBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _RefreshBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(Icons.refresh_rounded,
              size: 18, color: Colors.grey.shade500),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: isActive ? primary : Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border:
                Border.all(color: isActive ? primary : Colors.grey.shade200),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabWithBadge extends StatelessWidget {
  final String label;
  final int count;
  const _TabWithBadge({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade800)),
            ),
          ],
        ],
      ),
    );
  }
}

class _NomStatusBadge extends StatelessWidget {
  final Map<String, dynamic> nom;
  const _NomStatusBadge({required this.nom});

  @override
  Widget build(BuildContext context) {
    final status = nom['status']?.toString() ?? 'PENDING';
    final nextLevel = nom['next_required_level']?.toString().toUpperCase();

    Color color;
    String label = status;

    switch (status.toUpperCase()) {
      case 'APPROVED':
        color = Colors.green;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      case 'PENDING':
        color = Colors.orange;
        if (nextLevel == 'MANAGER')
          label = 'Pending Mgr';
        else if (nextLevel == 'DEPT_HEAD')
          label = 'Pending Head';
        else if (nextLevel == 'HR') label = 'Pending HR';
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyBlock({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(text,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
