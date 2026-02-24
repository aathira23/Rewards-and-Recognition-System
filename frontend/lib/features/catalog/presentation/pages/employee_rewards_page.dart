import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../injection_container.dart';
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
                    vertical: Responsive.pagePadding(context) + 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
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
  String _selectedCategory = 'All Categories';

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

        // Status helpers for recent requests
        Color _statusColor(String s) {
          if (s == 'APPROVED' || s == 'COMPLETED') return Colors.green;
          if (s == 'REJECTED' || s == 'CANCELLED') return Colors.red;
          return Colors.orange;
        }

        IconData _statusIcon(String s) {
          if (s == 'APPROVED' || s == 'COMPLETED')
            return Icons.check_circle_rounded;
          if (s == 'REJECTED' || s == 'CANCELLED') return Icons.cancel_rounded;
          return Icons.schedule_rounded;
        }

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
                      color: const Color(0xFF3B5BDB).withValues(alpha: 0.06),
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
                        gradient: LinearGradient(
                          colors: [Color(0xFF3B5BDB), Color(0xFF6741D9)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
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
                                  color: Color(0xFF3B5BDB)),
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
                                    color: Color(0xFF3B5BDB), width: 1.5),
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
                                          ? const Color(0xFF3B5BDB)
                                          : const Color(0xFFF7F8FD),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isPayroll
                                            ? const Color(0xFF3B5BDB)
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
                                          ? const Color(0xFF3B5BDB)
                                          : const Color(0xFFF7F8FD),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: !isPayroll
                                            ? const Color(0xFF3B5BDB)
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
                                backgroundColor: const Color(0xFF3B5BDB),
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
                      color: const Color(0xFF3B5BDB),
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
                                const Color(0xFF3B5BDB).withValues(alpha: 0.08),
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
                    Expanded(flex: 3, child: formCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: infoPanel),
                  ],
                );
              }
              return Column(
                  children: [formCard, const SizedBox(height: 16), infoPanel]);
            }),

            const SizedBox(height: 32),
            // ── Recent Requests ──
            const Text(
              'Recent Requests',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            state.conversions.isEmpty
                ? const EmptyStateView(
                    icon: Icons.history_rounded,
                    title: 'No conversion history',
                    message: 'Your point conversion requests will appear here.',
                    padding: 40,
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.conversions.length,
                    itemBuilder: (context, index) {
                      final req = state.conversions[index];
                      final sc = _statusColor(req.status);
                      final si = _statusIcon(req.status);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEEEFF5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: sc.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(si, color: sc, size: 18),
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
                                        fontSize: 12,
                                        color: Colors.grey.shade500),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: sc.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    req.status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: sc,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
            state.redemptions.isEmpty &&
            state.conversions.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final redemptions = state.redemptions;
        final conversions = state.conversions;

        if (redemptions.isEmpty && conversions.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyStateView(
              icon: Icons.history_edu_rounded,
              title: 'No Activities Yet',
              message:
                  'Your redemption and conversion history will appear here once you perform actions.',
            ),
          );
        }

        // Merge and sort
        final allActivities = [
          ...redemptions.map((e) => _HistoryItem(
                title: e.rewardName,
                subtitle: e.rewardCategory,
                points: e.pointsSpent,
                date: e.createdAt,
                status: e.status,
                isConversion: false,
              )),
          ...conversions.map((e) => _HistoryItem(
                title: '${e.pointsConverted} Points converted',
                subtitle: 'To ${e.conversionType}',
                points: e.pointsConverted,
                date: e.createdAt,
                status: e.status,
                isConversion: true,
                cashAmount: e.cashAmount,
              )),
        ];
        allActivities.sort((a, b) => b.date.compareTo(a.date));

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = allActivities[index];
              final isLast = index == allActivities.length - 1;
              return Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.1)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (item.isConversion
                              ? Colors.green
                              : Theme.of(context).colorScheme.primary)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.isConversion
                          ? Icons.currency_exchange_rounded
                          : Icons.shopping_bag_rounded,
                      color: item.isConversion
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(item.title, style: AppTextStyles.bodyBold()),
                  subtitle: Text(
                    '${item.subtitle} • ${AppDateFormatter.short(item.date)}',
                    style:
                        AppTextStyles.small(color: Theme.of(context).hintColor),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '-${item.points} pts',
                        style: AppTextStyles.sectionTitle(
                          color: item.isConversion
                              ? Colors.green
                              : Colors.redAccent,
                        ),
                      ),
                      StatusBadge(status: item.status),
                    ],
                  ),
                ),
              );
            },
            childCount: allActivities.length,
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
    final theme = Theme.of(context);
    return BlocBuilder<CatalogBloc, CatalogState>(
      builder: (context, catalogState) {
        // Normalize in case state holds a stale value no longer in the list
        const _validCategories = [
          'All Categories',
          'Gift Cards',
          'Merchandise'
        ];
        final effectiveCategory = _validCategories.contains(_selectedCategory)
            ? _selectedCategory
            : 'All Categories';

        final items = catalogState.items.where((item) {
          final query = _searchController.text.toLowerCase();
          final matchesSearch = item.name.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query);
          final matchesCategory = effectiveCategory == 'All Categories' ||
              item.category.toUpperCase() ==
                  (_categoryMap[effectiveCategory] ??
                      effectiveCategory.toUpperCase());
          return matchesSearch && matchesCategory;
        }).toList();

        final balance = context.read<PointsBloc>().state.summary?.balance ?? 0;

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 500;
                    final searchField = TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search rewards...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        fillColor: theme.colorScheme.surface,
                      ),
                    );
                    Widget buildDropdown({required bool expanded}) =>
                        DropdownMenu<String>(
                          initialSelection: const [
                            'All Categories',
                            'Gift Cards',
                            'Merchandise'
                          ].contains(_selectedCategory)
                              ? _selectedCategory
                              : 'All Categories',
                          expandedInsets: expanded ? EdgeInsets.zero : null,
                          width: expanded ? null : 200,
                          inputDecorationTheme: InputDecorationTheme(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: theme.dividerColor
                                      .withValues(alpha: 0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: theme.dividerColor
                                      .withValues(alpha: 0.1)),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          textStyle: theme.textTheme.bodyMedium,
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(
                                value: 'All Categories',
                                label: 'All Categories'),
                            DropdownMenuEntry(
                                value: 'Gift Cards', label: 'Gift Cards'),
                            DropdownMenuEntry(
                                value: 'Merchandise', label: 'Merchandise'),
                          ],
                          onSelected: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                        );

                    if (narrow) {
                      return Column(
                        children: [
                          searchField,
                          const SizedBox(height: 12),
                          buildDropdown(expanded: true),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 16),
                        buildDropdown(expanded: false),
                      ],
                    );
                  },
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
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.7,
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

class _HistoryItem {
  final String title;
  final String subtitle;
  final int points;
  final DateTime date;
  final String status;
  final bool isConversion;
  final double? cashAmount;

  _HistoryItem({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.date,
    required this.status,
    required this.isConversion,
    this.cashAmount,
  });
}
