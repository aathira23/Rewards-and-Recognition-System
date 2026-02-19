import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../injection_container.dart';

class BudgetsPage extends StatefulWidget {
  final String userRole;
  const BudgetsPage({super.key, required this.userRole});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _walletData;
  bool _isLoading = true;
  String? _error;

  bool get isHR => widget.userRole.toUpperCase() == 'HR' || widget.userRole.toUpperCase() == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: isHR ? 2 : 1, vsync: this);
    _loadWallet();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoading = true);
    try {
      final client = sl<ApiClient>();
      final response = await client.get(ApiConstants.managerWallet);
      if (response.statusCode == 200) {
        setState(() {
          _walletData = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget Management',
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold)),
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
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
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_walletData?['balance'] ?? 0} pts',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (_error != null)
                          Text(_error!,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // Tabs
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
                    tabs: [
                      if (isHR) const Tab(text: 'Allocate Budget'),
                      const Tab(text: 'Reward Employee'),
                    ],
                  ),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        if (isHR) _buildAllocateTab(context),
                        _buildRewardTab(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          Text('Allocate Budget to Manager',
              style:
                  GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
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
            onPressed: () async {
              try {
                final client = sl<ApiClient>();
                await client.post(ApiConstants.managerAllocate, data: {
                  'manager_id': int.tryParse(managerIdController.text) ?? 0,
                  'points': int.tryParse(pointsController.text) ?? 0,
                });
                _loadWallet();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Budget allocated successfully'),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
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
          Text('Reward Employee from Budget',
              style:
                  GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
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
            onPressed: () async {
              try {
                final client = sl<ApiClient>();
                await client.post(ApiConstants.managerReward, data: {
                  'employee_id': int.tryParse(employeeIdController.text) ?? 0,
                  'points': int.tryParse(pointsController.text) ?? 0,
                  'reason': reasonController.text,
                });
                _loadWallet();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Employee rewarded successfully'),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
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
