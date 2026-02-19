import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../injection_container.dart';
import '../bloc/nominations_bloc.dart';
import '../bloc/nominations_event.dart';
import '../bloc/nominations_state.dart';
import '../widgets/nominate_employee_dialog.dart';
import '../../domain/entities/nomination_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Approvals page for Managers and Department Heads.
///
/// • Tab 1 – Pending approvals: nominations waiting for action (Approve/Reject)
/// • Tab 2 – My Nominations: nominations I submitted
/// • Tab 3 – All (history): all visible nominations
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
                        Text(
                          'Nomination Approvals',
                          style: GoogleFonts.outfit(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Review and action pending award nominations',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500),
                        ),
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
                        label: const Text('Nominate Employee'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Tabs ─────────────────────────────────────────────
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
                      String userRole = 'EMPLOYEE';
                      if (authState is AuthAuthenticated) {
                        userRole = authState.auth.user?.role ?? 'EMPLOYEE';
                      }

                      final all = state.nominations;
                      // Only show in Pending if it's waiting for THIS role
                      final pendingForMe = all
                          .where((n) =>
                              n.status == 'PENDING' &&
                              n.nextRequiredLevel != null &&
                              n.nextRequiredLevel!.toUpperCase() ==
                                  userRole.toUpperCase())
                          .toList();

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
                              labelStyle: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600),
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
                                  // Pending – with approve/reject buttons
                                  _buildNominationsList(context, pendingForMe,
                                      showActions: true,
                                      userRole: userRole,
                                      emptyIcon: Icons.check_circle_outline,
                                      emptyText:
                                          'All caught up! No nominations waiting for your approval'),

                                  // My nominations (submitted by me)
                                  _buildNominationsList(context, all,
                                      showActions: false,
                                      userRole: userRole,
                                      emptyIcon: Icons.outbox_rounded,
                                      emptyText:
                                          'You haven\'t nominated anyone yet'),

                                  // Full history
                                  _buildNominationsList(context, all,
                                      showActions: false,
                                      userRole: userRole,
                                      emptyIcon: Icons.inbox_rounded,
                                      emptyText: 'No nominations found'),
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

  Widget _buildNominationsList(
    BuildContext context,
    List<NominationEntity> nominations, {
    required bool showActions,
    required String userRole,
    required IconData emptyIcon,
    required String emptyText,
  }) {
    if (nominations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyText,
                style: TextStyle(color: Colors.grey.shade500),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: nominations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildNominationCard(
          context, nominations[index], showActions, userRole),
    );
  }

  Widget _buildNominationCard(BuildContext context, NominationEntity nom,
      bool showActions, String userRole) {
    final statusColor = _statusColor(nom.status);
    final isPending = nom.status == 'PENDING';
    // Double check if it's really meant for me
    final isForMe = isPending &&
        nom.nextRequiredLevel != null &&
        nom.nextRequiredLevel!.toUpperCase() == userRole.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending && showActions
            ? Colors.orange.shade50.withValues(alpha: 0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isPending && showActions
                ? Colors.orange.shade100
                : Colors.grey.shade200),
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
                    Text(nom.awardTypeName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('Nominee: ${nom.nomineeName}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(nom),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (nom.justification.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(nom.justification,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text('By ${nom.nominatorName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const Spacer(),
              Text(_formatDate(nom.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),

          // Approve / Reject buttons — only for PENDING, only in Pending tab, and ONLY if it's my turn
          if (showActions && isForMe) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showActionDialog(context, nom.id, false),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: Size.zero,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _showActionDialog(context, nom.id, true),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
            style:
                GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold),
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
                        : 'Reason for rejection (optional)',
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

  String _statusLabel(NominationEntity nom) {
    if (nom.status.toUpperCase() == 'PENDING' &&
        nom.nextRequiredLevel != null) {
      final level = nom.nextRequiredLevel!.toUpperCase();
      if (level == 'MANAGER') return 'Pending Mgr';
      if (level == 'DEPT_HEAD') return 'Pending Head';
      if (level == 'HR') return 'Pending HR';
    }
    return nom.status;
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

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
