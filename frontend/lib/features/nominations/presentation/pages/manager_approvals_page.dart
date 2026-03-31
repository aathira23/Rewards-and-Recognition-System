import 'package:rr_frontend/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../injection_container.dart';
import '../bloc/nominations_bloc.dart';
import '../bloc/nominations_event.dart' as nom;
import '../bloc/nominations_state.dart';
import '../widgets/active_awards_dialog.dart';
import '../widgets/trophy_card.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/nomination_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/domain/entities/user_entity.dart';
import 'package:rr_frontend/core/presentation/widgets/main_layout.dart';
import 'package:rr_frontend/core/widgets/action_buttons.dart';
import 'package:rr_frontend/core/widgets/app_dialog.dart';
import '../../../recognitions/presentation/bloc/recognitions_bloc.dart';
import '../../../recognitions/presentation/bloc/recognitions_event.dart' as rec;
import '../../../recognitions/presentation/bloc/recognitions_state.dart';
import '../../../recognitions/presentation/widgets/recognition_feed_list.dart';

/// Approvals page for Managers and Department Heads.
///
/// Refactored to match the EmployeeAwardsPage layout:
/// • Tab 0 – My Awards: trophies received by the manager
/// • Tab 1 – Nominations: nominations the manager submitted to others
/// • Tab 2 – Approvals: pending actions and history for the team
class ManagerApprovalsPage extends StatelessWidget {
  const ManagerApprovalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<NominationsBloc>()
            ..add(nom.GetNominationsRequested())
            ..add(nom.GetAwardTypesRequested())
            ..add(nom.GetUsersRequested())
            ..add(nom.GetApprovalHistoryRequested()),
        ),
        BlocProvider(
          create: (_) => sl<RecognitionsBloc>()
            ..add(rec.GetRecognitionFeedRequested()),
        ),
      ],
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
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabs(context),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Content
                  Expanded(
                    flex: 3,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMyAwardsTab(context),
                        _buildNominationsTab(context),
                        _buildApprovalsTab(context),
                      ],
                    ),
                  ),
                  // Right Sidebar: Company Feed (Awards Only)
                  if (!isMobile)
                    Expanded(
                      flex: 1,
                      child: _buildCompanyFeed(context),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => MainLayout.of(context)
                    ?.selectTabByTitle('Recognitions'),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded,
                          size: 20, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text('Back to Dashboard',
                          style: AppTextStyles.bodyBold(color: Colors.black87)),
                    ],
                  ),
                ),
              ),
              Text(
                'Awards',
                style: AppTextStyles.headline1(color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Celebrate achievements and recognize the people who make a difference.',
                style: AppTextStyles.body(color: Colors.grey[600]),
              ),
            ],
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              UserEntity? currentUser;
              if (authState is AuthAuthenticated) {
                currentUser = authState.auth.user;
              }
              return BlocBuilder<NominationsBloc, NominationsState>(
                builder: (context, state) {
                  return ElevatedButton.icon(
                    onPressed: (state.awardTypes.isEmpty || currentUser == null)
                        ? null
                        : () => showDialog(
                              context: context,
                              builder: (_) => ActiveAwardsDialog(
                                awardTypes: state.awardTypes,
                                users: state.users,
                                bloc: context.read<NominationsBloc>(),
                                currentUser: currentUser!,
                              ),
                            ),
                    icon: const Icon(Icons.emoji_events_rounded, size: 18),
                    label: const Text('View & Nominate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Align(
        alignment: Alignment.centerLeft,
        child: BlocBuilder<NominationsBloc, NominationsState>(
          builder: (context, state) {
            final authState = context.read<AuthBloc>().state;
            int nominationCount = 0;
            int approvalCount = 0;

            if (authState is AuthAuthenticated) {
              final myId = authState.auth.user?.id;
              nominationCount =
                  state.nominations.where((n) => n.nominatorId == myId).length;
              approvalCount = state.nominations
                  .where((n) => n.status.toUpperCase() == 'PENDING')
                  .length;
            }

            return TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 24),
              indicatorColor: AppTheme.brandBlue,
              indicatorWeight: 3,
              labelColor: AppTheme.brandBlue,
              unselectedLabelColor: Colors.grey[500],
              labelStyle: AppTextStyles.bodyBold(),
              unselectedLabelStyle: AppTextStyles.body(),
              dividerColor: Colors.grey[200],
              tabs: [
                const Tab(
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('My Awards'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.send_rounded, size: 18),
                      const SizedBox(width: 8),
                      const Text('Nominations'),
                      if (nominationCount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$nominationCount',
                          style: AppTextStyles.small(color: Colors.grey[400]),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    children: [
                      const Icon(Icons.how_to_reg_rounded, size: 18),
                      const SizedBox(width: 8),
                      const Text('Approvals'),
                      if (approvalCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.brandBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$approvalCount',
                            style: AppTextStyles.smallBold(
                                color: AppTheme.brandBlue),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompanyFeed(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 32, top: 32, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Company Feed',
              style: AppTextStyles.headline1(color: Colors.black87)),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BlocBuilder<RecognitionsBloc, RecognitionsState>(
                builder: (context, state) {
                  final awardsFeed = state.feed
                      .where((r) =>
                          (r.sourceType ?? '').toUpperCase() == 'AWARD')
                      .toList();
                  if (state.status == RecognitionStatus.loading &&
                      state.feed.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (awardsFeed.isEmpty) {
                    return Center(
                        child: Text('No recent awards',
                            style:
                                AppTextStyles.body(color: Colors.grey[500])));
                  }
                  return RecognitionFeedList(
                    feed: awardsFeed,
                    shrinkWrap: true,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyAwardsTab(BuildContext context) {
    return BlocBuilder<NominationsBloc, NominationsState>(
      builder: (context, state) {
        final authState = context.read<AuthBloc>().state;
        if (authState is! AuthAuthenticated) return const SizedBox.shrink();

        final myId = authState.auth.user?.id;
        final myAwards = state.nominations
            .where((n) => n.nomineeId == myId && n.status == 'APPROVED')
            .toList();

        if (state.status == NominationsStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (myAwards.isEmpty) {
          return const EmptyStateView(
            icon: Icons.workspace_premium_rounded,
            title: 'No awards received yet',
            message: 'Keep contributing—your moment is coming!',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Trophies',
                  style: AppTextStyles.headline1(color: Colors.black87)),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 0.9,
                ),
                itemCount: myAwards.length,
                itemBuilder: (context, index) {
                  final award = myAwards[index];
                  return TrophyCard(
                    title: award.awardTypeName,
                    points: '+${award.pointsAwarded ?? 0} pts',
                    citation: award.citation.isNotEmpty
                        ? award.citation
                        : award.reviewerComment ?? 'Excellent performance',
                    from: award.nominatorName,
                    date: AppDateFormatter.format(award.createdAt),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNominationsTab(BuildContext context) {
    return BlocBuilder<NominationsBloc, NominationsState>(
      builder: (context, state) {
        final authState = context.read<AuthBloc>().state;
        if (authState is! AuthAuthenticated) return const SizedBox.shrink();

        final myId = authState.auth.user?.id;
        final mySubmissions =
            state.nominations.where((n) => n.nominatorId == myId).toList();

        if (state.status == NominationsStatus.loading &&
            state.nominations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (mySubmissions.isEmpty) {
          return const EmptyStateView(
            icon: Icons.send_rounded,
            title: 'No nominations sent yet',
            message: 'Tap "View & Nominate" to recognize a colleague!',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(context, mySubmissions),
              const SizedBox(height: 32),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mySubmissions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  return _buildNominationCard(mySubmissions[index]);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(
      BuildContext context, List<NominationEntity> submissions) {
    final total = submissions.length;
    final pending =
        submissions.where((n) => n.status.toUpperCase() == 'PENDING').length;
    final approved =
        submissions.where((n) => n.status.toUpperCase() == 'APPROVED').length;
    final rejected =
        submissions.where((n) => n.status.toUpperCase() == 'REJECTED').length;

    final cards = [
      _buildSummaryCard('Total Sent', total, Icons.send_outlined, Colors.indigo),
      _buildSummaryCard(
          'Pending', pending, Icons.hourglass_empty_rounded, Colors.orange),
      _buildSummaryCard(
          'Approved', approved, Icons.check_circle_outline_rounded, Colors.green),
      _buildSummaryCard('Rejected', rejected, Icons.cancel_outlined, Colors.red),
    ];

    if (Responsive.isMobile(context)) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: cards
            .map((c) => SizedBox(
                width: (MediaQuery.of(context).size.width - 80) / 2, child: c))
            .toList(),
      );
    }
    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
        const SizedBox(width: 16),
        Expanded(child: cards[2]),
        const SizedBox(width: 16),
        Expanded(child: cards[3]),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, int value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color.shade600, size: 20),
          ),
          const SizedBox(height: 16),
          Text('$value', style: AppTextStyles.headline1(color: Colors.black87)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.smallBold(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildNominationCard(NominationEntity nom) {
    final bool isApproved = nom.status.toUpperCase() == 'APPROVED';
    final bool isRejected = nom.status.toUpperCase() == 'REJECTED';
    final bool isPending = nom.status.toUpperCase() == 'PENDING';

    String statusText = nom.status.toUpperCase();
    if (isPending) {
      statusText =
          'PENDING ${nom.nextRequiredLevel ?? 'APPROVER'}'.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.emoji_events_outlined,
                        color: Colors.orange.shade700, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text(nom.awardTypeName,
                      style: AppTextStyles.sectionTitle(color: Colors.black87)),
                ],
              ),
              if (isPending) _buildStatusPill(statusText, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Text('Nominee',
                            style: AppTextStyles.small(color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(nom.nomineeName,
                        style: AppTextStyles.bodyBold(color: Colors.black87)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Text('Nominated by',
                            style: AppTextStyles.small(color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(nom.nominatorName,
                        style: AppTextStyles.bodyBold(color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(AppDateFormatter.format(nom.createdAt),
                  style: AppTextStyles.small(color: Colors.grey.shade500)),
            ],
          ),
          if (isApproved || isRejected) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isApproved ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isApproved
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        size: 16,
                        color: isApproved
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isApproved ? 'Approved' : 'Rejected',
                        style: AppTextStyles.smallBold(
                            color: isApproved
                                ? Colors.green.shade800
                                : Colors.red.shade800),
                      ),
                    ],
                  ),
                  if (nom.reviewerName != null)
                    Text(
                      'by ${nom.reviewerName}',
                      style: AppTextStyles.small(color: Colors.black54),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApprovalsTab(BuildContext context) {
    return BlocBuilder<NominationsBloc, NominationsState>(
      builder: (context, state) {
        final authState = context.read<AuthBloc>().state;
        String userRole = 'MANAGER';
        int? myId;
        if (authState is AuthAuthenticated) {
          userRole = authState.auth.user?.role ?? 'MANAGER';
          myId = authState.auth.user?.id;
        }

        final pendingForMe =
            state.nominations.where((n) => n.status == 'PENDING').toList();

        return DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                  indicatorColor: AppTheme.brandBlue,
                  labelColor: AppTheme.brandBlue,
                  unselectedLabelColor: Colors.grey[500],
                  labelStyle: AppTextStyles.bodyBold(),
                  tabs: [
                    Tab(text: 'Pending (${pendingForMe.length})'),
                    const Tab(text: 'History'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Pending Actions
                    _buildList(
                      pendingForMe,
                      state.users,
                      'No pending nominations at the moment',
                      Icons.check_circle_outline_rounded,
                      showActions: true,
                      userRole: userRole,
                      myId: myId,
                    ),
                    // History
                    _buildHistoryTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoCell(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, 
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
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

  Widget _buildStatusPill(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: AppTextStyles.smallBold(color: color.shade800)),
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
                          nom.ApproveNominationRequested(
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
                          nom.RejectNominationRequested(
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
