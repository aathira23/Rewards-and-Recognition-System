import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../injection_container.dart';
import '../bloc/nominations_bloc.dart';
import '../bloc/nominations_event.dart';
import '../bloc/nominations_state.dart';
import '../widgets/nominate_employee_dialog.dart';
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
        ..add(GetUsersRequested()),
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
  int? _myId;
  bool _idLoading = true;

  // Approval history loaded from dedicated endpoint
  List<Map<String, dynamic>> _approvalHistory = [];
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
    _loadApprovalHistory();
  }

  Future<void> _loadApprovalHistory() async {
    try {
      final res = await sl<ApiClient>().get(ApiConstants.myApprovalHistory);
      final data = res.data['data'] ?? [];
      if (mounted) {
        setState(() {
          _approvalHistory =
              (data is List) ? data.cast<Map<String, dynamic>>() : [];
          _historyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final res = await sl<ApiClient>().get(ApiConstants.profile);
      final data = res.data['data'] ?? res.data ?? {};
      if (mounted) {
        setState(() {
          _myId = data['id'];
          _idLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _idLoading = false);
    }
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

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF16A34A);
      case 'REJECTED':
        return const Color(0xFFDC2626);
      case 'PENDING':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(NominationEntity n) {
    if (n.status.toUpperCase() != 'PENDING' || n.nextRequiredLevel == null) {
      return n.status;
    }
    switch (n.nextRequiredLevel!.toUpperCase()) {
      case 'MANAGER':
        return 'Pending Mgr';
      case 'DEPT_HEAD':
        return 'Pending Head';
      case 'HR':
        return 'Pending HR';
      default:
        return 'Pending';
    }
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return d;
    }
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
            // Reload history so the acted-on card appears immediately
            _loadApprovalHistory();
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nomination Approvals',
                            style: AppTextStyles.pageTitle()),
                        const SizedBox(height: 2),
                        Text('Review and action pending award nominations',
                            style: AppTextStyles.body(
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  BlocBuilder<NominationsBloc, NominationsState>(
                    builder: (context, state) {
                      return ElevatedButton.icon(
                        onPressed: state.awardTypes.isEmpty
                            ? null
                            : () => showDialog(
                                  context: context,
                                  builder: (_) => NominateEmployeeDialog(
                                    awardTypes: state.awardTypes,
                                    users: state.users,
                                    bloc: context.read<NominationsBloc>(),
                                  ),
                                ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Nominate'),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Tabs ────────────────────────────────────────────
              BlocBuilder<NominationsBloc, NominationsState>(
                builder: (context, state) {
                  if ((state.status == NominationsStatus.loading &&
                          state.nominations.isEmpty) ||
                      _idLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(60.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      String userRole = 'MANAGER';
                      if (authState is AuthAuthenticated) {
                        userRole = authState.auth.user?.role ?? 'MANAGER';
                      }

                      final all = state.nominations;

                      // Pending for MY role
                      final pendingForMe = all
                          .where((n) =>
                              n.status == 'PENDING' &&
                              n.nextRequiredLevel != null &&
                              n.nextRequiredLevel!.toUpperCase() ==
                                  userRole.toUpperCase())
                          .toList();

                      // Nominations I submitted
                      final mySubmissions = _myId == null
                          ? <NominationEntity>[]
                          : all.where((n) => n.nominatorId == _myId).toList();

                      // History – resolved nominations
                      // final history =
                      //     all.where((n) => n.status != 'PENDING').toList();

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              labelColor: theme.colorScheme.primary,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: theme.colorScheme.primary,
                              labelStyle: AppTextStyles.bodyBold(),
                              tabs: [
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('Pending'),
                                      if (pendingForMe.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${pendingForMe.length}',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.orange.shade700),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Tab(text: 'My Nominations'),
                                const Tab(text: 'History'),
                              ],
                            ),
                            SizedBox(
                              height: 540,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // Pending – with approve/reject
                                  _buildList(
                                    pendingForMe,
                                    state.users,
                                    'All caught up! No nominations waiting for your approval',
                                    Icons.check_circle_outline,
                                    showActions: true,
                                    userRole: userRole,
                                  ),

                                  // My Nominations (submitted by me)
                                  _buildList(
                                    mySubmissions,
                                    state.users,
                                    'You haven\'t nominated anyone yet',
                                    Icons.outbox_rounded,
                                  ),

                                  // History — nominations I personally acted on
                                  _buildHistoryTab(),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  // ── History tab (from dedicated /my-approvals endpoint) ──────────
  Widget _buildHistoryTab() {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_approvalHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No approvals given yet',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _approvalHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildHistoryCard(_approvalHistory[i]),
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
    final justification = item['justification']?.toString() ?? '';
    final myComments = item['my_comments']?.toString() ?? '';
    final actionAt = item['my_action_at']?.toString() ?? '';

    // Overall status colour
    Color statusColor;
    String statusLabel;
    if (nomStatus == 'APPROVED') {
      statusColor = Colors.green;
      statusLabel = 'Approved';
    } else if (nomStatus == 'REJECTED') {
      statusColor = Colors.red;
      statusLabel = 'Rejected';
    } else {
      statusColor = Colors.orange;
      statusLabel = 'In Progress';
    }

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
          // Accent bar coloured by overall status
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.6),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
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
                      child: Text(awardName, style: AppTextStyles.cardTitle()),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
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
                if (justification.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(justification,
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
                    Text(_fmtDate(actionAt),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                    if (nomStatus == 'APPROVED' && pts != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF16A34A).withValues(alpha: 0.08),
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
        ],
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
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyMsg,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
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
      ),
    );
  }

  Widget _buildCard(
    NominationEntity n,
    List<UserEntity> users, {
    bool showActions = false,
    String userRole = 'MANAGER',
  }) {
    final color = _statusColor(n.status);
    final nominee = _resolveName(n, true, users);
    final nominator = _resolveName(n, false, users);
    final isPending = n.status == 'PENDING';
    final isForMe = isPending &&
        n.nextRequiredLevel != null &&
        n.nextRequiredLevel!.toUpperCase() == userRole.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: showActions && isPending
                ? Colors.orange.shade100
                : Colors.grey.shade100),
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
              color: color.withValues(alpha: 0.6),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(n),
                        style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
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
                    Text(_fmtDate(n.createdAt),
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

                // Approve / Reject — only in Pending tab and only if for my role
                if (showActions && isForMe) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.shade100),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showActionDialog(context, n.id, false),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _showActionDialog(context, n.id, true),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
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

  void _showActionDialog(
      BuildContext context, int nominationId, bool isApprove) {
    final commentsController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            isApprove ? 'Approve Nomination' : 'Reject Nomination',
            style: AppTextStyles.sectionHeader(),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (isApprove) {
                  context.read<NominationsBloc>().add(
                      ApproveNominationRequested(
                          nominationId: nominationId,
                          comments: commentsController.text.isEmpty
                              ? null
                              : commentsController.text));
                } else {
                  context.read<NominationsBloc>().add(RejectNominationRequested(
                      nominationId: nominationId,
                      comments: commentsController.text.isEmpty
                          ? null
                          : commentsController.text));
                }
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprove ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(isApprove ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );
  }
}
