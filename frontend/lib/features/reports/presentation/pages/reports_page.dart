import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../../injection_container.dart';
import '../bloc/reports_bloc.dart';
import '../bloc/reports_event.dart';
import '../bloc/reports_state.dart';

// ═══════════════════════════════════════════════════════════════════════
//  REPORT DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════

class _ColDef {
  final String key;
  final String label;
  final int flex;
  const _ColDef(this.key, this.label, {this.flex = 1});
}

enum _ReportType {
  recognitions(
    backendType: 'RECOGNITIONS',
    title: 'Recognition & Awards',
    subtitle:
        'Complete history of peer recognitions, ecards, manager rewards and formal awards with sender/receiver details, points and messages',
    icon: Icons.emoji_events_rounded,
    color: Color(0xFF2D2A70),
    hasDateFilter: true,
    hasDeptFilter: true,
    columns: [
      _ColDef('created_at', 'Date', flex: 2),
      _ColDef('actor_name', 'Sender', flex: 2),
      _ColDef('receiver_name', 'Receiver', flex: 2),
      _ColDef('source_type', 'Type', flex: 2),
      _ColDef('points', 'Points', flex: 1),
      _ColDef('message', 'Message', flex: 3),
    ],
  ),
  redemptions(
    backendType: 'REDEMPTIONS',
    title: 'Redemptions & Rewards',
    subtitle:
        'Track every reward redemption \u2014 who redeemed what, points spent, fulfillment status and timestamps',
    icon: Icons.card_giftcard_rounded,
    color: Color(0xFF10B981),
    hasDateFilter: true,
    hasDeptFilter: false,
    columns: [
      _ColDef('created_at', 'Date', flex: 2),
      _ColDef('user_name', 'Employee', flex: 3),
      _ColDef('reward_name', 'Reward', flex: 3),
      _ColDef('points_used', 'Points Used', flex: 1),
      _ColDef('status', 'Status', flex: 2),
    ],
  ),
  walletUtilization(
    backendType: 'WALLET_UTILIZATION',
    title: 'Budget & Wallet Utilization',
    subtitle:
        'Manager-level budget snapshot \u2014 total allocated, spent, remaining balance and utilization percentage',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF8B5CF6),
    hasDateFilter: false,
    hasDeptFilter: false,
    columns: [
      _ColDef('manager_name', 'Manager', flex: 3),
      _ColDef('total_allocated', 'Total Allocated', flex: 2),
      _ColDef('total_spent', 'Total Spent', flex: 2),
      _ColDef('remaining_balance', 'Remaining', flex: 2),
      _ColDef('utilization_pct', 'Utilization %', flex: 2),
    ],
  ),
  expiryForecast(
    backendType: 'EXPIRY_FORECAST',
    title: 'Points Expiry Forecast',
    subtitle:
        'Forecast of employee points expiring in a selected window \u2014 dates, amounts and number of affected users',
    icon: Icons.timer_outlined,
    color: Color(0xFFEF4444),
    hasDateFilter: false,
    hasDeptFilter: false,
    columns: [
      _ColDef('expiry_date', 'Expiry Date', flex: 2),
      _ColDef('total_points', 'Points Expiring', flex: 2),
      _ColDef('user_count', 'Users Affected', flex: 2),
      _ColDef('days_remaining', 'Days Left', flex: 2),
    ],
  ),
  payrollEncashment(
    backendType: 'PAYROLL',
    title: 'Payroll Encashment',
    subtitle:
        'Monthly points-to-cash conversion report \u2014 employee, points converted, cash value, approval status',
    icon: Icons.payments_rounded,
    color: Color(0xFF6366F1),
    hasDateFilter: false,
    hasDeptFilter: false,
    columns: [
      _ColDef('user_name', 'Employee', flex: 3),
      _ColDef('points_converted', 'Points', flex: 2),
      _ColDef('cash_amount', 'Cash Amount', flex: 2),
      _ColDef('status', 'Status', flex: 2),
      _ColDef('approved_at', 'Approved', flex: 2),
    ],
  );

  final String backendType;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool hasDateFilter;
  final bool hasDeptFilter;
  final List<_ColDef> columns;
  const _ReportType({
    required this.backendType,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.hasDateFilter,
    required this.hasDeptFilter,
    required this.columns,
  });
}

