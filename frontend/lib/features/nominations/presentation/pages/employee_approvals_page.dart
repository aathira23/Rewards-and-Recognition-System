import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/nomination_entity.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../bloc/nominations_bloc.dart';
import '../bloc/nominations_event.dart';
import '../bloc/nominations_state.dart';
import '../widgets/nominate_employee_dialog.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/utils/date_formatter.dart';

/// Employee Nomination Tracker — read-only view.
///
/// Tabs:
/// • Submitted – nominations this employee created
/// • Received  – approved awards where the employee is the nominee
/// • All       – every nomination the employee is involved in
///
/// Employees do NOT have approve/reject authority.
class EmployeeApprovalsPage extends StatelessWidget {
  const EmployeeApprovalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NominationsBloc>()
        ..add(GetNominationsRequested())
        ..add(GetAwardTypesRequested())
        ..add(GetUsersRequested()),
      child: const _ApprovalsView(),
    );
  }
}

class _ApprovalsView extends StatefulWidget {
  const _ApprovalsView();

  @override
  State<_ApprovalsView> createState() => _ApprovalsViewState();
}

class _ApprovalsViewState extends State<_ApprovalsView>
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
    return 'Pending $level';
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
              // ── Header ──────────────────────────────────────────
              AppPageHeader(
                title: 'My Nominations',
                subtitle: 'Track your nominations and awards',
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      isScrollable: Responsive.isMobile(context),
                      tabAlignment: Responsive.isMobile(context)
                          ? TabAlignment.start
                          : TabAlignment.fill,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: theme.colorScheme.primary,
                      labelStyle: AppTextStyles.bodyBold(),
                      tabs: const [
                        Tab(text: 'Submitted'),
                        Tab(text: 'Received'),
                        Tab(text: 'All Activity'),
                      ],
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
                        int? myId;
                        final authState = context.read<AuthBloc>().state;
                        if (authState is AuthAuthenticated) {
                          myId = authState.auth.user?.id;
                        }

                        // Nominations I submitted
                        final submitted = myId == null
                            ? state.nominations
                            : state.nominations
                                .where((n) => n.nominatorId == myId)
                                .toList();

                        // Approved awards where I'm the nominee
                        final received = myId == null
                            ? <NominationEntity>[]
                            : state.nominations
                                .where((n) =>
                                    n.nomineeId == myId &&
                                    n.status == 'APPROVED')
                                .toList();

                        // All nominations I'm involved in
                        final allMine = myId == null
                            ? state.nominations
                            : state.nominations
                                .where((n) =>
                                    n.nominatorId == myId ||
                                    n.nomineeId == myId)
                                .toList();

                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildList(
                                  submitted,
                                  state.users,
                                  'You haven\'t submitted any nominations yet',
                                  Icons.outbox_rounded),
                              _buildList(
                                  received,
                                  state.users,
                                  'No awards received yet',
                                  Icons.workspace_premium_outlined),
                              _buildList(
                                  allMine,
                                  state.users,
                                  'No nomination activity',
                                  Icons.inbox_rounded),
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

  Widget _buildList(List<NominationEntity> items, List<UserEntity> users,
      String emptyMsg, IconData emptyIcon) {
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
      itemBuilder: (_, i) => _buildCard(items[i], users),
    );
  }

  Widget _buildCard(NominationEntity n, List<UserEntity> users) {
    final nominee = _resolveName(n, true, users);
    final nominator = _resolveName(n, false, users);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Accent bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: (n.status == 'APPROVED'
                      ? const Color(0xFF16A34A)
                      : n.status == 'REJECTED'
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFF59E0B))
                  .withValues(alpha: 0.6),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
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
                        child: _infoCell(
                            Icons.person_outline_rounded, 'Nominee', nominee)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _infoCell(Icons.how_to_reg_outlined,
                            'Nominated by', nominator)),
                  ],
                ),
                if (n.justification.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(n.justification,
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
                    if (n.status == 'APPROVED' && n.pointsAwarded != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF16A34A).withValues(alpha: 0.08),
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
              ],
            ),
          ),
        ],
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
}