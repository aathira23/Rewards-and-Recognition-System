import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/nominations_bloc.dart';
import '../bloc/nominations_event.dart' as nom;
import '../bloc/nominations_state.dart';
import '../widgets/active_awards_dialog.dart';
import '../widgets/trophy_card.dart';
import '../../domain/entities/nomination_entity.dart';
import '../../../../core/widgets/app_snackbar.dart';
import 'package:rr_frontend/core/presentation/widgets/main_layout.dart';

import '../../../profile/domain/entities/user_entity.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../recognitions/presentation/bloc/recognitions_bloc.dart';
import '../../../recognitions/presentation/bloc/recognitions_event.dart' as rec;

class EmployeeNominationsPage extends StatelessWidget {
  const EmployeeNominationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<NominationsBloc>()
            ..add(nom.GetNominationsRequested())
            ..add(nom.GetAwardTypesRequested())
            ..add(nom.GetUsersRequested()),
        ),
        BlocProvider(
          create: (_) =>
              sl<RecognitionsBloc>()..add(rec.GetRecognitionFeedRequested()),
        ),
      ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(Responsive.pagePadding(context)),
              child: Column(
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
                              style: AppTextStyles.bodyBold(
                                  color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Awards',
                              style: AppTextStyles.headline1(
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Celebrate achievements and recognize the people who make a difference.',
                              style:
                                  AppTextStyles.body(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, authState) {
                          UserEntity? currentUser;
                          if (authState is AuthAuthenticated) {
                            currentUser = authState.auth.user;
                          }
                          return BlocBuilder<NominationsBloc, NominationsState>(
                            builder: (context, state) {
                              return ElevatedButton.icon(
                                onPressed: (state.awardTypes.isEmpty ||
                                        currentUser == null)
                                    ? null
                                    : () => showDialog(
                                          context: context,
                                          builder: (_) => ActiveAwardsDialog(
                                            awardTypes: state.awardTypes,
                                            users: state.users,
                                            bloc:
                                                context.read<NominationsBloc>(),
                                            currentUser: currentUser!,
                                          ),
                                        ),
                                icon: const Icon(Icons.emoji_events_rounded,
                                    size: 18),
                                label: const Text('View & Nominate'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2D2A70),
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
                ],
              ),
            ),
            _buildTabs(context),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyAwardsTab(context),
                  _buildNominationsTab(context),
                ],
              ),
            ),
          ],
        ),
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
            int nominationCount = 0;
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthAuthenticated) {
              final myId = authState.auth.user?.id;
              nominationCount =
                  state.nominations.where((n) => n.nominatorId == myId).length;
            }

            return TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 24),
              indicatorColor: const Color(0xFF2D2A70),
              indicatorWeight: 3,
              labelColor: const Color(0xFF2D2A70),
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
              ],
            );
          },
        ),
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
            message: 'Keep up the great work!',
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
      _buildSummaryCard('Total Sent', total, Icons.send_outlined, Colors.blue),
      _buildSummaryCard(
          'Pending', pending, Icons.hourglass_empty_rounded, Colors.orange),
      _buildSummaryCard('Approved', approved,
          Icons.check_circle_outline_rounded, Colors.green),
      _buildSummaryCard(
          'Rejected', rejected, Icons.cancel_outlined, Colors.red),
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
            color: Colors.black.withOpacity(0.02),
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
            color: Colors.black.withOpacity(0.02),
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
                            style: AppTextStyles.small(
                                color: Colors.grey.shade500)),
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
                            style: AppTextStyles.small(
                                color: Colors.grey.shade500)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isApproved ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
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
                        isApproved ? 'Approved by' : 'Rejected by',
                        style: AppTextStyles.smallBold(
                            color: isApproved
                                ? Colors.green.shade800
                                : Colors.red.shade800),
                      ),
                      if (nom.reviewerName != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('-',
                              style:
                                  AppTextStyles.small(color: Colors.black54)),
                        ),
                        Text(nom.reviewerName!,
                            style:
                                AppTextStyles.smallBold(color: Colors.black87)),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      Icon(isApproved ? Icons.check : Icons.close,
                          size: 16,
                          color: isApproved
                              ? Colors.green.shade700
                              : Colors.red.shade700),
                      const SizedBox(width: 4),
                      Text(
                        isApproved ? 'Approved' : 'Rejected',
                        style: AppTextStyles.smallBold(
                            color: isApproved
                                ? Colors.green.shade700
                                : Colors.red.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
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
}
