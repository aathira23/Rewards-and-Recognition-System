import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/action_buttons.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../injection_container.dart';
import '../bloc/hr_approvals_bloc.dart';
import '../bloc/hr_approvals_event.dart';
import '../bloc/hr_approvals_state.dart';

/// HR Approvals & Allocation page — three tabs:
///  1. Award Approvals  (approve / reject nominations)
///  2. Conversion Requests  (approve / reject point conversions)
///  3. Budget Allocation  (allocate budget to managers)
class HrApprovalsPage extends StatelessWidget {
  const HrApprovalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HrApprovalsBloc>()
        ..add(LoadNominations())
        ..add(LoadConversions())
        ..add(LoadManagers()),
      child: const _HrApprovalsView(),
    );
  }
}

class _HrApprovalsView extends StatefulWidget {
  const _HrApprovalsView();

  @override
  State<_HrApprovalsView> createState() => _HrApprovalsViewState();
}

class _HrApprovalsViewState extends State<_HrApprovalsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _nomFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<HrApprovalsBloc, HrApprovalsState>(
      listener: (context, state) {
        if (state.error != null) _snack(state.error!, isError: true);
        if (state.successMessage != null) _snack(state.successMessage!);
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainer,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Responsive.pagePadding(context),
                  Responsive.pagePadding(context),
                  Responsive.pagePadding(context),
                  0,
                ),
                child: AppPageHeader(
                  action: _RefreshBtn(onTap: () {
                    context.read<HrApprovalsBloc>()
                      ..add(LoadNominations())
                      ..add(LoadConversions())
                      ..add(LoadManagers());
                  }),
                ),
              ),

              // Tabs
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.pagePadding(context),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: Responsive.isMobile(context),
                    tabAlignment: Responsive.isMobile(context)
                        ? TabAlignment.start
                        : TabAlignment.fill,
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
                          count: state.nominations
                              .where((n) =>
                                  n['status'] == 'PENDING' &&
                                  n['next_required_level']
                                          ?.toString()
                                          .toUpperCase() ==
                                      'HR')
                              .length),
                      _TabWithBadge(
                          label: 'Payroll Encashment',
                          count: state.conversions
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
                    _buildAwardApprovalsTab(context, theme, state),
                    _buildConversionsTab(context, theme, state),
                    _buildBudgetAllocationTab(context, theme, state),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 1 — Award Approvals
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAwardApprovalsTab(
      BuildContext context, ThemeData theme, HrApprovalsState state) {
    if (state.nomLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _nomFilter == 'ALL'
        ? state.nominations
        : _nomFilter == 'PENDING'
            ? state.nominations
                .where((n) =>
                    n['status'] == 'PENDING' &&
                    n['next_required_level']?.toString().toUpperCase() == 'HR')
                .toList()
            : state.nominations
                .where((n) => n['status'] == _nomFilter)
                .toList();

    final pendingCount = state.nominations
        .where((n) =>
            n['status'] == 'PENDING' &&
            n['next_required_level']?.toString().toUpperCase() == 'HR')
        .length;

    return SingleChildScrollView(
      padding:
          EdgeInsets.symmetric(horizontal: Responsive.pagePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                  label: 'All (${state.nominations.length})',
                  isActive: _nomFilter == 'ALL',
                  onTap: () => setState(() => _nomFilter = 'ALL')),
              _FilterChip(
                  label: 'Pending ($pendingCount)',
                  isActive: _nomFilter == 'PENDING',
                  onTap: () => setState(() => _nomFilter = 'PENDING')),
              _FilterChip(
                  label: 'Approved',
                  isActive: _nomFilter == 'APPROVED',
                  onTap: () => setState(() => _nomFilter = 'APPROVED')),
              _FilterChip(
                  label: 'Rejected',
                  isActive: _nomFilter == 'REJECTED',
                  onTap: () => setState(() => _nomFilter = 'REJECTED')),
            ],
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            EmptyStateView(
                icon: Icons.inbox_rounded,
                title: 'No ${_nomFilter.toLowerCase()} nominations'),
          ...filtered.map((nom) => _buildNominationCard(context, nom, theme)),
        ],
      ),
    );
  }

  Widget _buildNominationCard(
      BuildContext context, Map<String, dynamic> nom, ThemeData theme) {
    final status = nom['status']?.toString() ?? 'PENDING';
    final isPending = status == 'PENDING';
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
        color: theme.colorScheme.surface,
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
              Text(AppDateFormatter.format(createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              const Spacer(),
              if (isForHR) ...[
                RejectButton(
                  onPressed: () =>
                      _showNomActionDialog(context, nom['id'], false),
                ),
                const SizedBox(width: 8),
                ApproveButton(
                  onPressed: () =>
                      _showNomActionDialog(context, nom['id'], true),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showNomActionDialog(
      BuildContext context, int nominationId, bool isApprove) {
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
          isApprove
              ? ApproveButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.read<HrApprovalsBloc>().add(ActionNomination(
                          id: nominationId,
                          isApprove: isApprove,
                          comments:
                              commentsC.text.isNotEmpty ? commentsC.text : null,
                        ));
                  },
                )
              : RejectButton(
                  useFilledStyle: true,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.read<HrApprovalsBloc>().add(ActionNomination(
                          id: nominationId,
                          isApprove: isApprove,
                          comments:
                              commentsC.text.isNotEmpty ? commentsC.text : null,
                        ));
                  },
                ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 2 — Conversion Requests
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildConversionsTab(
      BuildContext context, ThemeData theme, HrApprovalsState state) {
    if (state.convLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.conversions.isEmpty) {
      return const EmptyStateView(
          icon: Icons.swap_horiz_rounded, title: 'No conversion requests');
    }
    return SingleChildScrollView(
      padding:
          EdgeInsets.symmetric(horizontal: Responsive.pagePadding(context)),
      child: Column(
        children: state.conversions
            .map((c) => _buildConversionCard(context, c, theme))
            .toList(),
      ),
    );
  }

  Widget _buildConversionCard(
      BuildContext context, Map<String, dynamic> c, ThemeData theme) {
    final status = c['status']?.toString() ?? 'PENDING';
    final isPending = status == 'PENDING';
    final userName = c['user_name']?.toString() ?? 'User #${c['user_id']}';
    final points = c['points_converted'] ?? 0;
    final amount = c['cash_amount'] ?? 0;
    final createdAt = c['requested_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isPending ? Colors.blue.shade100 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.swap_horiz_rounded,
                color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: AppTextStyles.cardTitle()),
                const SizedBox(height: 4),
                Text('$points pts → ₹$amount',
                    style: AppTextStyles.bodyBold(
                        color: theme.colorScheme.primary)),
                const SizedBox(height: 4),
                Text(AppDateFormatter.format(createdAt),
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          if (isPending) ...[
            RejectButton(
              isCompact: true,
              onPressed: () => context
                  .read<HrApprovalsBloc>()
                  .add(ActionConversion(id: c['id'], action: 'reject')),
            ),
            const SizedBox(width: 4),
            ApproveButton(
              isCompact: true,
              onPressed: () => context
                  .read<HrApprovalsBloc>()
                  .add(ActionConversion(id: c['id'], action: 'approve')),
            ),
          ] else
            StatusBadge(status: status),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 3 — Budget Allocation
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBudgetAllocationTab(
      BuildContext context, ThemeData theme, HrApprovalsState state) {
    return SingleChildScrollView(
      padding:
          EdgeInsets.symmetric(horizontal: Responsive.pagePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBulkAllocationCard(context, theme),
          const SizedBox(height: 20),
          Text('Manager Wallets', style: AppTextStyles.cardTitle()),
          const SizedBox(height: 12),
          if (state.mgLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.managers.isEmpty)
            const EmptyStateView(
                icon: Icons.people_outline, title: 'No managers found')
          else
            ...state.managers.map((m) => _buildManagerCard(context, m, theme)),
        ],
      ),
    );
  }

  Widget _buildBulkAllocationCard(BuildContext context, ThemeData theme) {
    final pointsC = TextEditingController();
    String? selectedRole;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_add_rounded,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Bulk Budget Allocation', style: AppTextStyles.cardTitle()),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: pointsC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Points per manager',
                    prefixIcon: Icon(Icons.stars_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatefulBuilder(
                  builder: (ctx, setLocal) {
                    return DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role filter (optional)',
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'MANAGER', child: Text('Manager')),
                        DropdownMenuItem(
                            value: 'DEPT_HEAD', child: Text('Dept Head')),
                      ],
                      onChanged: (v) => setLocal(() => selectedRole = v),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                final pts = int.tryParse(pointsC.text.trim());
                if (pts == null || pts <= 0) {
                  _snack('Enter a valid point amount', isError: true);
                  return;
                }
                context.read<HrApprovalsBloc>().add(BulkAllocateBudgets(
                      points: pts,
                      roleFilter: selectedRole,
                    ));
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Allocate to All'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerCard(
      BuildContext context, Map<String, dynamic> m, ThemeData theme) {
    final name = m['name'] ?? 'Manager #${m['id']}';
    final email = m['email'] ?? '';
    final role = m['role'] ?? '';
    final walletBal = m['wallet']?['balance'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyBold()),
                Text('$email  ·  $role',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$walletBal pts',
                style:
                    AppTextStyles.smallBold(color: theme.colorScheme.primary)),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Allocate budget',
            icon: Icon(Icons.add_circle_outline,
                color: theme.colorScheme.primary),
            onPressed: () => _showAllocateDialog(context, m),
          ),
        ],
      ),
    );
  }

  void _showAllocateDialog(BuildContext context, Map<String, dynamic> manager) {
    final pointsC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Allocate Budget',
        maxWidth: 380,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manager: ${manager['name']}'),
            const SizedBox(height: 12),
            TextField(
              controller: pointsC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Points',
                prefixIcon: Icon(Icons.stars_rounded),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final pts = int.tryParse(pointsC.text.trim());
              if (pts == null || pts <= 0) return;
              Navigator.of(ctx).pop();
              context.read<HrApprovalsBloc>().add(AllocateBudgetToManager(
                    managerId: manager['id'],
                    points: pts,
                  ));
            },
            child: const Text('Allocate'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────
  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Private helper widgets
// ═══════════════════════════════════════════════════════════════════

class _RefreshBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _RefreshBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Refresh all',
      icon: const Icon(Icons.refresh_rounded),
      onPressed: onTap,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:
              isActive ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  isActive ? theme.colorScheme.primary : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.grey.shade600,
            )),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
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
    final isPending = status == 'PENDING';
    final nextLevel =
        nom['next_required_level']?.toString().toUpperCase() ?? '';

    String label;
    if (status == 'APPROVED') {
      label = 'Approved';
    } else if (status == 'REJECTED') {
      label = 'Rejected';
    } else if (isPending && nextLevel == 'HR') {
      label = 'Pending HR';
    } else {
      label = 'Pending $nextLevel';
    }

    return StatusBadge(
      status: status,
      label: label,
    );
  }
}
