import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../bloc/budget_bloc.dart';
import '../bloc/budget_event.dart';
import '../bloc/budget_state.dart';

class BudgetsPage extends StatelessWidget {
  final String userRole;
  const BudgetsPage({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BudgetBloc>()..add(LoadBudgetWallet()),
      child: _BudgetsView(userRole: userRole),
    );
  }
}

class _BudgetsView extends StatelessWidget {
  final String userRole;
  const _BudgetsView({required this.userRole});

  bool get isHR =>
      userRole.toUpperCase() == 'HR' || userRole.toUpperCase() == 'ADMIN';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<BudgetBloc, BudgetState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ));
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${state.error}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Budget Management', style: AppTextStyles.pageTitle()),
                const SizedBox(height: 24),

                // Wallet summary card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: state.isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white))
                      : Row(
                          children: [
                            const Icon(Icons.account_balance_wallet,
                                color: Colors.white, size: 36),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHR
                                      ? 'Manager Wallet Overview'
                                      : 'My Budget Wallet',
                                  style:
                                      AppTextStyles.body(color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${state.wallet?.balance ?? 0} pts',
                                  style: AppTextStyles.displayMedium(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),

                // Tabs
                DefaultTabController(
                  length: isHR ? 2 : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: theme.colorScheme.primary,
                          tabs: [
                            if (isHR) const Tab(text: 'Allocate Budget'),
                            const Tab(text: 'Reward Employee'),
                          ],
                        ),
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            children: [
                              if (isHR) _buildAllocateTab(context),
                              _buildRewardTab(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllocateTab(BuildContext context) {
    final managerIdController = TextEditingController();
    final pointsController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Allocate Budget to Manager', style: AppTextStyles.label()),
          const SizedBox(height: 16),
          TextField(
            controller: managerIdController,
            decoration: const InputDecoration(
              labelText: 'Manager User ID',
              hintText: 'Enter manager user ID',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pointsController,
            decoration: const InputDecoration(
              labelText: 'Points to Allocate',
              hintText: 'Enter amount',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<BudgetBloc>().add(AllocateBudget(
                    managerId:
                        int.tryParse(managerIdController.text) ?? 0,
                    points: int.tryParse(pointsController.text) ?? 0,
                  ));
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 48),
            ),
            child: const Text('Allocate Budget'),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardTab(BuildContext context) {
    final employeeIdController = TextEditingController();
    final pointsController = TextEditingController();
    final reasonController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reward Employee from Budget', style: AppTextStyles.label()),
          const SizedBox(height: 16),
          TextField(
            controller: employeeIdController,
            decoration: const InputDecoration(
              labelText: 'Employee User ID',
              hintText: 'Enter employee user ID',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pointsController,
            decoration: const InputDecoration(
              labelText: 'Points',
              hintText: 'Enter points to reward',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Why are you rewarding?',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<BudgetBloc>().add(RewardFromBudget(
                    employeeId:
                        int.tryParse(employeeIdController.text) ?? 0,
                    points: int.tryParse(pointsController.text) ?? 0,
                    reason: reasonController.text,
                  ));
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 48),
            ),
            child: const Text('Reward Employee'),
          ),
        ],
      ),
    );
  }
}
