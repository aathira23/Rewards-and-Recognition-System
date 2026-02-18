import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../bloc/points_bloc.dart';
import '../bloc/points_event.dart';
import '../bloc/points_state.dart';
import '../widgets/points_summary_card.dart';
import '../../domain/entities/point_transaction_entity.dart';

class PointsPage extends StatelessWidget {
  const PointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PointsBloc>()
        ..add(GetPointsSummaryRequested())
        ..add(const GetPointsHistoryRequested()),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: SingleChildScrollView(
            // Add scroll view here? Or stick to list structure?
            // Actually, we want the summary at top and list below
            // A CustomScrollView is best
            child: BlocBuilder<PointsBloc, PointsState>(
              builder: (context, state) {
                if (state.status == PointsStatus.loading &&
                    state.summary == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == PointsStatus.failure &&
                    state.summary == null) {
                  return Center(child: Text('Error: ${state.errorMessage}'));
                }

                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Wallet',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (state.summary != null)
                        PointsSummaryCard(summary: state.summary!),
                      const SizedBox(height: 32),
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
                          physics:
                              const NeverScrollableScrollPhysics(), // Scroll handled by SingleScrollView
                          itemCount: state.history.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionItem(state.history[index]);
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(PointTransactionEntity transaction) {
    final isCredit = transaction.transactionType == 'CREDIT';
    final color = isCredit ? Colors.green : Colors.red;
    final icon =
        isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline;
    final amountPrefix = isCredit ? '+' : '-';

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
                  _formatReferenceType(transaction.referenceType),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat.yMMMd().add_jm().format(transaction.createdAt),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$amountPrefix${transaction.points}',
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

  String _formatReferenceType(String type) {
    // Basic formatting
    return type.substring(0, 1).toUpperCase() + type.substring(1).toLowerCase();
  }
}
