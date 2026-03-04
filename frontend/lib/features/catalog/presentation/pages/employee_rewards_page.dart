import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../points/presentation/bloc/points_bloc.dart';
import '../../../points/presentation/bloc/points_event.dart';
import '../../../points/presentation/bloc/points_state.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';
import '../widgets/rewards_balance_card.dart';
import '../widgets/catalog_tab_navigation.dart';
import '../widgets/reward_item_card.dart';

class EmployeeRewardsPage extends StatefulWidget {
  const EmployeeRewardsPage({super.key});

  @override
  State<EmployeeRewardsPage> createState() => _EmployeeRewardsPageState();
}

class _EmployeeRewardsPageState extends State<EmployeeRewardsPage> {
  int _currentTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<CatalogBloc>()
            ..add(GetCatalogItemsRequested())
            ..add(GetHistoryRequested())
            ..add(GetPointsRulesRequested()),
        ),
        BlocProvider(
          create: (context) =>
              sl<PointsBloc>()..add(GetPointsSummaryRequested()),
        ),
      ],
      child: BlocListener<CatalogBloc, CatalogState>(
        listener: (context, state) {
          if (state.redemptionSuccess == true) {
            _showSuccessOverlay(context, 'Redemption Successful!',
                'Your reward is being processed.');
            context.read<PointsBloc>().add(GetPointsSummaryRequested());
            context.read<CatalogBloc>().add(GetHistoryRequested());
          }
          if (state.conversionSuccess == true) {
            _showSuccessOverlay(context, 'Request Submitted!',
                'Your points conversion is pending approval.');
            context.read<CatalogBloc>().add(GetHistoryRequested());
          }
          if (state.status == CatalogStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Builder(
            builder: (innerContext) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Area
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rewards Store',
                            style: Theme.of(innerContext)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          Text(
                            'Redeem your hard-earned points',
                            style: TextStyle(
                              color: Theme.of(innerContext).hintColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      IconButton.filledTonal(
                        onPressed: () => context
                            .read<CatalogBloc>()
                            .add(GetCatalogItemsRequested()),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Balance Card
                  BlocBuilder<PointsBloc, PointsState>(
                    builder: (context, state) {
                      final balance = state.summary?.balance ?? 0;
                      return RewardsBalanceCard(balance: balance);
                    },
                  ),
                  const SizedBox(height: 40),

                  // Tab Navigation
                  CatalogTabNavigation(
                    selectedIndex: _currentTabIndex,
                    onTabSelected: (index) {
                      setState(() => _currentTabIndex = index);
                    },
                  ),
                  const SizedBox(height: 32),

                  // Tab Content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentTab(innerContext),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessOverlay(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Colors.green, size: 80),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Great!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab(BuildContext context) {
    switch (_currentTabIndex) {
      case 0:
        return _buildCatalogTab(context);
      case 1:
        return _buildHistoryTab(context);
      case 2:
        return _buildConversionTab(context);
      default:
        return const SizedBox();
    }
  }

  Widget _buildHistoryTab(BuildContext context) {
    return BlocBuilder<CatalogBloc, CatalogState>(
      builder: (context, state) {
        if (state.status == CatalogStatus.loading &&
            state.redemptions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final redemptions = state.redemptions;
        if (redemptions.isEmpty) {
          return _buildEmptyState(
            context,
            Icons.history_edu_rounded,
            'No Redemptions Yet',
            'Your redemption history will appear here once you claim rewards.',
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: redemptions.length,
          itemBuilder: (context, index) {
            final item = redemptions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shopping_bag_rounded,
                      color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(
                  item.rewardName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${item.rewardCategory} • ${_formatDate(item.createdAt)}',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '-${item.pointsSpent} pts',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    _buildStatusBadge(context, item.status),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonth(date.month)} ${date.year}';
  }

  String _getMonth(int month) {
    const list = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'July',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec'
    ];
    return list[month];
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'APPROVED':
      case 'COMPLETED':
        color = Colors.green;
        break;
      case 'REJECTED':
      case 'CANCELLED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  final _pointsController = TextEditingController();
  String _selectedConversionType = 'PAYROLL';
  double _currentRate = 0.1;

  Widget _buildConversionTab(BuildContext context) {
    return BlocBuilder<CatalogBloc, CatalogState>(
      builder: (context, state) {
        // Find rate for selected type
        final rule = state.pointsRules.firstWhere(
          (r) =>
              r['recognition_type'] == 'CONVERSION' &&
              r['conversion_reward_type'] == _selectedConversionType,
          orElse: () => {},
        );
        _currentRate = (rule['conversion_rate'] != null)
            ? double.parse(rule['conversion_rate'].toString())
            : 0.1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Conversion Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(Icons.swap_horizontal_circle_outlined,
                      size: 48, color: Colors.indigo),
                  const SizedBox(height: 16),
                  const Text(
                    'Convert Points to Cash',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current rate: 100 pts = \$${(100 * _currentRate).toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.indigoAccent,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Conversion Details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Amount of Points',
                        hintText: 'Minimum 500 pts',
                        prefixIcon: const Icon(Icons.toll_rounded),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _pointsController.clear();
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedConversionType,
                      decoration: const InputDecoration(
                        labelText: 'Transfer Destination',
                        prefixIcon: Icon(Icons.account_balance_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'PAYROLL', child: Text('Monthly Payroll')),
                        DropdownMenuItem(
                            value: 'CSR', child: Text('CSR Charity Fund')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedConversionType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    // Live Calculation
                    if (_pointsController.text.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'You will receive:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green),
                            ),
                            Text(
                              '\$${((int.tryParse(_pointsController.text) ?? 0) * _currentRate).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _handleSubmitConversion(context),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt_rounded),
                            SizedBox(width: 8),
                            Text('Confirm & Convert',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Requests',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () =>
                      context.read<CatalogBloc>().add(GetHistoryRequested()),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Conversion list
            state.conversions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No conversion history found.'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.conversions.length,
                    itemBuilder: (context, index) {
                      final req = state.conversions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: req.status == 'APPROVED'
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              req.status == 'APPROVED'
                                  ? Icons.check_rounded
                                  : Icons.access_time_rounded,
                              color: req.status == 'APPROVED'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          title: Text('${req.pointsConverted} Points',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'To ${req.conversionType} • ${_formatDate(req.createdAt)}'),
                          trailing: Text(
                            '\$${req.cashAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        );
      },
    );
  }

  void _handleSubmitConversion(BuildContext context) {
    final pts = int.tryParse(_pointsController.text);
    if (pts == null || pts < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum conversion is 500 points')),
      );
      return;
    }
    context.read<CatalogBloc>().add(
        SubmitConversionRequested(points: pts, type: _selectedConversionType));
    _pointsController.clear();
  }

  Widget _buildEmptyState(
      BuildContext context, IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Theme.of(context).hintColor),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogTab(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search and Filters (Image 2 Mix)
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search rewards...',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  fillColor: theme.colorScheme.surface,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'All Categories',
                  items: [
                    'All Categories',
                    'Gift Cards',
                    'Merchandise',
                    'Experiences'
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {},
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Rewards Grid
        BlocBuilder<CatalogBloc, CatalogState>(
          builder: (context, catalogState) {
            if (catalogState.status == CatalogStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (catalogState.status == CatalogStatus.failure) {
              return Center(child: Text('Error: ${catalogState.errorMessage}'));
            }

            final items = catalogState.items.where((item) {
              final query = _searchController.text.toLowerCase();
              final matchesQuery = item.name.toLowerCase().contains(query) ||
                  item.description.toLowerCase().contains(query);

              // Category logic
              final selectedCategory =
                  'All Categories'; // TODO: add state for this
              final matchesCategory = selectedCategory == 'All Categories' ||
                  item.category == selectedCategory;

              return matchesQuery && matchesCategory;
            }).toList();

            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text('No rewards available in the catalog yet.'),
                ),
              );
            }

            return BlocBuilder<PointsBloc, PointsState>(
              builder: (context, pointsState) {
                final balance = pointsState.summary?.balance ?? 0;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        2, // Changed to 2 for better layout on common screens
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final reward = items[index];
                    return RewardItemCard(
                      reward: reward,
                      hasInsufficientPoints: balance < reward.pointsCost,
                      onRedeem: () {
                        _showRedemptionConfirm(context, reward);
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showRedemptionConfirm(BuildContext context, dynamic reward) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Redemption'),
        content: Text(
            'Are you sure you want to redeem "${reward.name}" for ${reward.pointsCost} points?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CatalogBloc>().add(RedeemItemRequested(reward.id));
              Navigator.pop(dialogContext);
              // Show notification on success via BlocListener if we added one
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
