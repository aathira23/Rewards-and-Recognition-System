import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../profile/domain/entities/user_entity.dart';
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
      create: (_) => sl<BudgetBloc>()
        ..add(LoadBudgetWallet())
        ..add(LoadBudgetUsers())
        ..add(LoadCurrentUser()),
      child: _BudgetsView(userRole: userRole),
    );
  }
}

class _BudgetsView extends StatefulWidget {
  final String userRole;
  const _BudgetsView({required this.userRole});

  @override
  State<_BudgetsView> createState() => _BudgetsViewState();
}

class _BudgetsViewState extends State<_BudgetsView> {
  bool get isHR =>
      widget.userRole.toUpperCase() == 'HR' ||
      widget.userRole.toUpperCase() == 'ADMIN';

  // State for Allocation
  final _managerIdController = TextEditingController();
  final _allocatePointsController = TextEditingController();

  // State for Reward
  int? _selectedEmployeeId;
  final _rewardPointsController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _managerIdController.dispose();
    _allocatePointsController.dispose();
    _rewardPointsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

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
            padding: EdgeInsets.all(Responsive.pagePadding(context)),
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
                          child: CircularProgressIndicator(color: Colors.white))
                      : Row(
                          children: [
                            const Icon(Icons.account_balance_wallet,
                                color: Colors.white, size: 36),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isHR
                                        ? 'Manager Wallet Overview'
                                        : 'My Budget Wallet',
                                    style: AppTextStyles.body(
                                        color: Colors.white70),
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
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: TabBarView(
                            children: [
                              if (isHR) _buildAllocateTab(context, state),
                              _buildRewardTab(context, state),
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

  Widget _buildAllocateTab(BuildContext context, BudgetState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Allocate Budget to Manager', style: AppTextStyles.label()),
          const SizedBox(height: 16),
          TextField(
            controller: _managerIdController,
            decoration: const InputDecoration(
              labelText: 'Manager User ID',
              hintText: 'Enter manager user ID',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _allocatePointsController,
            decoration: const InputDecoration(
              labelText: 'Points to Allocate',
              hintText: 'Enter amount',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<BudgetBloc>().add(AllocateBudget(
                    managerId: int.tryParse(_managerIdController.text) ?? 0,
                    points: int.tryParse(_allocatePointsController.text) ?? 0,
                  ));
              _managerIdController.clear();
              _allocatePointsController.clear();
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

  Widget _buildRewardTab(BuildContext context, BudgetState state) {
    if (state.currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final employees = state.users.where((u) {
      final role = state.currentUser!.role.toUpperCase();
      if (role == 'HR' || role == 'ADMIN') return true;
      // Manager and Dept Head only see their department
      return u.departmentId == state.currentUser!.departmentId;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reward Employee from Budget', style: AppTextStyles.label()),
          const SizedBox(height: 16),
          _buildSearchableDropdown(
            label: 'Select Employee',
            items: employees,
            selectedId: _selectedEmployeeId,
            onChanged: (id) => setState(() => _selectedEmployeeId = id),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _rewardPointsController,
            decoration: const InputDecoration(
              labelText: 'Points',
              hintText: 'Enter points to reward',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Why are you rewarding?',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _selectedEmployeeId == null
                ? null
                : () {
                    context.read<BudgetBloc>().add(RewardFromBudget(
                          employeeId: _selectedEmployeeId!,
                          points:
                              int.tryParse(_rewardPointsController.text) ?? 0,
                          reason: _reasonController.text,
                        ));
                    _rewardPointsController.clear();
                    _reasonController.clear();
                    setState(() => _selectedEmployeeId = null);
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

  Widget _buildSearchableDropdown({
    required String label,
    required List<UserEntity> items,
    required int? selectedId,
    required Function(int?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: selectedId,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          hint: const Text('Select a person'),
          items: items.map((user) {
            return DropdownMenuItem<int>(
              value: user.id,
              child: Text(user.name),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
