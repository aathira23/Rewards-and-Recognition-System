import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../injection_container.dart';
import '../../../budgets/presentation/bloc/budget_bloc.dart';
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

  // History filters
  DateTime? _startDate;
  DateTime? _endDate;
  String? _category; // null = all, 'received', 'spent', 'pending', 'expired'
  int _page = 1;
  static const _perPage = 20;

  @override
  void initState() {
    super.initState();
    _bloc = sl<PointsBloc>();
    _refreshAll();
  }

  void _refreshAll() {
    _bloc.add(GetPointsSummaryRequested());
    _fetchHistory(page: 1);
    _bloc.add(GetLeaderboardRequested(period: _currentPeriod));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _fetchHistory({int page = 1}) {
    setState(() => _page = page);
    _bloc.add(GetPointsHistoryRequested(
      page: page,
      category: _category,
      startDate: AppDateFormatter.api(_startDate),
      endDate: AppDateFormatter.api(_endDate),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _bloc),
        BlocProvider(create: (_) => sl<BudgetBloc>()),
      ],
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: BlocBuilder<PointsBloc, PointsState>(
          builder: (context, state) {
            if (state.status == PointsStatus.loading &&
                state.summary == null &&
                state.leaderboard.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () async => _refreshAll(),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(Responsive.pagePadding(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppPageHeader(
                      title: 'Points Overview',
                      subtitle: 'Track your earnings and influence',
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 768;

                        final leftColumn = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (state.summary != null) ...[
                              PointsSummaryCard(
                                summary: state.summary!,
                                userRole: widget.userRole,
                              ),
                              const SizedBox(height: 28),
                            ],
                            _buildHistorySection(state),
                          ],
                        );

                        final rightColumn = LeaderboardPanel(
                          entries: state.leaderboard,
                          currentPeriod: _currentPeriod,
                          isLoading: state.status == PointsStatus.loading &&
                              state.leaderboard.isEmpty,
                          onPeriodChanged: (period) {
                            setState(() => _currentPeriod = period);
                            _bloc.add(GetLeaderboardRequested(period: period));
                          },
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 65, child: leftColumn),
                              const SizedBox(width: 24),
                              Expanded(flex: 35, child: rightColumn),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            leftColumn,
                            const SizedBox(height: 24),
                            rightColumn,
                          ],
                        );
                      },
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

  // ─── History section ────────────────────────────────────────────
  Widget _buildHistorySection(PointsState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterBar(),
          const Divider(height: 1),
          _buildTableHeader(),
          const Divider(height: 1),
          if (state.status == PointsStatus.loading && state.history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.history.isEmpty)
            const EmptyStateView(
              icon: Icons.history_rounded,
              title: 'No transactions found',
              padding: 48,
            )
          else
            ...state.history.asMap().entries.map(
                (e) => _buildRow(e.value, e.key == state.history.length - 1)),
          _buildFooter(state),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final mobile = Responsive.isMobile(context);

    final filters = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // From date
        _DateChip(
          label: _startDate != null
              ? AppDateFormatter.short(_startDate)
              : 'mm/dd/yyyy',
          isSet: _startDate != null,
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _startDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (d != null) {
              setState(() => _startDate = d);
              _fetchHistory();
            }
          },
          onClear: _startDate != null
              ? () {
                  setState(() => _startDate = null);
                  _fetchHistory();
                }
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('to',
              style: AppTextStyles.small(color: Colors.grey.shade500)),
        ),
        // To date
        _DateChip(
          label: _endDate != null
              ? AppDateFormatter.short(_endDate)
              : 'mm/dd/yyyy',
          isSet: _endDate != null,
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _endDate ?? DateTime.now(),
              firstDate: _startDate ?? DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (d != null) {
              setState(() => _endDate = d);
              _fetchHistory();
            }
          },
          onClear: _endDate != null
              ? () {
                  setState(() => _endDate = null);
                  _fetchHistory();
                }
              : null,
        ),
        // Type dropdown
        _TypeDropdown(
          value: _category,
          onChanged: (v) {
            setState(() => _category = v);
            _fetchHistory();
          },
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Points History', style: AppTextStyles.sectionTitle()),
                const SizedBox(height: 12),
                filters,
              ],
            )
          : Row(
              children: [
                Text('Points History', style: AppTextStyles.sectionTitle()),
                const Spacer(),
                filters,
              ],
            ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.grey.shade50,
      child: _buildTableRowLayout(
        children: [
          _hdr('DATE'),
          _hdr('DESCRIPTION'),
          _hdr('TYPE'),
          _hdr('POINTS'),
        ],
      ),
    );
  }

  /// Shared flex-based row layout for table header & data rows.
  Widget _buildTableRowLayout({required List<Widget> children}) {
    return Row(
      children: [
        Expanded(flex: 2, child: children[0]),
        Expanded(flex: 4, child: children[1]),
        Expanded(flex: 2, child: children[2]),
        Expanded(flex: 2, child: children[3]),
        const SizedBox(width: 28),
      ],
    );
  }

  Widget _hdr(String label) => Text(
        label,
        style: AppTextStyles.captionStrong(
          color: Colors.grey.shade500,
        ),
      );

  Widget _buildRow(PointTransactionEntity tx, bool isLast) {
    final isCredit = tx.points.startsWith('+');
    final ptColor =
        isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              AppDateFormatter.format(tx.date),
              style: AppTextStyles.smallMedium(),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              tx.description,
              style: AppTextStyles.bodyBold(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(status: tx.type),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              tx.points,
              style: AppTextStyles.bodyBold(
                color: ptColor,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: PopupMenuButton<String>(
              icon:
                  Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'details', child: Text('View Details')),
              ],
              onSelected: (_) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(PointsState state) {
    final total = state.historyTotal;
    final showing = state.history.length;
    final start = (_page - 1) * _perPage + 1;
    final end = start + showing - 1;
    final hasPrev = _page > 1;
    final hasNext = total > 0 && end < total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          if (total > 0)
            Text(
              'Showing $start\u2013$end of $total records',
              style: AppTextStyles.caption(color: Colors.grey.shade500),
            )
          else
            Text(
              '$showing record${showing == 1 ? '' : 's'}',
              style: AppTextStyles.caption(color: Colors.grey.shade500),
            ),
          const Spacer(),
          if (total > _perPage) ...[
            _PageBtn(
              icon: Icons.chevron_left,
              enabled: hasPrev,
              onTap: hasPrev ? () => _fetchHistory(page: _page - 1) : null,
            ),
            const SizedBox(width: 6),
            _PageBtn(
              icon: Icons.chevron_right,
              enabled: hasNext,
              onTap: hasNext ? () => _fetchHistory(page: _page + 1) : null,
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Private widgets
// ═══════════════════════════════════════════════════════════════════

class _DateChip extends StatelessWidget {
  final String label;
  final bool isSet;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _DateChip({
    required this.label,
    required this.isSet,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.small(
                  color: isSet ? Colors.black87 : Colors.grey.shade500),
            ),
            if (isSet && onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 13, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _TypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          style: AppTextStyles.small(color: Colors.black87),
          icon: Icon(Icons.keyboard_arrow_down,
              size: 16, color: Colors.grey.shade500),
          items: const [
            DropdownMenuItem(value: null, child: Text('All Types')),
            DropdownMenuItem(value: 'received', child: Text('Earned')),
            DropdownMenuItem(value: 'spent', child: Text('Redeemed')),
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(value: 'expired', child: Text('Expired')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  const _PageBtn({required this.icon, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
    );
  }
}
