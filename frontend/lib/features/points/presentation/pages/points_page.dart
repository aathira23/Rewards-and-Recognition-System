import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../bloc/points_bloc.dart';
import '../bloc/points_event.dart';
import '../bloc/points_state.dart';
import '../widgets/points_summary_card.dart';
import '../widgets/leaderboard_panel.dart';
import '../../domain/entities/point_transaction_entity.dart';

class PointsPage extends StatefulWidget {
  final String userRole;
  const PointsPage({super.key, this.userRole = 'EMPLOYEE'});

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  String _currentPeriod = 'MONTHLY';
  late PointsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<PointsBloc>();
    _refreshData();
  }

  void _refreshData() {
    _bloc.add(GetPointsSummaryRequested());
    _bloc.add(const GetPointsHistoryRequested());
    _bloc.add(GetLeaderboardRequested(period: _currentPeriod));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: BlocBuilder<PointsBloc, PointsState>(
          builder: (context, state) {
            if (state.status == PointsStatus.loading &&
                state.summary == null &&
                state.leaderboard.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == PointsStatus.failure &&
                state.summary == null &&
                state.leaderboard.isEmpty) {
              return Center(child: Text('Error: ${state.errorMessage}'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                _refreshData();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Points Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Wallet & History
                        Expanded(
                          flex: 65,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (state.summary != null) ...[
                                PointsSummaryCard(
                                  summary: state.summary!,
                                  userRole: widget.userRole,
                                ),
                                const SizedBox(height: 32),
                              ],
                              const Text(
                                'Transaction History',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (state.history.isEmpty)
                                const Center(
                                    child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text('No transactions yet'),
                                ))
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: state.history.length,
                                  itemBuilder: (context, index) {
                                    return _buildTransactionItem(
                                        state.history[index]);
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column: Leaderboard
                        Expanded(
                          flex: 35,
                          child: Column(
                            children: [
                              if (state.status == PointsStatus.loading &&
                                  state.leaderboard.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (state.status == PointsStatus.failure &&
                                  state.leaderboard.isEmpty)
                                _buildErrorCard(state.errorMessage ??
                                    'Failed to load leaderboard')
                              else
                                LeaderboardPanel(
                                  entries: state.leaderboard,
                                  currentPeriod: _currentPeriod,
                                  onPeriodChanged: (period) {
                                    setState(() {
                                      _currentPeriod = period;
                                    });
                                    _bloc.add(GetLeaderboardRequested(
                                        period: period));
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade900, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(PointTransactionEntity transaction) {
    final isCredit = transaction.points.startsWith('+');
    final color = isCredit ? Colors.green : Colors.red;
    final icon =
        isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  transaction.date,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction.points,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
