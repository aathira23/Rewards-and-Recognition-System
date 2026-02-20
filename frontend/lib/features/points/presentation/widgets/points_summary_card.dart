import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../budgets/presentation/bloc/budget_bloc.dart';
import '../../../budgets/presentation/bloc/budget_event.dart';
import '../../../budgets/presentation/bloc/budget_state.dart';
import '../../domain/entities/points_summary_entity.dart';

/// Wallet card with a toggle between "My Points" and "Manager Wallet".
/// The toggle only appears for MANAGER / DEPT_HEAD / HR roles.
class PointsSummaryCard extends StatefulWidget {
  final PointsSummaryEntity summary;
  final String userRole;

  const PointsSummaryCard({
    super.key,
    required this.summary,
    this.userRole = 'EMPLOYEE',
  });

  @override
  State<PointsSummaryCard> createState() => _PointsSummaryCardState();
}

class _PointsSummaryCardState extends State<PointsSummaryCard> {
  bool _showManagerWallet = false;

  bool get _canToggle {
    final r = widget.userRole.toUpperCase();
    return r == 'MANAGER' || r == 'DEPT_HEAD' || r == 'HR' || r == 'ADMIN';
  }

  void _toggle(bool toManager) {
    if (toManager) {
      final bloc = context.read<BudgetBloc>();
      bloc.add(LoadBudgetWallet());
      bloc.add(LoadBudgetUsers());
      bloc.add(LoadCurrentUser());
    }
    setState(() => _showManagerWallet = toManager);
  }

  // ─── Colours per wallet ───

  static const _personalGrad = [Color(0xFF1E56BD), Color(0xFF3B7BF2)];
  static const _managerGrad = [Color(0xFF0F7B5F), Color(0xFF2ABB8B)];

  @override
  Widget build(BuildContext context) {
    final isManager = _showManagerWallet;
    final grad = isManager ? _managerGrad : _personalGrad;

    return BlocListener<BudgetBloc, BudgetState>(
      listenWhen: (prev, curr) =>
          prev.successMessage != curr.successMessage ||
          prev.error != curr.error,
      listener: (context, budgetState) {
        if (budgetState.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(budgetState.successMessage!),
            backgroundColor: Colors.green,
          ));
        }
        if (budgetState.error != null && budgetState.wallet != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(budgetState.error!),
            backgroundColor: Colors.red,
          ));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: grad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: grad.first.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header row: title + toggle ───
              Row(
                children: [
                  Icon(
                    isManager
                        ? Icons.savings_rounded
                        : Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isManager ? 'Manager Wallet' : 'Points Wallet',
                    style: AppTextStyles.label(
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (_canToggle) _buildToggle(isManager),
                ],
              ),
              const SizedBox(height: 18),

              // ─── Animated switcher between wallet contents ───
              // Fixed height prevents the card from resizing during transition.
              SizedBox(
                height: 168,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: isManager
                      ? _managerContent(key: const ValueKey('mgr'))
                      : _personalContent(key: const ValueKey('personal')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Toggle pill ───

  Widget _buildToggle(bool isManager) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleChip(
            label: 'Personal',
            active: !isManager,
            onTap: () => _toggle(false),
          ),
          _toggleChip(
            label: 'Budget',
            active: isManager,
            onTap: () => _toggle(true),
          ),
        ],
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: AppTextStyles.smallBold(
            color: active ? const Color(0xFF1E56BD) : Colors.white70,
          ),
        ),
      ),
    );
  }

  // ─── Personal wallet content ───

  Widget _personalContent({Key? key}) {
    final s = widget.summary;
    return SizedBox(
      key: key,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.balance.toString(),
                style: AppTextStyles.displayLarge(
                  color: Colors.white,
                ),
              ),
              Text(
                'Available Points',
                style: AppTextStyles.body(color: Colors.white70),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 14),
              Builder(
                builder: (context) {
                  final statWidgets = [
                    _stat('Total Earned', s.totalEarned.toString(),
                        Icons.trending_up),
                    _stat('Redeemed', s.totalRedeemed.toString(),
                        Icons.shopping_bag_outlined),
                    _stat(
                        'Expiring Soon',
                        (s.expiringToday + s.expiringThisMonth).toString(),
                        Icons.timer_outlined,
                        sub: s.expiringToday > 0
                            ? '${s.expiringToday} exp today'
                            : 'rest of month'),
                  ];
                  if (Responsive.isMobile(context)) {
                    return Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: statWidgets,
                    );
                  }
                  return Row(
                    children:
                        statWidgets.map((w) => Expanded(child: w)).toList(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Manager wallet content ───

  Widget _managerContent({Key? key}) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, budgetState) {
        if (budgetState.isLoading && budgetState.wallet == null) {
          return SizedBox(
            key: key,
            width: double.infinity,
            child: const Center(
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            ),
          );
        }

        if (budgetState.error != null && budgetState.wallet == null) {
          return SizedBox(
            key: key,
            width: double.infinity,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white60, size: 28),
                  const SizedBox(height: 8),
                  Text('Could not load budget',
                      style: AppTextStyles.body(color: Colors.white60)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        context.read<BudgetBloc>().add(LoadBudgetWallet()),
                    child: Text('Tap to retry',
                        style: AppTextStyles.small(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        final balance = budgetState.wallet?.balance ?? 0;

        return SizedBox(
          key: key,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        balance.toString(),
                        style: AppTextStyles.displayLarge(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'pts available to reward',
                        style: AppTextStyles.body(color: Colors.white70),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _rewardButton(),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 10),
                  Text(
                    'Use your budget to reward team members directly from this wallet.',
                    style: AppTextStyles.small(color: Colors.white60),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Reward employee quick-action ───

  Widget _rewardButton() {
    return GestureDetector(
      onTap: () => _showRewardDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Reward Employee',
              style: AppTextStyles.bodyBold(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardDialog(BuildContext context) {
    final budgetBloc = context.read<BudgetBloc>();
    final budgetState = budgetBloc.state;
    final users = budgetState.users;
    final currentUser = budgetState.currentUser;
    int? selectedEmployeeId;
    final pointsCtl = TextEditingController();
    final reasonCtl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.card_giftcard_rounded,
                  color: Theme.of(context).colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              const Text('Reward Employee'),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (users.isEmpty || currentUser == null)
                    const Text('Loading users...',
                        style: TextStyle(fontSize: 12, color: Colors.grey))
                  else
                    DropdownButtonFormField<int>(
                      initialValue: selectedEmployeeId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Employee',
                        filled: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Search or select employee'),
                      items: users.where((u) {
                        final role = currentUser.role.toUpperCase();
                        if (role == 'HR' || role == 'ADMIN') return true;
                        return u.departmentId == currentUser.departmentId;
                      }).map((user) {
                        return DropdownMenuItem<int>(
                          value: user.id,
                          child: Text(user.name),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedEmployeeId = val),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: pointsCtl,
                    decoration: const InputDecoration(labelText: 'Points'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reasonCtl,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                budgetBloc.add(RewardFromBudget(
                  employeeId: selectedEmployeeId ?? 0,
                  points: int.tryParse(pointsCtl.text) ?? 0,
                  reason: reasonCtl.text,
                ));
              },
              child: const Text('Send Reward'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stat helper ───

  Widget _stat(String label, String value, IconData icon, {String? sub}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.small(color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.sectionHeader(
            color: Colors.white,
          ),
        ),
        if (sub != null)
          Text(sub, style: AppTextStyles.tiny(color: Colors.white54)),
      ],
    );
  }
}
