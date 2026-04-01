import 'package:rr_frontend/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import 'package:rr_frontend/core/presentation/widgets/main_layout.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../injection_container.dart';
import '../../../../core/utils/leveling_utils.dart';
import '../bloc/budget_bloc.dart';
import '../bloc/points_bloc.dart';
import '../bloc/points_event.dart';
import '../bloc/points_state.dart';
import '../bloc/budget_state.dart';
import '../bloc/budget_event.dart';
import 'package:rr_frontend/features/recognitions/presentation/bloc/recognitions_bloc.dart';
import 'package:rr_frontend/features/recognitions/presentation/bloc/recognitions_event.dart';
import 'package:rr_frontend/features/recognitions/presentation/bloc/recognitions_state.dart';
import '../../domain/entities/point_transaction_entity.dart';

class MyActivityPage extends StatefulWidget {
  final String userRole;
  const MyActivityPage({super.key, this.userRole = 'EMPLOYEE'});

  @override
  State<MyActivityPage> createState() => _MyActivityPageState();
}

class _MyActivityPageState extends State<MyActivityPage> {
  late PointsBloc _bloc;
  late RecognitionsBloc _recognitionsBloc;
  late BudgetBloc _budgetBloc;

  // History filters
  DateTime? _startDate;
  DateTime? _endDate;
  String? _category; // null = all, 'received', 'spent', 'pending', 'expired'
  int _page = 1;
  late String _walletType;
  static const _perPage = kDefaultPageSize;

  @override
  void initState() {
    super.initState();
    _bloc = sl<PointsBloc>();
    _recognitionsBloc = sl<RecognitionsBloc>();
    _budgetBloc = sl<BudgetBloc>();
    _walletType = 'EMPLOYEE'; // Personal by default
    _refreshAll();
  }

  @override
  void dispose() {
    _bloc.close();
    _recognitionsBloc.close();
    _budgetBloc.close();
    super.dispose();
  }

  void _refreshAll() {
    _fetchSummary();
    _fetchHistory(page: 1);
    _recognitionsBloc.add(GetAppreciationStatsRequested());
  }

  void _fetchSummary() {
    _bloc.add(GetPointsSummaryRequested());
  }

  void _fetchHistory({int page = 1}) {
    setState(() => _page = page);
    _bloc.add(GetPointsHistoryRequested(
      page: page,
      perPage: kDefaultPageSize,
      category: _category,
      startDate: AppDateFormatter.api(_startDate),
      endDate: AppDateFormatter.api(_endDate),
      walletType: _walletType,
    ));
  }

