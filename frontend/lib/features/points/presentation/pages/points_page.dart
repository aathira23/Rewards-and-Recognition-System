import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import 'package:rr_frontend/core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/constants/api_constants.dart';
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
  static const _perPage = kDefaultPageSize;

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
      perPage: kDefaultPageSize,
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
    final listHeight = Responsive.isMobile(context) ? 360.0 : 400.0;
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
          // Fixed-height scrollable area for the history rows to avoid
          // layout shifts when content changes.
          SizedBox(
            height: listHeight,
            child: Builder(builder: (context) {
              if (state.status == PointsStatus.loading &&
                  state.history.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.history.isEmpty) {
                return const Center(
                  child: EmptyStateView(
                    icon: Icons.history_rounded,
                    title: 'No transactions found',
                    padding: 48,
                  ),
                );
              }

              // Render rows inside a ListView so the outer layout stays
              // constant while the user scrolls through entries.
              final visible = _visibleHistory(state.history);
              return ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox.shrink(),
                itemBuilder: (ctx, idx) {
                  final isLast = idx == visible.length - 1;
                  return _buildRow(visible[idx], isLast);
                },
              );
            }),
          ),
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
      alignment: WrapAlignment.end,
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
                const SizedBox(width: 16),
                Expanded(child: filters),
              ],
            ),
    );
  }

  // Return history entries visible to the user. Hide "Expired" entries
  // scheduled for the future so the history only shows expiries after
  // they've actually taken effect.
  List<PointTransactionEntity> _visibleHistory(
      List<PointTransactionEntity> history) {
    final now = DateTime.now();
    return history.where((tx) {
      if (tx.type.toLowerCase() == 'expired') {
        // Prefer a full ISO timestamp when available
        final parsed = AppDateFormatter.parse(tx.createdAtFull ?? tx.date);
        if (parsed == null) return true; // can't determine, keep it
        return !parsed.isAfter(now);
      }
      return true;
    }).toList();
  }

  Widget _buildTableHeader() {
    final mobile = Responsive.isMobile(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(flex: mobile ? 3 : 2, child: _hdr('DATE')),
          Expanded(flex: mobile ? 5 : 4, child: _hdr('DESCRIPTION')),
          if (!mobile) Expanded(flex: 2, child: _hdr('TYPE')),
          Expanded(flex: 2, child: _hdr('POINTS')),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _hdr(String label) => Text(
        label,
        style: AppTextStyles.captionStrong(
          color: Colors.grey.shade500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

  Widget _buildRow(PointTransactionEntity tx, bool isLast) {
    final isCredit = tx.points.startsWith('+');
    final ptColor =
        isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final mobile = Responsive.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: mobile ? 3 : 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                AppDateFormatter.format(tx.date),
                style: AppTextStyles.smallMedium(),
              ),
            ),
          ),
          Expanded(
            flex: mobile ? 5 : 4,
            child: mobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tx.description,
                        style: AppTextStyles.bodyBold(),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(status: tx.type),
                    ],
                  )
                : Text(
                    tx.description,
                    style: AppTextStyles.bodyBold(),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          if (!mobile)
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
            width: 44,
            child: _ViewLink(
              onTap: () => _showTransactionDetails(tx),
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
          Expanded(
            child: total > 0
                ? Text(
                    'Showing $start\u2013$end of $total records',
                    style: AppTextStyles.caption(color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(
                    '$showing record${showing == 1 ? '' : 's'}',
                    style: AppTextStyles.caption(color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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

  void _showTransactionDetails(PointTransactionEntity tx) {
    final isCredit = tx.points.startsWith('+');
    final ptColor =
        isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Transaction Details',
        maxWidth: 460,
        showCloseButton: false,
        content: Column(
          children: [
            // Header with amount
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ptColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ptColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tx.points,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: ptColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Points',
                    style: AppTextStyles.bodyBold(
                        color: ptColor.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details list
            _detailRow('Description', tx.description, isLarge: true),
            _detailRow('Status', tx.type, isBadge: true),
            _detailRow('Date', tx.date),
            if (tx.createdAtFull != null)
              _detailRow(
                  'Time', AppDateFormatter.formatTime(tx.createdAtFull!)),
            _detailRow('Reference', tx.referenceType ?? 'GENERAL'),
            _detailRow('Transaction ID', tx.id.toString()),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {bool isBadge = false, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment:
            isLarge ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.caption(color: Colors.grey.shade500),
            ),
          ),
          Expanded(
            child: isBadge
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(status: value),
                  )
                : Text(
                    value,
                    style: isLarge
                        ? AppTextStyles.bodyBold()
                        : AppTextStyles.bodyMedium(),
                  ),
          ),
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
    return DropdownMenu<String?>(
      initialSelection: value,
      width: 140,
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        constraints: const BoxConstraints(maxHeight: 34),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      textStyle: AppTextStyles.small(color: Colors.black87),
      trailingIcon: Icon(Icons.keyboard_arrow_down,
          size: 16, color: Colors.grey.shade500),
      dropdownMenuEntries: const [
        DropdownMenuEntry(value: null, label: 'All Types'),
        DropdownMenuEntry(value: 'received', label: 'Earned'),
        DropdownMenuEntry(value: 'spent', label: 'Redeemed'),
        DropdownMenuEntry(value: 'pending', label: 'Pending'),
        DropdownMenuEntry(value: 'expired', label: 'Expired'),
      ],
      onSelected: onChanged,
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

class _ViewLink extends StatefulWidget {
  final VoidCallback onTap;
  const _ViewLink({required this.onTap});

  @override
  State<_ViewLink> createState() => _ViewLinkState();
}

class _ViewLinkState extends State<_ViewLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          'View',
          style: TextStyle(
            color: AppTheme.brandBlue,
            fontSize: 13,
            fontWeight: _isHovered ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
