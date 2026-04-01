import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import 'package:rr_frontend/injection_container.dart';
import 'package:rr_frontend/features/points/domain/entities/leaderboard_entry_entity.dart';
import 'package:rr_frontend/features/points/presentation/bloc/points_bloc.dart';
import 'package:rr_frontend/features/points/presentation/bloc/points_event.dart';
import 'package:rr_frontend/features/points/presentation/bloc/points_state.dart';

import 'package:rr_frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rr_frontend/features/auth/presentation/bloc/auth_state.dart';
import 'package:rr_frontend/core/presentation/widgets/main_layout.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  String _currentPeriod = 'MONTHLY';
  late PointsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<PointsBloc>();
    _refresh();
  }

  void _refresh() {
    _bloc.add(GetLeaderboardRequested(period: _currentPeriod));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: BlocBuilder<PointsBloc, PointsState>(
                  builder: (context, state) {
                    if (state.status == PointsStatus.loading &&
                        state.leaderboard.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.leaderboard.isEmpty &&
                        state.status == PointsStatus.success) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: Text('No leaderboard data available.'),
                        ),
                      );
                    }

                    final top3 = state.leaderboard.take(3).toList();
                    final rest = state.leaderboard;

                    return Column(
                      children: [
                        if (top3.isNotEmpty) _buildPodiumContainer(top3),
                        const SizedBox(height: 24),
                        _buildRankingsListContainer(rest),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  final authState = context.read<AuthBloc>().state;
                  String title = 'Recognitions';
                  if (authState is AuthAuthenticated) {
                    final role = authState.auth.user?.role.toUpperCase();
                    if (role == 'HR' || role == 'ADMIN') {
                      title = 'Dashboard';
                    }
                  }
                  MainLayout.of(context)?.selectTabByTitle(title);
                },
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
                'Leaderboard',
                style: AppTextStyles.headline1(color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'See how you stack up against your peers',
                style: AppTextStyles.body(color: Colors.grey[600]),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton('This Month', 'MONTHLY'),
                _buildToggleButton('This Year', 'YEARLY'),
                _buildToggleButton('All Time', 'ALL_TIME'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, String value) {
    final isSelected = _currentPeriod == value;
    return InkWell(
      onTap: () {
        setState(() => _currentPeriod = value);
        _refresh();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D2A70) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: isSelected
              ? AppTextStyles.bodyBold(color: Colors.white)
              : AppTextStyles.body(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildPodiumContainer(List<LeaderboardEntryEntity> top3) {
    // Top 3 layout: rank 2 left, rank 1 center, rank 3 right
    final rank1 = top3.isNotEmpty ? top3[0] : null;
    final rank2 = top3.length > 1 ? top3[1] : null;
    final rank3 = top3.length > 2 ? top3[2] : null;

    return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 500;
            if (isMobile) {
              // Stack vertically on very small screens if needed, or scale down
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (rank2 != null)
                    Expanded(
                        child: _buildPodiumItem(
                            rank2, 2, 140, const Color(0xFFF3F4F6))),
                  if (rank1 != null)
                    Expanded(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildPodiumItem(
                                rank1, 1, 180, const Color(0xFFFFFBEB)))),
                  if (rank3 != null)
                    Expanded(
                        child: _buildPodiumItem(
                            rank3, 3, 120, const Color(0xFFFFF7ED))),
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (rank2 != null)
                  _buildPodiumItem(rank2, 2, 140, const Color(0xFFF3F4F6),
                      width: 140),
                if (rank1 != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildPodiumItem(
                          rank1, 1, 180, const Color(0xFFFFFBEB),
                          width: 160)),
                if (rank3 != null)
                  _buildPodiumItem(rank3, 3, 120, const Color(0xFFFFF7ED),
                      width: 140),
              ],
            );
          },
        ));
  }

  Widget _buildPodiumItem(
      LeaderboardEntryEntity entry, int rank, double height, Color boxColor,
      {double? width}) {
    Color medalColor;
    IconData iconData = Icons.emoji_events;
    if (rank == 1)
      medalColor = const Color(0xFFEAB308); // Gold
    else if (rank == 2)
      medalColor = const Color(0xFF9CA3AF); // Silver
    else
      medalColor = const Color(0xFFD97706); // Bronze

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconData, color: medalColor, size: 32),
        const SizedBox(height: 8),
        CircleAvatar(
          radius: rank == 1 ? 36 : 28,
          backgroundColor:
              rank == 1 ? const Color(0xFF2D2A70) : Colors.indigo.shade50,
          child: Text(
            entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
            style: AppTextStyles.headline1(
                    color: rank == 1 ? Colors.white : const Color(0xFF2D2A70))
                .copyWith(fontSize: rank == 1 ? 24 : 20),
          ),
        ),
        const SizedBox(height: 12),
        Text(entry.name,
            style: AppTextStyles.bodyBold(color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rank == 1) ...[
              Icon(Icons.star, color: medalColor, size: 14),
              const SizedBox(width: 4),
            ],
            Text('${entry.score} pts',
                style: AppTextStyles.bodyBold(color: const Color(0xFF2D2A70))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            rank.toString(),
            style: AppTextStyles.display(color: medalColor),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingsListContainer(List<LeaderboardEntryEntity> entries) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rankings', style: AppTextStyles.sectionHeader()),
              Text('${entries.length} Participants',
                  style: AppTextStyles.body(color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (context, index) =>
                Divider(color: Colors.grey.withOpacity(0.1), height: 32),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _buildListRow(entry);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(LeaderboardEntryEntity entry) {
    Widget rankWidget;
    if (entry.rank == 1) {
      rankWidget =
          const Icon(Icons.emoji_events, color: Color(0xFFEAB308), size: 24);
    } else if (entry.rank == 2) {
      rankWidget =
          const Icon(Icons.military_tech, color: Color(0xFF9CA3AF), size: 24);
    } else if (entry.rank == 3) {
      rankWidget =
          const Icon(Icons.military_tech, color: Color(0xFFD97706), size: 24);
    } else {
      rankWidget = SizedBox(
        width: 24,
        child: Center(
          child: Text(
            entry.rank.toString(),
            style: AppTextStyles.bodyBold(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(width: 32, child: rankWidget),
        const SizedBox(width: 16),
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFF2D2A70),
          child: Text(
            entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
            style: AppTextStyles.bodyBold(color: Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.name,
                  style: AppTextStyles.bodyBold(color: Colors.black87)),
              if (entry.departmentName != null &&
                  entry.departmentName!.isNotEmpty)
                Text(entry.departmentName!,
                    style: AppTextStyles.small(color: Colors.grey.shade500)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${entry.score} pts',
                style: AppTextStyles.bodyBold(color: const Color(0xFF2D2A70))),
            // Placeholder for up/down spots if supported
            // Row(children: [ Icon(Icons.trending_up, size: 12, color: Colors.green), Text(' Up 2 spots', style: AppTextStyles.small(color: Colors.green)) ])
          ],
        ),
      ],
    );
  }
}
