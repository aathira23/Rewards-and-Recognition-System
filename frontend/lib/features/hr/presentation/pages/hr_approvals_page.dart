import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/presentation/widgets/main_layout.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/action_buttons.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/feature_flag_service.dart';
import '../bloc/hr_approvals_bloc.dart';
import '../bloc/hr_approvals_event.dart';
import '../bloc/hr_approvals_state.dart';

/// HR Allocations page — two tabs:
///  1. Conversion Requests  (approve / reject point conversions)
///  2. Budget Allocation  (allocate budget to managers)
class HrApprovalsPage extends StatelessWidget {
  const HrApprovalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HrApprovalsBloc>()
        ..add(LoadConversions())
        ..add(LoadManagers())
        ..add(LoadEmployees()),
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
    with TickerProviderStateMixin {
  TabController? _tabController;
  // null = still loading; true/false = flag resolved
  bool? _conversionEnabled;
  // Life Events tab — employee search
  String _empSearch = '';

  @override
  void initState() {
    super.initState();
    _loadFeatureFlags();
  }

  Future<void> _loadFeatureFlags() async {
    final enabled =
        await sl<FeatureFlagService>().isEnabled('conversion_enabled');
    if (!mounted) return;
    final oldController = _tabController;
    final newController = TabController(length: enabled ? 3 : 2, vsync: this);
    setState(() {
      _conversionEnabled = enabled;
      _tabController = newController;
    });
    if (oldController != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => oldController.dispose());
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  String _roleLabel(dynamic role) {
    if (role == null) return '';
    final r = role.toString().toUpperCase();
    switch (r) {
      case 'DEPT_HEAD':
        return 'Department Head';
      case 'MANAGER':
        return 'Manager';
      case 'HR':
        return 'Human Resources';
      case 'ADMIN':
        return 'Administrator';
      case 'EMPLOYEE':
        return 'Employee';
      default:
        final s = role.toString().replaceAll('_', ' ');
        return s
            .split(' ')
            .map((w) => w.isEmpty
                ? w
                : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
            .join(' ');
    }
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          MainLayout.of(context)?.selectTabByTitle('Dashboard'),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_rounded,
                                size: 20, color: Colors.black87),
                            const SizedBox(width: 8),
                            Text('Back to Dashboard',
                                style: AppTextStyles.bodyBold(
                                    color: Colors.black87)),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Allocations',
                                style: AppTextStyles.headline1(
                                    color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Review conversions & allocate budgets',
                                style: AppTextStyles.body(
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        _RefreshBtn(onTap: () {
                          context.read<HrApprovalsBloc>()
                            ..add(LoadConversions())
                            ..add(LoadManagers());
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Tabs — only render once the feature flag is resolved
              if (_tabController == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
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
                        if (_conversionEnabled == true)
                          _TabWithBadge(
                              label: 'Payroll Encashment',
                              count: state.conversions
                                  .where((c) => c['status'] == 'PENDING')
                                  .length),
                        const Tab(text: 'Budget Allocation'),
                        const Tab(text: 'Life Events'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Content
              if (_tabController != null)
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      if (_conversionEnabled == true)
                        _buildConversionsTab(context, theme, state),
                      _buildBudgetAllocationTab(context, theme, state),
                      _buildLifeEventsTab(context, theme, state),
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
            color: isPending ? Colors.indigo.shade100 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.swap_horiz_rounded,
                color: Colors.indigo.shade700, size: 20),
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
                    return DropdownMenu<String>(
                      initialSelection: selectedRole,
                      expandedInsets: EdgeInsets.zero,
                      inputDecorationTheme: InputDecorationTheme(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      label: const Text('Role filter (optional)'),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'MANAGER', label: 'Manager'),
                        DropdownMenuEntry(
                            value: 'DEPT_HEAD', label: 'Department Head'),
                      ],
                      onSelected: (v) => setLocal(() => selectedRole = v),
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
                Text('$email  ·  ${_roleLabel(role)}',
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
        maxWidth: 400,
        showCloseButton: false,
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

  // ═══════════════════════════════════════════════════════════════════
  //  TAB 4 — Life Events (Manual HR-triggered celebrations)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildLifeEventsTab(
      BuildContext context, ThemeData theme, HrApprovalsState state) {
    final filtered = state.employees.where((e) {
      if (_empSearch.isEmpty) return true;
      final name = (e['name'] ?? '').toString().toLowerCase();
      final email = (e['email'] ?? '').toString().toLowerCase();
      return name.contains(_empSearch) || email.contains(_empSearch);
    }).toList();

    return SingleChildScrollView(
      padding:
          EdgeInsets.symmetric(horizontal: Responsive.pagePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.celebration_rounded,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Life Event Celebrations',
                        style: AppTextStyles.cardTitle()),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Manually recognise an employee\'s personal milestone. '
                  'Select an employee below and choose the event type. '
                  'Points will be awarded immediately and the employee will be notified.',
                  style: AppTextStyles.bodyMedium()
                      .copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search field
          TextField(
            decoration: InputDecoration(
              hintText: 'Search employees…',
              prefixIcon: const Icon(Icons.search_rounded),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) =>
                setState(() => _empSearch = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 16),

          // Employee list
          if (state.empLoading)
            const Center(child: CircularProgressIndicator())
          else if (filtered.isEmpty)
            EmptyStateView(
              icon: Icons.people_outline,
              title: _empSearch.isEmpty
                  ? 'No employees found'
                  : 'No employees match "$_empSearch"',
            )
          else
            ...filtered.map(
              (emp) => _buildEmployeeLifeEventCard(context, emp, theme, state),
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeLifeEventCard(BuildContext context,
      Map<String, dynamic> emp, ThemeData theme, HrApprovalsState state) {
    final name = emp['name'] ?? 'Employee #${emp['id']}';
    final email = emp['email'] ?? '';
    final role = emp['role'] ?? '';
    final userId = emp['id'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyBold()),
                Text(email,
                    style: AppTextStyles.bodyMedium()
                        .copyWith(color: Colors.grey.shade600)),
                Text(_roleLabel(role),
                    style: AppTextStyles.small()
                        .copyWith(color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // New Baby button
          Tooltip(
            message: 'New Baby',
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade50,
                foregroundColor: Colors.pink.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 0,
                side: BorderSide(color: Colors.pink.shade200),
              ),
              icon: const Text('🍼', style: TextStyle(fontSize: 14)),
              label: const Text('New Baby',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              onPressed: state.lifeEventLoading
                  ? null
                  : () => _confirmLifeEvent(
                      context, userId, name, 'BIRTH', '🍼 New Baby'),
            ),
          ),
          const SizedBox(width: 8),
          // Marriage button
          Tooltip(
            message: 'Marriage',
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade50,
                foregroundColor: Colors.purple.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 0,
                side: BorderSide(color: Colors.purple.shade200),
              ),
              icon: const Text('💍', style: TextStyle(fontSize: 14)),
              label: const Text('Marriage',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              onPressed: state.lifeEventLoading
                  ? null
                  : () => _confirmLifeEvent(
                      context, userId, name, 'MARRIAGE', '💍 Marriage'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLifeEvent(BuildContext context, int userId, String userName,
      String type, String label) {
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Confirm $label Celebration',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to trigger a $label celebration for:',
              style: AppTextStyles.bodyMedium(),
            ),
            const SizedBox(height: 8),
            Text(userName, style: AppTextStyles.bodyBold()),
            const SizedBox(height: 12),
            Text(
              'This will award recognition points to the employee and '
              'post a congratulations message on the feed.',
              style: AppTextStyles.bodyMedium()
                  .copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<HrApprovalsBloc>()
                  .add(TriggerLifeEvent(userId: userId, celebrationType: type));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────
  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AppSnackbar.error(context, msg);
    } else {
      AppSnackbar.success(context, msg);
    }
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
      icon: const Icon(Icons.refresh_rounded, size: 20),
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

    final level = nextLevel.isEmpty ? 'Action' : nextLevel;
    final label = isPending ? 'Pending $level' : null;

    return StatusBadge(
      status: status,
      label: label,
    );
  }
}
