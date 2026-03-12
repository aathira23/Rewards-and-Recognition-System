import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../injection_container.dart';
import '../bloc/nominations_bloc.dart';
import '../bloc/nominations_event.dart';
import '../bloc/nominations_state.dart';
import '../../../../core/widgets/action_buttons.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../widgets/nominate_employee_dialog.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/nomination_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/domain/entities/user_entity.dart';

/// Approvals page for Managers and Department Heads.
///
/// • Tab 1 – Pending: nominations waiting for THIS role to approve/reject
/// • Tab 2 – My Nominations: nominations the current user submitted
/// • Tab 3 – History: all visible nominations (approved + rejected)
class ManagerApprovalsPage extends StatelessWidget {
  const ManagerApprovalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NominationsBloc>()
        ..add(GetNominationsRequested())
        ..add(GetAwardTypesRequested())
        ..add(GetUsersRequested())
        ..add(GetApprovalHistoryRequested()),
      child: const _ManagerApprovalsView(),
    );
  }
}

class _ManagerApprovalsView extends StatefulWidget {
  const _ManagerApprovalsView();

  @override
  State<_ManagerApprovalsView> createState() => _ManagerApprovalsViewState();
}

class _ManagerApprovalsViewState extends State<_ManagerApprovalsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  // ── helpers ──────────────────────────────────────────────────────
  String _resolveName(
      NominationEntity n, bool isNominee, List<UserEntity> users) {
    final name = isNominee ? n.nomineeName : n.nominatorName;
    final id = isNominee ? n.nomineeId : n.nominatorId;
    if (name != 'Unknown') return name;
    return users.where((u) => u.id == id).map((u) => u.name).firstOrNull ??
        'Unknown';
  }

  String? _statusLabel(NominationEntity n) {
    if (n.status.toUpperCase() != 'PENDING' || n.nextRequiredLevel == null) {
      return null;
    }
    final level = n.nextRequiredLevel!.toUpperCase();
    const levelNames = {
      'DEPT_HEAD': 'Dept Head',
      'MANAGER': 'Manager',
      'HR': 'HR',
      'ADMIN': 'Admin'
    };
    return 'Pending ${levelNames[level] ?? level.replaceAll('_', ' ')}';
  }

  // ── build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocListener<NominationsBloc, NominationsState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            AppSnackbar.success(context, state.successMessage!);
          }
          if (state.status == NominationsStatus.failure &&
              state.errorMessage != null) {
            AppSnackbar.error(context, state.errorMessage!);
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.pagePadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              AppPageHeader(
                action: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    UserEntity? currentUser;
                    if (authState is AuthAuthenticated) {
                      currentUser = authState.auth.user;
                    }

                    return BlocBuilder<NominationsBloc, NominationsState>(
                      builder: (context, state) {
                        return ElevatedButton.icon(
                          onPressed:
                              (state.awardTypes.isEmpty || currentUser == null)
                                  ? null
                                  : () => showDialog(
                                        context: context,
                                        builder: (_) => NominateEmployeeDialog(
                                          awardTypes: state.awardTypes,
                                          users: state.users,
                                          bloc: context.read<NominationsBloc>(),
                                          currentUser: currentUser,
                                        ),
                                      ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Nominate'),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Tabs ────────────────────────────────────────────
              BlocBuilder<NominationsBloc, NominationsState>(
                builder: (context, state) {
                  if (state.status == NominationsStatus.loading &&
                      state.nominations.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(60.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      String userRole = 'MANAGER';
                      int? myId;
                      if (authState is AuthAuthenticated) {
                        userRole = authState.auth.user?.role ?? 'MANAGER';
                        myId = authState.auth.user?.id;
                      }

                      final all = state.nominations;

                      // All active pending nominations in my circle
                      final pendingForMe =
                          all.where((n) => n.status == 'PENDING').toList();

                      // Nominations I submitted
                      final mySubmissions = myId == null
                          ? <NominationEntity>[]
                          : all.where((n) => n.nominatorId == myId).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Stats Strip ───────────────────────────────
                          BlocBuilder<NominationsBloc, NominationsState>(
                            builder: (context, hState) {
                              final approved = hState.approvalHistory
                                  .where((h) =>
                                      h['my_action']?.toString() == 'APPROVED')
                                  .length;
                              final rejected = hState.approvalHistory
                                  .where((h) =>
                                      h['my_action']?.toString() == 'REJECTED')
                                  .length;
                              return _buildStatsStrip(
                                theme,
                                pendingForMe.length,
                                mySubmissions.length,
                                approved,
                                rejected,
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // ── Tabs Container ────────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey.shade100,
                                          width: 1),
                                    ),
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    isScrollable: Responsive.isMobile(context),
                                    tabAlignment: Responsive.isMobile(context)
                                        ? TabAlignment.start
                                        : TabAlignment.fill,
                                    labelColor: theme.colorScheme.primary,
                                    unselectedLabelColor: Colors.grey.shade500,
                                    indicator: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border(
                                        bottom: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2),
                                      ),
                                    ),
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    dividerColor: Colors.transparent,
                                    labelStyle: AppTextStyles.bodyBold(),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    tabs: [
                                      _buildTab('Pending', pendingForMe.length,
                                          Icons.hourglass_top_rounded),
                                      _buildTab(
                                          'My Nominations',
                                          mySubmissions.length,
                                          Icons.send_rounded),
                                      _buildTab(
                                          'History', 0, Icons.history_rounded),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      // Pending – with approve/reject
                                      _buildList(
                                        pendingForMe,
                                        state.users,
                                        'No pending nominations at the moment',
                                        Icons.check_circle_outline,
                                        showActions: true,
                                        userRole: userRole,
                                        myId: myId,
                                      ),

                                      // My Nominations (submitted by me)
                                      _buildList(
                                        mySubmissions,
                                        state.users,
                                        'You haven\'t nominated anyone yet',
                                        Icons.outbox_rounded,
                                        myId: myId,
                                      ),

                                      // History — nominations I personally acted on
                                      _buildHistoryTab(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Tab _buildTab(String label, int count, IconData icon) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsStrip(
    ThemeData theme,
    int pending,
    int submitted,
    int approved,
    int rejected,
  ) {
    final tiles = [
      _ManagerStatTile(
        label: 'Awaiting Review',
        value: '$pending',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFF59E0B),
        theme: theme,
      ),
      _ManagerStatTile(
        label: 'My Submissions',
        value: '$submitted',
        icon: Icons.send_rounded,
        color: const Color(0xFF6366F1),
        theme: theme,
      ),
      _ManagerStatTile(
        label: 'Approved',
        value: '$approved',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF10B981),
        theme: theme,
      ),
      _ManagerStatTile(
        label: 'Rejected',
        value: '$rejected',
        icon: Icons.cancel_outlined,
        color: const Color(0xFFEF4444),
        theme: theme,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;
        if (isNarrow) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tiles
                .map((t) =>
                    SizedBox(width: (constraints.maxWidth - 10) / 2, child: t))
                .toList(),
          );
        }
        return Row(
          children: tiles
              .map((t) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: t == tiles.last ? 0 : 12),
                      child: t,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  // ── History tab (from dedicated /my-approvals endpoint) ──────────
  Widget _buildHistoryTab() {
    return BlocBuilder<NominationsBloc, NominationsState>(
      builder: (context, state) {
        if (state.historyLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.approvalHistory.isEmpty) {
          return const EmptyStateView(
            icon: Icons.inbox_rounded,
            title: 'No approvals given yet',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: state.approvalHistory.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _buildHistoryCard(state.approvalHistory[i]),
        );
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final myAction = item['my_action']?.toString() ?? '';
    final isApproved = myAction == 'APPROVED';
    final nomStatus = item['nomination_status']?.toString() ?? '';
    final awardName = item['award_type_name']?.toString() ?? 'Award';
    final nomineeName = item['nominee_name']?.toString() ?? '';
    final nominatorName = item['nominator_name']?.toString() ?? '';
    final pts = item['points_awarded'];
    final citation = item['citation']?.toString() ?? '';
    final myComments = item['my_comments']?.toString() ?? '';
    final actionAt = item['my_action_at']?.toString() ?? '';

    // Overall status colour
    Color statusColor;
    if (nomStatus == 'APPROVED') {
      statusColor = Colors.green;
    } else if (nomStatus == 'REJECTED') {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Award + overall status
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.emoji_events_rounded,
                              color: Colors.amber.shade700, size: 17),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child:
                              Text(awardName, style: AppTextStyles.cardTitle()),
                        ),
                        StatusBadge(
                          status: nomStatus,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: Colors.grey.shade100),
                    const SizedBox(height: 10),
                    // Nominee / Nominator
                    Row(
                      children: [
                        Expanded(
                            child: _infoCell(Icons.person_outline_rounded,
                                'Nominee', nomineeName)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _infoCell(Icons.how_to_reg_outlined,
                                'Nominated by', nominatorName)),
                      ],
                    ),
                    if (citation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(citation,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.4)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(AppDateFormatter.format(actionAt),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400)),
                        if (nomStatus == 'APPROVED' && pts != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('+$pts pts',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF16A34A))),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: Colors.grey.shade100),
                    const SizedBox(height: 8),
                    // "Your action" pill
                    Row(
                      children: [
                        Icon(
                          isApproved
                              ? Icons.check_circle_outline_rounded
                              : Icons.cancel_outlined,
                          size: 14,
                          color: isApproved ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isApproved ? 'You approved' : 'You rejected',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isApproved ? Colors.green : Colors.red),
                        ),
                        if (myComments.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('· $myComments',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500)),
                          ),
                        ],
                        if (nomStatus == 'PENDING') ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Awaiting next level',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade700)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    List<NominationEntity> items,
    List<UserEntity> users,
    String emptyMsg,
    IconData emptyIcon, {
    bool showActions = false,
    String userRole = 'MANAGER',
    int? myId,
  }) {
    if (items.isEmpty) {
      return EmptyStateView(
        icon: emptyIcon,
        title: emptyMsg,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildCard(
        items[i],
        users,
        showActions: showActions,
        userRole: userRole,
        myId: myId,
      ),
    );
  }

  Widget _buildCard(
    NominationEntity n,
    List<UserEntity> users, {
    bool showActions = false,
    String userRole = 'MANAGER',
    int? myId,
  }) {
    final nominee = _resolveName(n, true, users);
    final nominator = _resolveName(n, false, users);
    final isPending = n.status == 'PENDING';

    // For MANAGER-level approvals, also verify this user is the nominee's
    // direct manager — prevents buttons appearing for unrelated managers.
    final roleMatches = isPending &&
        n.nextRequiredLevel != null &&
        n.nextRequiredLevel!.toUpperCase() == userRole.toUpperCase();
    final isDirectManager = userRole.toUpperCase() != 'MANAGER' ||
        myId == null ||
        users.where((u) => u.id == n.nomineeId).any((u) => u.managerId == myId);
    final isForMe = roleMatches && isDirectManager;

    final cardColor = n.status == 'APPROVED'
        ? const Color(0xFF16A34A)
        : n.status == 'REJECTED'
            ? const Color(0xFFDC2626)
            : const Color(0xFFF59E0B);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Award type + status
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.emoji_events_rounded,
                              color: Colors.amber.shade700, size: 17),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            n.awardTypeName.isEmpty ? 'Award' : n.awardTypeName,
                            style: AppTextStyles.cardTitle(),
                          ),
                        ),
                        StatusBadge(
                          status: n.status,
                          label: _statusLabel(n),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: Colors.grey.shade100),
                    const SizedBox(height: 10),
                    // Nominee / Nominator
                    Row(
                      children: [
                        Expanded(
                            child: _infoCell(Icons.person_outline_rounded,
                                'Nominee', nominee)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _infoCell(Icons.how_to_reg_outlined,
                                'Nominated by', nominator)),
                      ],
                    ),
                    if (n.citation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(n.citation,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.4)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(AppDateFormatter.format(n.createdAt),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400)),
                        if (n.status == 'APPROVED' &&
                            n.pointsAwarded != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+${n.pointsAwarded} pts',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF16A34A)),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Reviewer attribution + comment banner
                    if (n.reviewerLevel != null ||
                        (n.reviewerComment != null &&
                            n.reviewerComment!.isNotEmpty)) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: cardColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: cardColor.withValues(alpha: 0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (n.reviewerLevel != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.person_outline_rounded,
                                      size: 13, color: cardColor),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      (n.reviewerLevel!.toUpperCase() ==
                                                  'DEPT_HEAD'
                                              ? 'Dept Head'
                                              : n.reviewerLevel!
                                                          .toUpperCase() ==
                                                      'MANAGER'
                                                  ? 'Manager'
                                                  : n.reviewerLevel!
                                                              .toUpperCase() ==
                                                          'HR'
                                                      ? 'HR'
                                                      : n.reviewerLevel!
                                                          .replaceAll(
                                                              '_', ' ')) +
                                          (n.reviewerName != null &&
                                                  n.reviewerName!.isNotEmpty
                                              ? '  ·  ${n.reviewerName}'
                                              : ''),
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: cardColor),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (n.reviewerComment != null &&
                                  n.reviewerComment!.isNotEmpty)
                                const SizedBox(height: 5),
                            ],
                            if (n.reviewerComment != null &&
                                n.reviewerComment!.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      size: 12,
                                      color: cardColor.withValues(alpha: 0.7)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      n.reviewerComment!,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                          height: 1.4),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],

                    // Approve / Reject — only in Pending tab and only if for my role
                    if (showActions && isForMe) ...[
                      const SizedBox(height: 12),
                      Divider(height: 1, color: Colors.grey.shade100),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          RejectButton(
                            onPressed: () =>
                                _showActionDialog(context, n.id, false),
                          ),
                          const SizedBox(width: 10),
                          ApproveButton(
                            onPressed: () =>
                                _showActionDialog(context, n.id, true),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCell(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 1),
              Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  void _showActionDialog(
      BuildContext context, int nominationId, bool isApprove) {
    final commentsController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AppDialog(
          title: isApprove ? 'Approve Nomination' : 'Reject Nomination',
          maxWidth: 400,
          showCloseButton: false,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isApprove
                    ? 'Once approved, the nomination moves to the next stage in the workflow.'
                    : 'Please provide a reason for rejecting this nomination.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentsController,
                decoration: InputDecoration(
                  labelText: isApprove
                      ? 'Comments (optional)'
                      : 'Reason for rejection',
                  hintText:
                      isApprove ? 'Add any feedback...' : 'Required reason',
                  hintStyle:
                      TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            isApprove
                ? ApproveButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.read<NominationsBloc>().add(
                          ApproveNominationRequested(
                              nominationId: nominationId,
                              comments: commentsController.text.trim()));
                    },
                  )
                : RejectButton(
                    useFilledStyle: true,
                    onPressed: () {
                      if (commentsController.text.trim().isEmpty) {
                        AppSnackbar.warning(context, 'Reason is required');
                        return;
                      }
                      Navigator.of(dialogContext).pop();
                      context.read<NominationsBloc>().add(
                          RejectNominationRequested(
                              nominationId: nominationId,
                              comments: commentsController.text.trim()));
                    },
                  ),
          ],
        );
      },
    );
  }
}

class _ManagerStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _ManagerStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.headline2()),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
