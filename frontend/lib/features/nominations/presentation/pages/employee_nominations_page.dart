import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/nominations_bloc.dart';
import '../bloc/nominations_event.dart';
import '../bloc/nominations_state.dart';
import '../widgets/nominate_employee_dialog.dart';
import '../../domain/entities/nomination_entity.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/utils/date_formatter.dart';

/// Employee-only nominations page.
///
/// • Nominate a colleague
/// • View nominations I submitted (with status chip)
/// • View awards I have received (approved nominations where I am the nominee)
class EmployeeNominationsPage extends StatelessWidget {
  const EmployeeNominationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NominationsBloc>()
        ..add(GetNominationsRequested())
        ..add(GetAwardTypesRequested())
        ..add(GetUsersRequested()),
      child: const _EmployeeNominationsView(),
    );
  }
}

class _EmployeeNominationsView extends StatefulWidget {
  const _EmployeeNominationsView();

  @override
  State<_EmployeeNominationsView> createState() =>
      _EmployeeNominationsViewState();
}

class _EmployeeNominationsViewState extends State<_EmployeeNominationsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocListener<NominationsBloc, NominationsState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ));
          }
          if (state.status == NominationsStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ));
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.pagePadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────
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
              const SizedBox(height: 20),

              // ── Stats Strip ───────────────────────────────────────
              BlocBuilder<NominationsBloc, NominationsState>(
                builder: (context, state) {
                  int? currentUserId;
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    currentUserId = authState.auth.user?.id;
                  }
                  final submitted = currentUserId == null
                      ? state.nominations
                      : state.nominations
                          .where((n) => n.nominatorId == currentUserId)
                          .toList();
                  final pending = submitted
                      .where((n) => n.status.toUpperCase() == 'PENDING')
                      .length;
                  final approved = submitted
                      .where((n) => n.status.toUpperCase() == 'APPROVED')
                      .length;
                  final rejected = submitted
                      .where((n) => n.status.toUpperCase() == 'REJECTED')
                      .length;
                  return _NominationStatsStrip(
                    total: submitted.length,
                    pending: pending,
                    approved: approved,
                    rejected: rejected,
                  );
                },
              ),
              const SizedBox(height: 20),

              // ── Tabs ──────────────────────────────────────────────
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
                          bottom:
                              BorderSide(color: Colors.grey.shade100, width: 1),
                        ),
                      ),
                      child: BlocBuilder<NominationsBloc, NominationsState>(
                        builder: (context, state) {
                          int? currentUserId;
                          final authState = context.read<AuthBloc>().state;
                          if (authState is AuthAuthenticated) {
                            currentUserId = authState.auth.user?.id;
                          }
                          final submittedCount = currentUserId == null
                              ? state.nominations.length
                              : state.nominations
                                  .where((n) => n.nominatorId == currentUserId)
                                  .length;
                          final receivedCount = currentUserId == null
                              ? 0
                              : state.nominations
                                  .where((n) =>
                                      n.nomineeId == currentUserId &&
                                      n.status == 'APPROVED')
                                  .length;
                          return TabBar(
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
                                    color: theme.colorScheme.primary, width: 2),
                              ),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelStyle: AppTextStyles.bodyBold(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            tabs: [
                              _buildTab('My Nominations', submittedCount,
                                  Icons.send_rounded),
                              _buildTab('Awards Received', receivedCount,
                                  Icons.workspace_premium_rounded),
                            ],
                          );
                        },
                      ),
                    ),
                    BlocBuilder<NominationsBloc, NominationsState>(
                      builder: (context, state) {
                        if (state.status == NominationsStatus.loading &&
                            state.nominations.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(48.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        // Get current user ID from AuthBloc
                        int? currentUserId;
                        final authState = context.read<AuthBloc>().state;
                        if (authState is AuthAuthenticated) {
                          currentUserId = authState.auth.user?.id;
                        }

                        // Nominations I submitted
                        final submitted = currentUserId == null
                            ? state.nominations
                            : state.nominations
                                .where((n) => n.nominatorId == currentUserId)
                                .toList();

                        // Awards where I am the nominee and they are APPROVED
                        final received = currentUserId == null
                            ? <NominationEntity>[]
                            : state.nominations
                                .where((n) =>
                                    n.nomineeId == currentUserId &&
                                    n.status == 'APPROVED')
                                .toList();

                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildSubmittedList(
                                  context, state, submitted, state.users),
                              _buildReceivedList(
                                  context, received, state.users),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── My Nominations tab ──────────────────────────────────────────
  Widget _buildSubmittedList(BuildContext context, NominationsState state,
      List<NominationEntity> nominations, List<UserEntity> users) {
    if (nominations.isEmpty) {
      return const EmptyStateView(
        icon: Icons.emoji_events_outlined,
        title: 'No nominations submitted yet',
        message: 'Tap "Nominate Someone" to get started',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: nominations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildNominationCard(nominations[index],
          users: users, canAction: false),
    );
  }

  // ── Awards Received tab ─────────────────────────────────────────
  Widget _buildReceivedList(BuildContext context,
      List<NominationEntity> received, List<UserEntity> users) {
    if (received.isEmpty) {
      return const EmptyStateView(
        icon: Icons.workspace_premium_rounded,
        title: 'No awards received yet',
        message: 'Keep up the great work!',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: received.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          _buildReceivedCard(received[index], users),
    );
  }

  Widget _buildNominationCard(NominationEntity nom,
      {required bool canAction, List<UserEntity> users = const []}) {
    final nomineeName = nom.nomineeName == 'Unknown'
        ? users
                .where((u) => u.id == nom.nomineeId)
                .map((u) => u.name)
                .firstOrNull ??
            'Unknown'
        : nom.nomineeName;
    final nominatorName = nom.nominatorName == 'Unknown'
        ? users
                .where((u) => u.id == nom.nominatorId)
                .map((u) => u.name)
                .firstOrNull ??
            'Unknown'
        : nom.nominatorName;

    final statusColor = _statusColor(nom.status.toUpperCase());

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
            // Left accent bar
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
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Award name row + status badge
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.emoji_events_rounded,
                              color: Colors.amber.shade700, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            nom.awardTypeName,
                            style: AppTextStyles.cardTitle(),
                          ),
                        ),
                        StatusBadge(
                          status: nom.status,
                          label: _statusLabel(nom),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 10),
                    // Nominee + Nominator row
                    Row(
                      children: [
                        Expanded(
                          child: _infoCell(Icons.person_outline_rounded,
                              'Nominee', nomineeName),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoCell(Icons.how_to_reg_outlined,
                              'Nominated by', nominatorName),
                        ),
                      ],
                    ),
                    if (nom.justification.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        nom.justification,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          AppDateFormatter.format(nom.createdAt),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                        if (nom.status == 'APPROVED' &&
                            nom.pointsAwarded != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              '+${nom.pointsAwarded} pts',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Reviewer attribution + comment banner
                    if (nom.reviewerLevel != null ||
                        (nom.reviewerComment != null &&
                            nom.reviewerComment!.isNotEmpty)) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (nom.reviewerLevel != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.person_outline_rounded,
                                      size: 13, color: statusColor),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      (nom.reviewerLevel!.toUpperCase() ==
                                                  'DEPT_HEAD'
                                              ? 'Dept Head'
                                              : nom.reviewerLevel!
                                                          .toUpperCase() ==
                                                      'MANAGER'
                                                  ? 'Manager'
                                                  : nom.reviewerLevel!
                                                              .toUpperCase() ==
                                                          'HR'
                                                      ? 'HR'
                                                      : nom.reviewerLevel!
                                                          .replaceAll(
                                                              '_', ' ')) +
                                          (nom.reviewerName != null &&
                                                  nom.reviewerName!.isNotEmpty
                                              ? '  ·  ${nom.reviewerName}'
                                              : ''),
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (nom.reviewerComment != null &&
                                  nom.reviewerComment!.isNotEmpty)
                                const SizedBox(height: 5),
                            ],
                            if (nom.reviewerComment != null &&
                                nom.reviewerComment!.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      size: 12,
                                      color:
                                          statusColor.withValues(alpha: 0.7)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      nom.reviewerComment!,
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

  Widget _buildReceivedCard(NominationEntity nom, List<UserEntity> users) {
    final nominatorName = nom.nominatorName == 'Unknown'
        ? users
                .where((u) => u.id == nom.nominatorId)
                .map((u) => u.name)
                .firstOrNull ??
            'Unknown'
        : nom.nominatorName;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gold accent bar
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.workspace_premium_rounded,
                      color: Colors.amber.shade700, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nom.awardTypeName,
                        style: AppTextStyles.cardTitle(),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.how_to_reg_outlined,
                              size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'By $nominatorName',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            AppDateFormatter.format(nom.createdAt),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (nom.pointsAwarded != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${nom.pointsAwarded}',
                        style: AppTextStyles.headline2(
                            color: Colors.amber.shade700),
                      ),
                      Text('pts',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.amber.shade600,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
              ],
            ),
          ),
        ],
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

  String? _statusLabel(NominationEntity nom) {
    if (nom.status.toUpperCase() != 'PENDING' ||
        nom.nextRequiredLevel == null) {
      return null;
    }
    final level = nom.nextRequiredLevel!.toUpperCase();
    const levelNames = {
      'DEPT_HEAD': 'Dept Head',
      'MANAGER': 'Manager',
      'HR': 'HR',
      'ADMIN': 'Admin'
    };
    return 'Pending ${levelNames[level] ?? level.replaceAll('_', ' ')}';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// ── Stats Strip Widget ─────────────────────────────────────────────────────

class _NominationStatsStrip extends StatelessWidget {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const _NominationStatsStrip({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiles = [
      _StatTile(
        label: 'Total Sent',
        value: '$total',
        icon: Icons.send_rounded,
        color: const Color(0xFF6366F1),
        theme: theme,
      ),
      _StatTile(
        label: 'Pending',
        value: '$pending',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFF59E0B),
        theme: theme,
      ),
      _StatTile(
        label: 'Approved',
        value: '$approved',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF10B981),
        theme: theme,
      ),
      _StatTile(
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
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _StatTile({
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