  void _toggleWallet(String type) {
    if (_walletType == type) return;
    setState(() {
      _walletType = type;
      _page = 1;
    });
    _refreshAll();

    if (type == 'MANAGER') {
      _budgetBloc.add(LoadBudgetWallet());
      _budgetBloc.add(LoadBudgetUsers());
      _budgetBloc.add(LoadCurrentUser());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _bloc),
        BlocProvider.value(value: _recognitionsBloc),
        BlocProvider.value(value: _budgetBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<BudgetBloc, BudgetState>(
            bloc: _budgetBloc,
            listener: (context, state) {
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.error!), backgroundColor: Colors.red),
                );
                _budgetBloc.add(ClearBudgetMessages());
              }
              if (state.successMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.successMessage!),
                      backgroundColor: Colors.green),
                );
                _budgetBloc.add(ClearBudgetMessages());
                _refreshAll();
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: BlocBuilder<PointsBloc, PointsState>(
            builder: (context, pointsState) {
              return BlocBuilder<RecognitionsBloc, RecognitionsState>(
                builder: (context, recognitionsState) {
                  if (pointsState.status == PointsStatus.loading &&
                      pointsState.summary == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _refreshAll(),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(Responsive.pagePadding(context)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPageHeader(),
                          const SizedBox(height: 24),
                          _buildMainBanner(pointsState, recognitionsState),
                          const SizedBox(height: 32),
                          _buildHistorySection(pointsState),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    final bool isManager = widget.userRole == 'MANAGER' ||
        widget.userRole == 'DEPT_HEAD' ||
        widget.userRole == 'HR' ||
        widget.userRole == 'ADMIN';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    final role = widget.userRole.toUpperCase();
                    final destination = (role == 'HR' || role == 'ADMIN')
                        ? 'Dashboard'
                        : 'Recognitions';
                    MainLayout.of(context)?.selectTabByTitle(destination);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back,
                            color: Color(0xFF64748B), size: 18),
                        const SizedBox(width: 8),
                        Text('Back to Dashboard',
                            style: AppTextStyles.body(
                                color: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ),
                Text('My Activity',
                    style: AppTextStyles.headline1(
                        color: const Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(
                  _walletType == 'EMPLOYEE'
                      ? 'Track your point earnings, redemptions, and conversions'
                      : 'Manage your team budget and track allocations',
                  style: AppTextStyles.body(color: const Color(0xFF64748B)),
                ),
              ],
            ),
            if (isManager) _buildTogglePill(),
          ],
        ),
      ],
    );
  }

  Widget _buildTogglePill() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleItem('EMPLOYEE', 'Personal'),
          _toggleItem('MANAGER', 'Budget'),
        ],
      ),
    );
  }

  Widget _toggleItem(String type, String label) {
    final bool active = _walletType == type;
    return GestureDetector(
      onTap: () => _toggleWallet(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.smallBold(
            color: active ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildMainBanner(
      PointsState pointsState, RecognitionsState recognitionsState) {
    final summary = pointsState.summary;
    if (summary == null) return const SizedBox.shrink();

    final isBudget = _walletType == 'MANAGER';

    // Personal data
    final totalPoints = summary.balance;
    final level = LevelingUtils.getLevel(totalPoints);
    final nextLevelPoints =
        LevelingUtils.getPointsToNextLevel(totalPoints) ?? 0;
    final nextThreshold = totalPoints + nextLevelPoints;

    return BlocBuilder<BudgetBloc, BudgetState>(
      bloc: _budgetBloc,
      builder: (context, budgetState) {
        final wallet = budgetState.wallet;
        final balance = wallet?.balance ?? 0;

        // Use real values from API if available; otherwise, default to 0 for rewarded
        // and treat the current balance as the total allocated (assuming 0 rewards so far).
        final allocated = wallet?.raw['total_allocated'] ?? balance;
        final rewarded = wallet?.raw['total_rewarded'] ?? 0;
        final double usageProgress =
            allocated > 0 ? (rewarded / allocated).clamp(0.0, 1.0) : 0.0;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.brandBlue,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.brandBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmall = constraints.maxWidth < 900;

              if (isSmall) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildBalancePart(isBudget, balance, totalPoints),
                    ),
                    Divider(
                        color: Colors.white.withValues(alpha: 0.15), height: 1),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: isBudget
                          ? _buildBudgetStatsRow(allocated, rewarded, balance)
                          : _buildStatsRow(summary, recognitionsState),
                    ),
                    Divider(
                        color: Colors.white.withValues(alpha: 0.15), height: 1),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildProgressPart(
                          isBudget,
                          level,
                          usageProgress,
                          rewarded,
                          allocated,
                          totalPoints,
                          nextThreshold,
                          balance),
                    ),
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── LEFT SECTION : Balance & Stats ────────────────────────
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
                            child: _buildBalancePart(
                                isBudget, balance, totalPoints),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Divider(
                                color: Colors.white.withValues(alpha: 0.15),
                                height: 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
                            child: isBudget
                                ? _buildBudgetStatsRow(
                                    allocated, rewarded, balance)
                                : _buildStatsRow(summary, recognitionsState),
                          ),
                        ],
                      ),
                    ),

                    // ── VERTICAL DIVIDER ──────────────────────────────────────
                    VerticalDivider(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                      indent: 20,
                      endIndent: 20,
                    ),

                    // ── RIGHT SECTION : Level / Usage Progress ────────────────
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildProgressPart(
                            isBudget,
                            level,
                            usageProgress,
                            rewarded,
                            allocated,
                            totalPoints,
                            nextThreshold,
                            balance),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBalancePart(bool isBudget, int balance, int totalPoints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isBudget ? 'Manager Balance' : 'Current Balance',
            style:
                AppTextStyles.body(color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
                isBudget
                    ? Icons.account_balance_wallet_rounded
                    : Icons.stars_rounded,
                color: const Color(0xFFFACC15),
                size: 36),
            const SizedBox(width: 12),
            Text(isBudget ? '$balance' : '$totalPoints',
                style: AppTextStyles.displayLarge(color: Colors.white)
                    .copyWith(fontSize: 40, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text('pts',
                  style: AppTextStyles.headline1(
                          color: Colors.white.withValues(alpha: 0.6))
                      .copyWith(fontSize: 18)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressPart(
      bool isBudget,
      int level,
      double usageProgress,
      int rewarded,
      int allocated,
      int totalPoints,
      int nextThreshold,
      int balance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: isBudget
                    ? const Icon(Icons.show_chart_rounded,
                        color: Color(0xFF854D0E), size: 32)
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.shield,
                              color: Color(0xFF854D0E), size: 34),
                          Text('$level',
                              style:
                                  AppTextStyles.smallBold(color: Colors.white)
                                      .copyWith(fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isBudget ? 'Budget Usage' : 'Level $level',
                    style: AppTextStyles.headline1(color: Colors.white)
                        .copyWith(fontSize: 20)),
                Text(isBudget ? 'Activity tracking' : 'Keep going!',
                    style: AppTextStyles.small(
                        color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isBudget ? 'Usage' : 'Progress',
                style: AppTextStyles.smallBold(color: Colors.white)),
            Text(
                isBudget
                    ? '$rewarded / $allocated pts'
                    : '$totalPoints / $nextThreshold pts',
                style: AppTextStyles.small(
                    color: Colors.white.withValues(alpha: 0.7))),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: isBudget
                ? usageProgress
                : LevelingUtils.getProgress(totalPoints),
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFACC15)),
          ),
        ),
        if (isBudget) ...[
          const SizedBox(height: 24),
          _buildRewardActionSmall(balance),
        ],
      ],
    );
  }

  Widget _buildBudgetStatsRow(int allocated, int rewarded, int balance) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(
            Icons.add_chart_rounded, 'TOTAL ALLOCATED', '$allocated'),
        _buildStatItem(
            Icons.celebration_rounded, 'TOTAL REWARDED', '$rewarded'),
        _buildStatItem(Icons.account_balance_rounded, 'AVAILABLE', '$balance'),
      ],
    );
  }

  void _showZeroBalanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: 'Zero Balance',
        content: const Text(
            'Your manager wallet is empty. Please contact HR to request more points.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRewardDialog(BuildContext context) {
    final state = _budgetBloc.state;

    if (state.users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No team members found to reward.')),
      );
      return;
    }

    int? selectedUserId;
    final TextEditingController pointsController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          title: 'Reward Employee',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Select Employee'),
                items: state.users
                    .map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.name),
                        ))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedUserId = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(
                    labelText: 'Points Amount', suffixText: 'pts'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedUserId == null ||
                    pointsController.text.isEmpty ||
                    reasonController.text.isEmpty) {
                  return;
                }
                final points = int.tryParse(pointsController.text) ?? 0;
                if (points <= 0) return;

                _budgetBloc.add(RewardFromBudget(
                  employeeId: selectedUserId!,
                  points: points,
                  reason: reasonController.text,
                ));
                Navigator.pop(context);
                _refreshAll();
              },
              child: const Text('Send Reward'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardActionSmall(int balance) {
    return ElevatedButton(
      onPressed: () {
        if (balance == 0) {
          _showZeroBalanceDialog(context);
        } else {
          _showRewardDialog(context);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        elevation: 0,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: 18),
          SizedBox(width: 8),
          Text('Reward Employee'),
        ],
      ),
    );
  }

  Widget _buildStatsRow(dynamic summary, RecognitionsState recognitionsState) {
    final expiringSoon =
        (summary.expiringToday ?? 0) + (summary.expiringThisMonth ?? 0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(
            Icons.north_east_rounded, 'TOTAL EARNED', '${summary.totalEarned}'),
        _buildStatItem(
            Icons.south_west_rounded, 'REDEEMED', '${summary.totalRedeemed}'),
        _buildStatItem(Icons.history_rounded, 'CONVERTED',
            '${summary.totalConverted ?? 0}'),
        _buildStatItem(Icons.timer_outlined, 'EXPIRING SOON', '$expiringSoon'),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.captionStrong(
                        color: Colors.white.withValues(alpha: 0.7))
                    .copyWith(fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        Text(value,
            style: AppTextStyles.headline1(color: Colors.white)
                .copyWith(fontSize: 24)),
      ],
    );
  }

  // ─── History section ────────────────────────────────────────────
  Widget _buildHistorySection(PointsState state) {
    final String historyTitle = _walletType == 'EMPLOYEE'
        ? 'Transaction History'
        : 'Budget Usage History';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterBar(historyTitle),
          _buildTableHeader(),
          if (state.status == PointsStatus.loading && state.history.isEmpty)
            const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()))
          else if (state.history.isEmpty)
            const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                    child: EmptyStateView(
                        icon: Icons.history_rounded,
                        title: 'No transactions found')))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.history.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 24, endIndent: 24),
              itemBuilder: (ctx, idx) => _buildRow(state.history[idx]),
            ),
          _buildFooter(state),
        ],
      ),
    );
  }

  Widget _buildFilterBar(String title) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.sectionTitle()),
          const Spacer(),
          _DateChip(
            label: _startDate != null
                ? AppDateFormatter.short(_startDate)
                : 'Start Date',
            isSet: _startDate != null,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) {
                setState(() => _startDate = d);
                _fetchHistory();
              }
            },
          ),
          const SizedBox(width: 12),
          _DateChip(
            label: _endDate != null
                ? AppDateFormatter.short(_endDate)
                : 'End Date',
            isSet: _endDate != null,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _endDate ?? DateTime.now(),
                firstDate: _startDate ?? DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) {
                setState(() => _endDate = d);
                _fetchHistory();
              }
            },
          ),
          const SizedBox(width: 12),
          _TypeDropdown(
            value: _category,
            onChanged: (v) {
              setState(() => _category = v);
              _fetchHistory();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _hdr('DATE')),
          Expanded(flex: 4, child: _hdr('DESCRIPTION')),
          Expanded(flex: 2, child: _hdr('STATUS')),
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.centerRight, child: _hdr('POINTS'))),
        ],
      ),
    );
  }

  Widget _hdr(String label) => Text(label,
      style: AppTextStyles.captionStrong(color: const Color(0xFF64748B)));

  Widget _buildRow(PointTransactionEntity tx) {
    final bool isPositive = tx.points.startsWith('+');

    return InkWell(
      onTap: () => _showTransactionDetails(tx),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                AppDateFormatter.format(tx.date),
                style: AppTextStyles.body(color: const Color(0xFF64748B)),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                tx.description,
                style: AppTextStyles.bodyBold(color: const Color(0xFF1E293B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tx.type,
                    style: AppTextStyles.captionBold(
                            color: const Color(0xFF475569))
                        .copyWith(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  tx.points,
                  style: AppTextStyles.bodyBold(
                      color: isPositive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(PointsState state) {
    final total = state.historyTotal;
    final start = (_page - 1) * _perPage + 1;
    final end = (_page * _perPage) > total ? total : (_page * _perPage);

    final hasNext = total > (_page * _perPage);
    final hasPrev = _page > 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Text(
            total == 0 ? 'No records' : 'Showing $start-$end of $total records',
            style: AppTextStyles.small(color: const Color(0xFF64748B)),
          ),
          const Spacer(),
          if (total > _perPage) ...[
            _navBtn(Icons.chevron_left, hasPrev,
                () => _fetchHistory(page: _page - 1)),
            const SizedBox(width: 8),
            _navBtn(Icons.chevron_right, hasNext,
                () => _fetchHistory(page: _page + 1)),
          ],
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 20,
            color: enabled ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
      ),
    );
  }

  void _showTransactionDetails(PointTransactionEntity tx) {
    final isCredit = tx.points.startsWith('+');
    final ptColor =
        isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Transaction Details',
        maxWidth: 460,
        showCloseButton: false,
        content: Column(
          children: [
            // Header with amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: ptColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ptColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tx.points,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: ptColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Points',
                    style: AppTextStyles.bodyBold(
                        color: ptColor.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details list
            _detailRow('Description', tx.description, isLarge: true),
            _detailRow('Status', tx.type, isBadge: true),
            _detailRow('Date', tx.date),
            if (tx.createdAtFull != null)
              _detailRow(
                  'Time', AppDateFormatter.formatTime(tx.createdAtFull!)),
            _detailRow(
                'Reference', tx.referenceType?.toUpperCase() ?? 'GENERAL'),
            _detailRow('Transaction ID', tx.id.toString()),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {bool isBadge = false, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment:
            isLarge ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.body(color: const Color(0xFF94A3B8)),
            ),
          ),
          Expanded(
            child: isBadge
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(status: value),
                  )
                : Text(
                    value,
                    style: isLarge
                        ? AppTextStyles.bodyBold(color: const Color(0xFF1E293B))
                        : AppTextStyles.bodyMedium(
                            color: const Color(0xFF1E293B)),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool isSet;
  final VoidCallback onTap;
  const _DateChip(
      {required this.label, required this.isSet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.small(color: const Color(0xFF475569))),
          ],
        ),
      ),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _TypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String?>(
        value: value,
        underline: const SizedBox(),
        hint: Text('All Types',
            style: AppTextStyles.small(color: const Color(0xFF475569))),
        items: const [
          DropdownMenuItem(value: null, child: Text('All Types')),
          DropdownMenuItem(value: 'received', child: Text('Earned')),
          DropdownMenuItem(value: 'spent', child: Text('Redeemed')),
          DropdownMenuItem(value: 'pending', child: Text('Pending')),
          DropdownMenuItem(value: 'expired', child: Text('Expired')),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
