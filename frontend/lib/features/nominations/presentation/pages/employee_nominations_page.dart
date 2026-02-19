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
import '../../../profile/domain/entities/user_entity.dart';

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

  // Raw current-user-id loaded directly (to distinguish "my nominations" vs
  // "received awards" without introducing a heavy dependency).
  int? _currentUserId;
  bool _userIdLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final client = sl<ApiClient>();
      final res = await client.get(ApiConstants.profile);
      final data = res.data['data'] ?? res.data ?? {};
      if (mounted) {
        setState(() {
          _currentUserId = data['id'];
          _userIdLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _userIdLoading = false);
    }
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
              // ── Header ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nominations',
                          style: AppTextStyles.pageTitle(),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Nominate a colleague or check your award status',
                          style:
                              AppTextStyles.body(color: Colors.grey.shade500),
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
                        label: const Text('Nominate Someone'),
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

              // ── Tabs ──────────────────────────────────────────────
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
                      labelStyle: AppTextStyles.bodyBold(),
                      tabs: const [
                        Tab(text: 'My Nominations'),
                        Tab(text: 'Awards Received'),
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

                        if (_userIdLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(48.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        // Nominations I submitted
                        final submitted = _currentUserId == null
                            ? state.nominations
                            : state.nominations
                                .where((n) => n.nominatorId == _currentUserId)
                                .toList();

                        // Awards where I am the nominee and they are APPROVED
                        final received = _currentUserId == null
                            ? <NominationEntity>[]
                            : state.nominations
                                .where((n) =>
                                    n.nomineeId == _currentUserId &&
                                    n.status == 'APPROVED')
                                .toList();

                        return SizedBox(
                          height: 520,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No nominations submitted yet',
                style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 6),
            Text('Tap "Nominate Someone" to get started',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium_rounded,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No awards received yet',
                style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 6),
            Text('Keep up the great work!',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
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
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top accent bar matching status colour
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.6),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                    _statusBadge(nom),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 10),
                // Nominee + Nominator row
                Row(
                  children: [
                    Expanded(
                      child: _infoCell(
                          Icons.person_outline_rounded, 'Nominee', nomineeName),
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
                        fontSize: 12, color: Colors.grey.shade600, height: 1.4),
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
                      _formatDate(nom.createdAt),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
                            _formatDate(nom.createdAt),
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

  Widget _statusBadge(NominationEntity nom) {
    final status = nom.status.toUpperCase();
    final color = _statusColor(status);

    String label = status;
    if (status == 'PENDING' && nom.nextRequiredLevel != null) {
      final level = nom.nextRequiredLevel!.toUpperCase();
      if (level == 'MANAGER')
        label = 'Pending Mgr';
      else if (level == 'DEPT_HEAD')
        label = 'Pending Head';
      else if (level == 'HR') label = 'Pending HR';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
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
