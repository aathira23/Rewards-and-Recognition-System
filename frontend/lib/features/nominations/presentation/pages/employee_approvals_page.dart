import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/nomination_entity.dart';
import '../bloc/nominations_bloc.dart';
import '../bloc/nominations_event.dart';
import '../bloc/nominations_state.dart';
import '../widgets/nominate_employee_dialog.dart';

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
              Row(
                children: [
                  Expanded(
                    child: Text('Nominations & Approvals',
                        style: GoogleFonts.outfit(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  BlocBuilder<NominationsBloc, NominationsState>(
                    builder: (context, state) {
                      return ElevatedButton.icon(
                        onPressed: (state.awardTypes.isEmpty)
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
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
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
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: theme.colorScheme.primary,
                      tabs: const [
                        Tab(text: 'All Nominations'),
                        Tab(text: 'Pending'),
                        Tab(text: 'Resolved'),
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

                        final all = state.nominations;
                        final pending =
                            all.where((n) => n.status == 'PENDING').toList();
                        final resolved =
                            all.where((n) => n.status != 'PENDING').toList();

                        return SizedBox(
                          height: 500,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildNominationsList(context, all),
                              _buildNominationsList(context, pending),
                              _buildNominationsList(context, resolved),
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

  Widget _buildNominationsList(
      BuildContext context, List<NominationEntity> nominations) {
    if (nominations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No nominations found',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: nominations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final nom = nominations[index];
        return _buildNominationCard(context, nom);
      },
    );
  }

  Widget _buildNominationCard(BuildContext context, NominationEntity nom) {
    final statusColor = _getStatusColor(nom.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
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
                  nom.status,
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
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
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
          if (nom.status == 'PENDING') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showActionDialog(context, nom.id, false),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showActionDialog(context, nom.id, true),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          title: Text(isApprove ? 'Approve Nomination' : 'Reject Nomination'),
          content: TextField(
            controller: commentsController,
            decoration: const InputDecoration(
              labelText: 'Comments (optional)',
            ),
            maxLines: 3,
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
              ),
              child: Text(isApprove ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
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
