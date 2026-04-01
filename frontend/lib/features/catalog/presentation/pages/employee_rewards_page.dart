import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/feature_flag_service.dart';
import '../../domain/entities/reward_entity.dart';
import '../../../points/presentation/bloc/points_bloc.dart';
import '../../../points/presentation/bloc/points_event.dart';
import '../../../points/presentation/bloc/points_state.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';
import '../widgets/rewards_balance_card.dart';
import '../widgets/catalog_tab_navigation.dart';
import '../widgets/reward_item_card.dart';
import '../../../../core/presentation/widgets/main_layout.dart';

class EmployeeRewardsPage extends StatefulWidget {
  const EmployeeRewardsPage({super.key});

  @override
  State<EmployeeRewardsPage> createState() => _EmployeeRewardsPageState();
}

class _EmployeeRewardsPageState extends State<EmployeeRewardsPage> {
  int _currentTabIndex = 0;
  // null = still loading; true/false = flag resolved
  bool? _conversionEnabled;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    _loadFeatureFlags();
  }

  Future<void> _loadFeatureFlags() async {
    final enabled =
        await sl<FeatureFlagService>().isEnabled('conversion_enabled');
    if (mounted) {
      setState(() => _conversionEnabled = enabled);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pointsController.dispose();
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
            context.read<CatalogBloc>().add(GetCatalogItemsRequested());
          }
          if (state.conversionSuccess == true) {
            _showSuccessOverlay(context, 'Request Submitted!',
                'Your points conversion is pending approval.');
            context.read<CatalogBloc>().add(GetHistoryRequested());
          }
          if (state.status == CatalogStatus.failure &&
              state.errorMessage != null) {
            final msg = state.errorMessage!;
            if (msg.toLowerCase().contains('insufficient points') ||
                msg.toLowerCase().contains('insufficient balance')) {
              _showInsufficientPointsDialog(context, msg);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Builder(
            builder: (innerContext) => CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.pagePadding(context),
                    vertical: Responsive.pagePadding(context),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Page header — title + balance badge
                      BlocBuilder<PointsBloc, PointsState>(
                        builder: (context, pointsState) {
                          final balance = pointsState.summary?.balance ?? 0;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    BlocBuilder<AuthBloc, AuthState>(
                                      builder: (context, authState) {
                                        String destination = 'Recognitions';
                                        if (authState is AuthAuthenticated) {
                                          final role = authState.auth.user?.role
                                              .toUpperCase();
                                          if (role == 'HR' || role == 'ADMIN') {
                                            destination = 'Dashboard';
                                          }
                                        }

                                        return GestureDetector(
                                          onTap: () => MainLayout.of(context)
                                              ?.selectTabByTitle(destination),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 12.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                    Icons.arrow_back_rounded,
                                                    size: 20,
                                                    color: Colors.black87),
                                                const SizedBox(width: 8),
                                                Text('Back to Dashboard',
                                                    style:
                                                        AppTextStyles.bodyBold(
                                                            color:
                                                                Colors.black87)),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const Text(
                                      'Rewards Store',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Redeem your hard-earned points',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RewardsBalanceCard.badge(balance: balance),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // Tab Navigation — only render once the feature flag is known
                      if (_conversionEnabled == null)
                        const SizedBox(
                          height: 48,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else
                        CatalogTabNavigation(
                          selectedIndex: _currentTabIndex,
                          onTabSelected: (index) {
                            setState(() => _currentTabIndex = index);
                          },
                          conversionEnabled: _conversionEnabled!,
                        ),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),

                // Tab Content - Sliverized
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.pagePadding(context),
                  ),
                  sliver: _buildCurrentTabSliver(innerContext),
                ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInsufficientPointsDialog(BuildContext context, String rawMessage) {
    // Extract numbers from the message for a friendlier display
    // e.g. "Insufficient points. Balance: 200, Requested: 500"
    final balanceMatch =
        RegExp(r'(?:Balance|Available):\s*(\d+)').firstMatch(rawMessage);
    final requestedMatch = RegExp(r'Requested:\s*(\d+)').firstMatch(rawMessage);
    final int? have =
        balanceMatch != null ? int.tryParse(balanceMatch.group(1)!) : null;
    final int? need =
        requestedMatch != null ? int.tryParse(requestedMatch.group(1)!) : null;
    final int? shortfall = (have != null && need != null) ? need - have : null;

    showDialog(
      context: context,
      builder: (_) => AppDialog(
        title: 'Not Enough Points',
        maxWidth: 500,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.orange.withValues(alpha: 0.12),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              shortfall != null
                  ? 'You need $shortfall more points.'
                  : "You don't have enough points for this.",
              textAlign: TextAlign.center,
              style: AppTextStyles.body(color: Colors.grey),
            ),
            if (have != null && need != null) ...[
              const SizedBox(height: 16),
              Text(
                '$have / $need',
                style: AppTextStyles.cardTitle(),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessOverlay(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Colors.green, size: 80),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Great!'),
            ),
          ),
        ],
      ),
    );
  }

  final _pointsController = TextEditingController();
  String _selectedConversionType = 'PAYROLL';
  String _selectedCategory = 'All';

  // Maps display labels → backend reward_type values
  static const _categoryMap = {
    'Gift Cards': 'GIFT_CARD',
    'Merchandise': 'MERCH',
  };

  Widget _buildConversionTab(BuildContext context, {Key? key}) {
    return BlocBuilder<CatalogBloc, CatalogState>(
      key: key,
      builder: (context, state) {
        // Find rate for selected type
        final rule = state.pointsRules.firstWhere(
          (r) =>
              r['recognition_type'] == 'CONVERSION' &&
              r['conversion_reward_type'] == _selectedConversionType,
          orElse: () => {},
        );
        final double currentRate = (rule['conversion_rate'] != null)
            ? double.parse(rule['conversion_rate'].toString())
            : 0.1;

        final pts = int.tryParse(_pointsController.text) ?? 0;
        final cashValue = pts * currentRate;
        final isPayroll = _selectedConversionType == 'PAYROLL';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Two-panel row ──
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > 680;
              final formCard = Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8EAF6)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D2A70).withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card header
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B31A5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.swap_horiz_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Convert Points',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '1 pt = ₹${currentRate.toStringAsFixed(3)}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Points input
                          TextField(
                            controller: _pointsController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'Points to Convert',
                              hintText: 'Min. 500 pts',
                              hintStyle: const TextStyle(
                                color: Color(0xFFCDD0E3),
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF7F8FD),
                              prefixIcon: const Icon(Icons.toll_rounded,
                                  color: Color(0xFF3B31A5)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE8EAF6)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE8EAF6)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF3B31A5), width: 1.5),
                              ),
                              suffixIcon: pts > 0
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded,
                                          size: 18),
                                      onPressed: () {
                                        _pointsController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Destination selector as chips
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() =>
                                      _selectedConversionType = 'PAYROLL'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isPayroll
                                          ? const Color(0xFF2D2A70)
                                          : const Color(0xFFF7F8FD),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isPayroll
                                            ? const Color(0xFF2D2A70)
                                            : const Color(0xFFE8EAF6),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.account_balance_rounded,
                                            size: 16,
                                            color: isPayroll
                                                ? Colors.white
                                                : Colors.grey.shade500),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Payroll',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isPayroll
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedConversionType = 'CSR'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: !isPayroll
                                          ? const Color(0xFF2D2A70)
                                          : const Color(0xFFF7F8FD),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: !isPayroll
                                            ? const Color(0xFF2D2A70)
                                            : const Color(0xFFE8EAF6),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.volunteer_activism_rounded,
                                            size: 16,
                                            color: !isPayroll
                                                ? Colors.white
                                                : Colors.grey.shade500),
                                        const SizedBox(width: 6),
                                        Text(
                                          'CSR Fund',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: !isPayroll
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Receive amount chip
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: pts > 0
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFECFDF5),
                                        Color(0xFFF0FDF4),
                                      ],
                                    )
                                  : null,
                              color: pts > 0 ? null : const Color(0xFFF7F8FD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: pts > 0
                                    ? const Color(0xFF6EE7B7)
                                    : const Color(0xFFE8EAF6),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'You will receive',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: pts > 0
                                        ? const Color(0xFF059669)
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                Text(
                                  pts > 0
                                      ? '₹${cashValue.toStringAsFixed(2)}'
                                      : '—',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: pts > 0
                                        ? const Color(0xFF059669)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => _handleSubmitConversion(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D2A70),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bolt_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Confirm & Convert',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              final infoPanel = Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FD),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8EAF6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How it works',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ConversionStep(
                      number: '1',
                      title: 'Enter amount',
                      subtitle: 'Minimum 500 pts per request',
                      color: const Color(0xFF2D2A70),
                    ),
                    const SizedBox(height: 12),
                    _ConversionStep(
                      number: '2',
                      title: 'Choose destination',
                      subtitle: 'Payroll or CSR charity',
                      color: const Color(0xFF6741D9),
                    ),
                    const SizedBox(height: 12),
                    _ConversionStep(
                      number: '3',
                      title: 'Await approval',
                      subtitle: 'HR reviews within 2 business days',
                      color: const Color(0xFF059669),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 16),
                    Text(
                      'Current Rate',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF2D2A70).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '100 pts',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3B5BDB),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 16, color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF059669).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₹${(100 * currentRate).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          formCard,
                          const SizedBox(height: 32),
                          const Text(
                            'Recent Requests',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRecentRequestsList(state),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: infoPanel),
                  ],
                );
              }
              return Column(children: [
                formCard,
                const SizedBox(height: 16),
                infoPanel,
                const SizedBox(height: 32),
                const Text(
                  'Recent Requests',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                _buildRecentRequestsList(state),
              ]);
            }),
          ],
        );
      },
    );
  }

  Widget _buildRecentRequestsList(CatalogState state) {
    if (state.conversions.isEmpty) {
      return const EmptyStateView(
        icon: Icons.history_rounded,
        title: 'No conversion history',
        message: 'Your point conversion requests will appear here.',
        padding: 40,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEFF5)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.conversions.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Color(0xFFEEEFF5),
        ),
        itemBuilder: (context, index) {
          final req = state.conversions[index];
          final status = req.status.toLowerCase();
          final statusColor = status == 'approved'
              ? const Color(0xFF059669)
              : status == 'pending'
                  ? const Color(0xFFEA580C)
                  : status == 'rejected'
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF757575);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B31A5).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sync_alt_rounded,
                      color: Color(0xFF3B31A5), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${req.pointsConverted} pts → ${req.conversionType}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppDateFormatter.short(req.createdAt),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${req.cashAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      req.status[0].toUpperCase() +
                          req.status.substring(1).toLowerCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
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

    // Find rate for selected type (to show in confirm dialog)
    final state = context.read<CatalogBloc>().state;
    final rule = state.pointsRules.firstWhere(
      (r) =>
          r['recognition_type'] == 'CONVERSION' &&
          r['conversion_reward_type'] == _selectedConversionType,
      orElse: () => {},
    );
    final double currentRate = (rule['conversion_rate'] != null)
        ? double.parse(rule['conversion_rate'].toString())
        : 0.1;
    final cashValue = pts * currentRate;

    final balance = context.read<PointsBloc>().state.summary?.balance ?? 0;
    if (balance < pts) {
      _showInsufficientPointsDialog(
          context, "Insufficient points. Balance: $balance, Requested: $pts");
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Confirm Conversion',
        maxWidth: 400,
        showCloseButton: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to convert $pts points?',
              style: AppTextStyles.bodyBold(),
            ),
            const SizedBox(height: 12),
            Text(
              'You will receive ₹${cashValue.toStringAsFixed(2)} to your ${_selectedConversionType.toLowerCase()} account.',
              style: AppTextStyles.body(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 20, color: Colors.amber.shade800),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'This request will be sent to HR for approval.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CatalogBloc>().add(SubmitConversionRequested(
                    points: pts,
                    type: _selectedConversionType,
                  ));
              _pointsController.clear();
              Navigator.pop(dialogContext);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTabSliver(BuildContext context) {
    switch (_currentTabIndex) {
      case 0:
        return _buildCatalogTabSliver(context);
      case 1:
        return _buildHistoryTabSliver(context);
      case 2:
        return _buildConversionTabSliver(context);
      default:
        return const SliverToBoxAdapter(child: SizedBox());
    }
  }

  Widget _buildHistoryTabSliver(BuildContext context) {
    return BlocBuilder<CatalogBloc, CatalogState>(
      builder: (context, state) {
        if (state.status == CatalogStatus.loading &&
            state.redemptions.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final redemptions = state.redemptions;

        if (redemptions.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyStateView(
              icon: Icons.history_edu_rounded,
              title: 'No Redemptions Yet',
              message:
                  'Your redemption history will appear here once you redeem a reward.',
            ),
          );
        }

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header — outside the table card
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded,
                        size: 18, color: Color(0xFF3B31A5)),
                    const SizedBox(width: 8),
                    const Text(
                      'Redemption History',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table header
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Item',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Date Redeemed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Points Spent',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Status',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    // Table rows
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: redemptions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      itemBuilder: (context, index) {
                        final r = redemptions[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  r.rewardName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  AppDateFormatter.short(r.createdAt),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF757575),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${r.pointsSpent}',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: StatusBadge(status: r.status),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConversionTabSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: _buildConversionTab(context),
    );
  }

  Widget _buildCatalogTabSliver(BuildContext context) {
    return BlocBuilder<CatalogBloc, CatalogState>(
      builder: (context, catalogState) {
        const _validCategories = [
          'All',
          'Gift Cards',
          'Merchandise',
        ];
        final effectiveCategory = _validCategories.contains(_selectedCategory)
            ? _selectedCategory
            : 'All';

        final items = catalogState.items.where((item) {
          final query = _searchController.text.toLowerCase();
          final matchesSearch = item.name.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query);
          final matchesCategory = effectiveCategory == 'All' ||
              item.category.toUpperCase() ==
                  (_categoryMap[effectiveCategory] ??
                      effectiveCategory.toUpperCase());
          return matchesSearch && matchesCategory;
        }).toList();

        final balance = context.read<PointsBloc>().state.summary?.balance ?? 0;

        return SliverMainAxisGroup(
          slivers: [
            // ── Category chips + search + filter — single row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    // Category chip pills on the left
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _validCategories.map((cat) {
                            final isActive = effectiveCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedCategory = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFF3B31A5)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isActive
                                          ? const Color(0xFF3B31A5)
                                          : const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFF757575),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Search field — fixed width on the right
                    SizedBox(
                      width: 200,
                      height: 42,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search rewards...',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13),
                          prefixIcon: Icon(Icons.search,
                              color: Colors.grey.shade400, size: 18),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFF3B31A5), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filter icon button
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: const Icon(Icons.tune_rounded,
                          color: Color(0xFF757575), size: 18),
                    ),
                  ],
                ),
              ),
            ),
            if (catalogState.status == CatalogStatus.loading &&
                catalogState.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (catalogState.status == CatalogStatus.failure &&
                catalogState.items.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(
                        catalogState.errorMessage ?? 'Failed to load catalog',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context
                            .read<CatalogBloc>()
                            .add(GetCatalogItemsRequested()),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (items.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyStateView(
                  icon: Icons.search_off_rounded,
                  title: 'No rewards found',
                  message: 'Try adjusting your search or filters.',
                ),
              )
            else
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final reward = items[index];
                    return RewardItemCard(
                      reward: reward,
                      hasInsufficientPoints: balance < reward.pointsCost,
                      onRedeem: () {
                        _showRedemptionConfirm(context, reward);
                      },
                    );
                  },
                  childCount: items.length,
                ),
              ),
          ],
        );
      },
    );
  }

  void _showRedemptionConfirm(BuildContext context, RewardEntity reward) {
    showDialog(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Confirm Redemption',
        maxWidth: 400,
        showCloseButton: false,
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
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _ConversionStep extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Color color;
  const _ConversionStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