// ═══════════════════════════════════════════════════════════════════════
//  PAGE
// ═══════════════════════════════════════════════════════════════════════

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReportsBloc>(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  _ReportType? _active;

  // Filters (local UI state)
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _deptId;
  String _payrollMonth = '';
  int _expiryDays = 30;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _payrollMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // ── fetch report data ────────────────────────────────────────────
  void _fetchReport(_ReportType type) {
    setState(() => _active = type);

    // Load departments if needed (lazy, one-time)
    if (type.hasDeptFilter) {
      final bloc = context.read<ReportsBloc>();
      if (bloc.state.departments.isEmpty) {
        bloc.add(const LoadDepartmentsForFilter());
      }
    }

    context
        .read<ReportsBloc>()
        .add(LoadReport(queryParams: _buildQueryParams(type)));
  }

  Map<String, dynamic> _buildQueryParams(_ReportType type) {
    final qp = <String, dynamic>{'report_type': type.backendType};
    if (type.hasDateFilter && _fromDate != null) {
      qp['from_date'] = AppDateFormatter.api(_fromDate);
    }
    if (type.hasDateFilter && _toDate != null) {
      qp['to_date'] = AppDateFormatter.api(_toDate);
    }
    if (type.hasDeptFilter && _deptId != null) {
      qp['department_id'] = _deptId;
    }
    if (type == _ReportType.expiryForecast) {
      qp['days'] = _expiryDays;
    }
    if (type == _ReportType.payrollEncashment) {
      qp['month'] = _payrollMonth;
    }
    return qp;
  }

  void _exportCsv() {
    if (_active == null) return;
    context
        .read<ReportsBloc>()
        .add(ExportReportCsv(queryParams: _buildQueryParams(_active!)));
  }

  /// Add computed columns for display (utilization %, days remaining).
  List<Map<String, dynamic>> _processData(
      List<Map<String, dynamic>> raw, _ReportType type) {
    if (type != _ReportType.walletUtilization &&
        type != _ReportType.expiryForecast) {
      return raw;
    }
    return raw.map((row) {
      final r = Map<String, dynamic>.from(row);
      if (type == _ReportType.walletUtilization) {
        final alloc = (r['total_allocated'] ?? 0) as num;
        final spent = (r['total_spent'] ?? 0) as num;
        r['utilization_pct'] =
            alloc > 0 ? ((spent / alloc) * 100).toStringAsFixed(1) : '0.0';
      }
      if (type == _ReportType.expiryForecast && r['expiry_date'] != null) {
        final expiry = DateTime.tryParse(r['expiry_date'].toString());
        if (expiry != null) {
          r['days_remaining'] =
              expiry.difference(DateTime.now()).inDays.clamp(0, 9999);
        }
      }
      return r;
    }).toList();
  }

  void _goBack() => setState(() => _active = null);

  // ── build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportsBloc, ReportsState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.successMessage!),
            behavior: SnackBarBehavior.floating,
          ));
        }

        // Trigger CSV download if data available
        if (state.exportData != null && state.exportFileName != null) {
          FileDownloadHelper.download(
            bytes: state.exportData!,
            fileName: state.exportFileName!,
          );
          // Clear so it doesn't trigger again on unrelated state changes
          context.read<ReportsBloc>().add(const ClearExportData());
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
          body: _active == null ? _buildGrid() : _buildDetail(state),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  GRID
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildGrid() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.pagePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            // desktop ≥1100 → 3 cols, tablet ≥600 → 2 cols, mobile → 1 col
            final cols = w >= 1100 ? 3 : (w >= 600 ? 2 : 1);
            final spacing = 20.0;
            final cardWidth = (w - spacing * (cols - 1)) / cols;
            return Wrap(
              spacing: spacing,
              runSpacing: 20,
              children: _ReportType.values.map((t) {
                return SizedBox(
                  width: cardWidth.clamp(260, 600),
                  child: _ReportCard(type: t, onTap: () => _fetchReport(t)),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DETAIL VIEW
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildDetail(ReportsState state) {
    final type = _active!;
    final data = _processData(state.data, type);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.pagePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── breadcrumb ──
          Row(
            children: [
              InkWell(
                onTap: _goBack,
                borderRadius: BorderRadius.circular(6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.arrow_back_rounded,
                      size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text('Reports',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('/',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade400)),
              ),
              Text(type.title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),

          // ── title + actions ──
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 600;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: type.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(type.icon, color: type.color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(type.title,
                                style: AppTextStyles.sectionHeader()),
                            const SizedBox(height: 2),
                            Text(type.subtitle,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      if (!narrow) ...[
                        OutlinedButton.icon(
                          onPressed: () => _fetchReport(type),
                          icon: const Icon(Icons.refresh_rounded, size: 15),
                          label: const Text('Refresh'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: data.isNotEmpty ? _exportCsv : null,
                          icon: const Icon(Icons.download_rounded, size: 15),
                          label: const Text('Export CSV'),
                        ),
                      ],
                    ],
                  ),
                  if (narrow) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _fetchReport(type),
                            icon: const Icon(Icons.refresh_rounded, size: 15),
                            label: const Text('Refresh'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: data.isNotEmpty ? _exportCsv : null,
                            icon: const Icon(Icons.download_rounded, size: 15),
                            label: const Text('Export CSV'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ── filters ──
          _buildFilters(type, state, data, theme),

          // ── summary cards ──
          if (!state.isLoading && data.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSummary(type, data, theme),
          ],

          const SizedBox(height: 20),

          // ── content ──
          if (state.isLoading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(60),
                    child: CircularProgressIndicator())),
          if (state.error != null)
            EmptyStateView(
              icon: Icons.error_outline_rounded,
              title: 'Failed to load report',
              message: state.error!,
              onRetry: () => _fetchReport(type),
            ),
          if (!state.isLoading && state.error == null && data.isEmpty)
            const EmptyStateView(
              icon: Icons.inbox_rounded,
              title: 'No records found',
              message: 'Try adjusting your filters to see more results.',
            ),
          if (!state.isLoading && data.isNotEmpty)
            _buildTable(type, data, theme),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  FILTERS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFilters(_ReportType type, ReportsState state,
      List<Map<String, dynamic>> data, ThemeData theme) {
    if (!type.hasDateFilter &&
        !type.hasDeptFilter &&
        type != _ReportType.payrollEncashment &&
        type != _ReportType.expiryForecast) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.filter_list_rounded,
              size: 18, color: Colors.grey.shade500),

          // Date range
          if (type.hasDateFilter) ...[
            _FilterChip(
              label: _fromDate != null
                  ? AppDateFormatter.short(_fromDate)
                  : 'From Date',
              icon: Icons.calendar_today,
              isSet: _fromDate != null,
              onTap: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: _fromDate ??
                        DateTime.now().subtract(const Duration(days: 30)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now());
                if (d != null) {
                  setState(() => _fromDate = d);
                  _fetchReport(type);
                }
              },
              onClear: _fromDate != null
                  ? () {
                      setState(() => _fromDate = null);
                      _fetchReport(type);
                    }
                  : null,
            ),
            const SizedBox(width: 8),
            Text('\u2192', style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(width: 8),
            _FilterChip(
              label:
                  _toDate != null ? AppDateFormatter.short(_toDate) : 'To Date',
              icon: Icons.calendar_today,
              isSet: _toDate != null,
              onTap: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: _toDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now());
                if (d != null) {
                  setState(() => _toDate = d);
                  _fetchReport(type);
                }
              },
              onClear: _toDate != null
                  ? () {
                      setState(() => _toDate = null);
                      _fetchReport(type);
                    }
                  : null,
            ),
          ],

          // Department filter
          if (type.hasDeptFilter && state.departments.isNotEmpty) ...[
            DropdownMenu<int?>(
              initialSelection: _deptId,
              width: 180,
              inputDecorationTheme: InputDecorationTheme(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _deptId != null
                        ? Colors.blue.shade200
                        : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _deptId != null
                        ? Colors.blue.shade200
                        : Colors.grey.shade300,
                  ),
                ),
                filled: true,
                fillColor:
                    _deptId != null ? Colors.blue.shade50 : Colors.grey.shade50,
              ),
              textStyle: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              label: Text('All Departments', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              dropdownMenuEntries: [
                const DropdownMenuEntry(value: null, label: 'All Departments'),
                ...state.departments.map((d) => DropdownMenuEntry(
                    value: d['id'] as int?,
                    label: d['name']?.toString() ?? '')),
              ],
              onSelected: (v) {
                setState(() => _deptId = v);
                _fetchReport(type);
              },
            ),
          ],

          // Expiry forecast days selector
          if (type == _ReportType.expiryForecast) ...[
            Text('Expiring within:',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600)),
            const SizedBox(width: 8),
            ...[7, 14, 30, 60, 90, 360].map((d) {
              final sel = _expiryDays == d;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () {
                    setState(() => _expiryDays = d);
                    _fetchReport(type);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          sel ? const Color(0xFF2D2A70) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? const Color(0xFF2D2A70)
                              : Colors.grey.shade300),
                    ),
                    child: Text('${d}d',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : Colors.grey.shade700)),
                  ),
                ),
              );
            }),
          ],

          // Payroll month picker
          if (type == _ReportType.payrollEncashment) ...[
            _FilterChip(
              label: AppDateFormatter.monthYear(
                  DateTime.tryParse('$_payrollMonth-01')),
              icon: Icons.date_range_rounded,
              isSet: true,
              onTap: () async {
                final parts = _payrollMonth.split('-');
                final yr = int.parse(parts[0]);
                final mo = int.parse(parts[1]);
                final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime(yr, mo),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now());
                if (d != null) {
                  setState(() => _payrollMonth =
                      '${d.year}-${d.month.toString().padLeft(2, '0')}');
                  _fetchReport(type);
                }
              },
            ),
          ],

          Text('${data.length} records',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SUMMARY STAT CARDS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSummary(
      _ReportType type, List<Map<String, dynamic>> data, ThemeData theme) {
    final stats = _computeStats(type, data);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        if (isMobile) {
          // 2-column grid on mobile
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: stats
                .map((s) => SizedBox(
                      width: (constraints.maxWidth - 12) / 2,
                      child: _buildStatCard(s, theme),
                    ))
                .toList(),
          );
        }
        return Row(
          children: stats
              .map((s) => Expanded(
                      child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: _buildStatCard(s, theme),
                  )))
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard(_Stat s, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(s.icon, size: 16, color: s.color),
          ),
          const SizedBox(height: 10),
          Text(s.value, style: AppTextStyles.headline2()),
          const SizedBox(height: 3),
          Text(s.label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  List<_Stat> _computeStats(_ReportType type, List<Map<String, dynamic>> data) {
    switch (type) {
      case _ReportType.recognitions:
        return _recognitionStats(data);
      case _ReportType.redemptions:
        return _redemptionStats(data);
      case _ReportType.walletUtilization:
        return _walletStats(data);
      case _ReportType.expiryForecast:
        return _expiryStats(data);
      case _ReportType.payrollEncashment:
        return _payrollStats(data);
    }
  }

  List<_Stat> _recognitionStats(List<Map<String, dynamic>> data) {
    final total = data.length;
    final totalPts =
        data.fold<int>(0, (s, r) => s + ((r['points'] as num?)?.toInt() ?? 0));
    final senders = data.map((r) => r['actor_name']).toSet().length;
    final receivers = data.map((r) => r['receiver_name']).toSet().length;
    final typeCounts = <String, int>{};
    for (final r in data) {
      final t = r['source_type']?.toString() ?? '';
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }
    String topType = '\u2014';
    if (typeCounts.isNotEmpty) {
      topType =
          typeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }
    return [
      _Stat('Total Recognitions', _fmt(total), Icons.receipt_long_rounded,
          const Color(0xFF3B82F6)),
      _Stat('Total Points Awarded', _fmt(totalPts), Icons.stars_rounded,
          const Color(0xFFF59E0B)),
      _Stat('Unique Senders', _fmt(senders), Icons.person_outline,
          const Color(0xFF8B5CF6)),
      _Stat('Unique Receivers', _fmt(receivers), Icons.people_outline_rounded,
          const Color(0xFF10B981)),
      _Stat('Top Activity Type', topType, Icons.category_rounded,
          const Color(0xFFEF4444)),
    ];
  }

  List<_Stat> _redemptionStats(List<Map<String, dynamic>> data) {
    final total = data.length;
    final totalPts = data.fold<int>(
        0, (s, r) => s + ((r['points_used'] as num?)?.toInt() ?? 0));
    final employees = data.map((r) => r['user_name']).toSet().length;
    final fulfilled = data.where((r) => r['status'] == 'FULFILLED').length;
    final rwdCounts = <String, int>{};
    for (final r in data) {
      final rw = r['reward_name']?.toString() ?? '';
      rwdCounts[rw] = (rwdCounts[rw] ?? 0) + 1;
    }
    String topReward = '\u2014';
    if (rwdCounts.isNotEmpty) {
      topReward =
          rwdCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }
    return [
      _Stat('Total Redemptions', _fmt(total), Icons.card_giftcard_rounded,
          const Color(0xFF10B981)),
      _Stat('Points Redeemed', _fmt(totalPts), Icons.stars_rounded,
          const Color(0xFFF59E0B)),
      _Stat('Unique Employees', _fmt(employees), Icons.people_outline_rounded,
          const Color(0xFF3B82F6)),
      _Stat(
          'Fulfillment Rate',
          total > 0
              ? '${((fulfilled / total) * 100).toStringAsFixed(1)}%'
              : '0%',
          Icons.check_circle_outline,
          const Color(0xFF8B5CF6)),
      _Stat('Most Popular', topReward, Icons.trending_up_rounded,
          const Color(0xFFEF4444)),
    ];
  }

  List<_Stat> _walletStats(List<Map<String, dynamic>> data) {
    final count = data.length;
    final totalAlloc = data.fold<int>(
        0, (s, r) => s + ((r['total_allocated'] as num?)?.toInt() ?? 0));
    final totalSpent = data.fold<int>(
        0, (s, r) => s + ((r['total_spent'] as num?)?.toInt() ?? 0));
    final avgUtil = count > 0
        ? data.fold<double>(
                0,
                (s, r) =>
                    s +
                    (double.tryParse(r['utilization_pct']?.toString() ?? '0') ??
                        0)) /
            count
        : 0;
    final totalRemaining = totalAlloc - totalSpent;
    return [
      _Stat('Total Managers', _fmt(count), Icons.manage_accounts_rounded,
          const Color(0xFF8B5CF6)),
      _Stat('Total Budget', '${_fmt(totalAlloc)} pts',
          Icons.account_balance_rounded, const Color(0xFF3B82F6)),
      _Stat('Total Spent', '${_fmt(totalSpent)} pts', Icons.payments_rounded,
          const Color(0xFFEF4444)),
      _Stat('Remaining', '${_fmt(totalRemaining)} pts', Icons.savings_rounded,
          const Color(0xFF10B981)),
      _Stat('Avg Utilization', '${avgUtil.toStringAsFixed(1)}%',
          Icons.speed_rounded, const Color(0xFFF59E0B)),
    ];
  }

  List<_Stat> _expiryStats(List<Map<String, dynamic>> data) {
    final totalPts = data.fold<int>(
        0, (s, r) => s + ((r['total_points'] as num?)?.toInt() ?? 0));
    final totalUsers = data.fold<int>(
        0, (s, r) => s + ((r['user_count'] as num?)?.toInt() ?? 0));
    final dates = data.length;
    int minDays = 999;
    for (final r in data) {
      final d = (r['days_remaining'] as num?)?.toInt() ?? 999;
      if (d < minDays) minDays = d;
    }
    return [
      _Stat('Points at Risk', '${_fmt(totalPts)} pts',
          Icons.warning_amber_rounded, const Color(0xFFEF4444)),
      _Stat('Users Affected', _fmt(totalUsers), Icons.people_outline_rounded,
          const Color(0xFFF59E0B)),
      _Stat('Expiry Dates', _fmt(dates), Icons.event_rounded,
          const Color(0xFF3B82F6)),
      _Stat('Earliest Expiry', minDays < 999 ? '$minDays days' : '\u2014',
          Icons.timer_outlined, const Color(0xFF8B5CF6)),
    ];
  }

  List<_Stat> _payrollStats(List<Map<String, dynamic>> data) {
    final total = data.length;
    final totalPts = data.fold<int>(
        0, (s, r) => s + ((r['points_converted'] as num?)?.toInt() ?? 0));
    final totalCash = data.fold<double>(
        0, (s, r) => s + ((r['cash_amount'] as num?)?.toDouble() ?? 0));
    final avgRate = totalPts > 0 ? (totalCash / totalPts) : 0.0;
    return [
      _Stat('Total Conversions', _fmt(total), Icons.sync_alt_rounded,
          const Color(0xFF6366F1)),
      _Stat('Points Converted', '${_fmt(totalPts)} pts', Icons.stars_rounded,
          const Color(0xFFF59E0B)),
      _Stat('Cash Value', '₹${totalCash.toStringAsFixed(2)}',
          Icons.payments_rounded, const Color(0xFF10B981)),
      _Stat('Avg Rate', '₹${avgRate.toStringAsFixed(3)}/pt',
          Icons.trending_up_rounded, const Color(0xFF3B82F6)),
    ];
  }

  String _fmt(num n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DATA TABLE
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTable(
      _ReportType type, List<Map<String, dynamic>> data, ThemeData theme) {
    final cols = type.columns;
    const maxRows = 100;
    final rows = data.take(maxRows).toList();
    final isMobile = Responsive.isMobile(context);
    // On mobile each column gets a fixed pixel width so the Row inside the
    // horizontal scroll view has bounded constraints (Expanded requires bounded).
    const double colUnit = 90.0;

    Column buildContent(bool scrollable) {
      Widget headerCell(_ColDef c) {
        final text = Text(
          c.label.toUpperCase(),
          style: AppTextStyles.captionStrong(color: Colors.grey.shade500),
        );
        return scrollable
            ? SizedBox(width: c.flex * colUnit, child: text)
            : Expanded(flex: c.flex, child: text);
      }

      Widget dataCell(_ColDef c, Map<String, dynamic> row) {
        final cell = Align(
          alignment: Alignment.centerLeft,
          child: _renderCell(c.key, row[c.key], type),
        );
        return scrollable
            ? SizedBox(width: c.flex * colUnit, child: cell)
            : Expanded(flex: c.flex, child: cell);
      }

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(color: Colors.grey.shade50),
            child: Row(children: cols.map(headerCell).toList()),
          ),
          const Divider(height: 1),
          ...rows.map((row) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100))),
                child:
                    Row(children: cols.map((c) => dataCell(c, row)).toList()),
              )),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (isMobile)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: buildContent(true),
            )
          else
            buildContent(false),
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Showing ${rows.length} of ${data.length} records',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
                const Spacer(),
                if (data.length > maxRows)
                  Text(
                    'Export CSV for full data',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade400),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderCell(String key, dynamic val, _ReportType type) {
    if (val == null) {
      return Text('\u2014',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400));
    }

    // Dates
    if (key == 'created_at' || key == 'approved_at' || key == 'expiry_date') {
      final dt = DateTime.tryParse(val.toString());
      if (dt != null) {
        final formatted = key == 'expiry_date'
            ? AppDateFormatter.short(dt)
            : AppDateFormatter.dateTime(dt);
        return Text(formatted,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700));
      }
    }

    // Status badges
    if (key == 'status') {
      return _StatusBadge(status: val.toString());
    }

    // Source type badges
    if (key == 'source_type') {
      return _SourceTypeBadge(type: val.toString());
    }

    // Points
    if (key == 'points' ||
        key == 'points_used' ||
        key == 'points_converted' ||
        key == 'total_points' ||
        key == 'total_allocated' ||
        key == 'total_spent' ||
        key == 'remaining_balance') {
      return Text('${_fmt(val is num ? val : 0)} pts',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600));
    }

    // Cash
    if (key == 'cash_amount') {
      final n = (val is num) ? val.toDouble() : 0.0;
      return Text('₹${n.toStringAsFixed(2)}',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700));
    }

    // Utilization %
    if (key == 'utilization_pct') {
      final pct = double.tryParse(val.toString()) ?? 0;
      final color = pct >= 80
          ? Colors.red.shade600
          : pct >= 50
              ? Colors.orange.shade600
              : Colors.green.shade600;
      return Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0, 1),
                backgroundColor: Colors.grey.shade100,
                color: color,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$val%',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      );
    }

    // Days remaining
    if (key == 'days_remaining') {
      final d = val is num ? val.toInt() : 0;
      final color = d <= 7
          ? Colors.red.shade600
          : d <= 14
              ? Colors.orange.shade600
              : Colors.green.shade600;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$d days',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );
    }

    // User count
    if (key == 'user_count') {
      return Row(
        children: [
          Icon(Icons.people_outline, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(val.toString(),
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      );
    }

    // Message (truncated)
    if (key == 'message') {
      return Tooltip(
        message: val.toString(),
        child: Text(val.toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      );
    }

    // Names (bold)
    if (key.contains('name')) {
      return Text(val.toString(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis);
    }

    // Default
    return Text(val.toString(),
        style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis);
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
}

class _ReportCard extends StatefulWidget {
  final _ReportType type;
  final VoidCallback onTap;
  const _ReportCard({required this.type, required this.onTap});

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -2.0 : 0, 0),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          elevation: _hovered ? 4 : 0,
          shadowColor: widget.type.color.withValues(alpha: 0.2),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _hovered
                        ? widget.type.color.withValues(alpha: 0.3)
                        : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.type.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(widget.type.icon,
                            color: widget.type.color, size: 22),
                      ),
                      const Spacer(),
                      Icon(
                          _hovered
                              ? Icons.arrow_forward_rounded
                              : Icons.download_rounded,
                          size: 18,
                          color: _hovered
                              ? widget.type.color
                              : Colors.grey.shade400),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(widget.type.title, style: AppTextStyles.cardTitle()),
                  const SizedBox(height: 4),
                  Text(widget.type.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSet;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSet,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSet ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSet ? Colors.blue.shade200 : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isSet ? Colors.blue.shade600 : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color:
                        isSet ? Colors.blue.shade700 : Colors.grey.shade600)),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onClear,
                child: Icon(Icons.close, size: 14, color: Colors.blue.shade400),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusBadge(status: status);
  }
}

class _SourceTypeBadge extends StatelessWidget {
  final String type;
  const _SourceTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    final label = _formatLabel(type);

    switch (type) {
      case 'ECARD':
        bg = Colors.pink.shade50;
        fg = Colors.pink.shade700;
        icon = Icons.card_giftcard;
      case 'AWARD':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade700;
        icon = Icons.emoji_events;
      case 'CELEBRATION':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade700;
        icon = Icons.celebration;
      case 'MANAGER_REWARD':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        icon = Icons.workspace_premium;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade600;
        icon = Icons.label_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600, color: fg),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String s) {
    if (s.isEmpty) return s;
    final spaced = s.replaceAll('_', ' ');
    final lowered = spaced.toLowerCase();
    return lowered[0].toUpperCase() + lowered.substring(1);
  }
}
