import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../injection_container.dart';

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
    color: Color(0xFF3B82F6),
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
        'Track every reward redemption — who redeemed what, points spent, fulfillment status and timestamps',
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
        'Manager-level budget snapshot — total allocated, spent, remaining balance and utilization percentage',
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
        'Forecast of employee points expiring in a selected window — dates, amounts and number of affected users',
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
        'Monthly points-to-cash conversion report — employee, points converted, cash value, approval status',
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

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // Active state
  _ReportType? _active;
  List<Map<String, dynamic>> _data = [];
  bool _loading = false;
  String? _error;

  // Filters
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _deptId;
  List<Map<String, dynamic>> _departments = [];
  String _payrollMonth = '';
  int _expiryDays = 30;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _payrollMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // ── fetch report data ────────────────────────────────────────────
  Future<void> _fetchReport(_ReportType type) async {
    setState(() {
      _active = type;
      _loading = true;
      _error = null;
      _data = [];
    });

    // Load department list if needed (once)
    if (type.hasDeptFilter && _departments.isEmpty) {
      try {
        final client = sl<ApiClient>();
        final res = await client.get(ApiConstants.departments);
        final body = res.data;
        final list = body is Map ? (body['data'] ?? []) : body;
        if (list is List) {
          _departments = list.cast<Map<String, dynamic>>();
        }
      } catch (_) {}
    }

    try {
      final client = sl<ApiClient>();
      late final dynamic response;

      if (type == _ReportType.payrollEncashment) {
        response =
            await client.get(ApiConstants.reportsPayroll, queryParameters: {
          'month': _payrollMonth,
          'export_format': 'json',
        });
      } else {
        final qp = <String, dynamic>{
          'report_type': type.backendType,
          'export_format': 'json',
        };
        if (type.hasDateFilter && _fromDate != null) {
          qp['from_date'] = DateFormat('yyyy-MM-dd').format(_fromDate!);
        }
        if (type.hasDateFilter && _toDate != null) {
          qp['to_date'] = DateFormat('yyyy-MM-dd').format(_toDate!);
        }
        if (type.hasDeptFilter && _deptId != null) {
          qp['department_id'] = _deptId;
        }
        if (type == _ReportType.expiryForecast) {
          qp['days'] = _expiryDays;
        }
        response = await client.get(ApiConstants.reports, queryParameters: qp);
      }

      if (response.statusCode == 200) {
        final body = response.data;
        final raw = body['data']?['data'] ?? body['data'] ?? [];
        final list = raw is List
            ? raw.cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];

        // Post-process: add computed fields
        for (final row in list) {
          // wallet utilization %
          if (type == _ReportType.walletUtilization) {
            final alloc = (row['total_allocated'] ?? 0) as num;
            final spent = (row['total_spent'] ?? 0) as num;
            row['utilization_pct'] =
                alloc > 0 ? ((spent / alloc) * 100).toStringAsFixed(1) : '0.0';
          }
          // expiry days remaining
          if (type == _ReportType.expiryForecast &&
              row['expiry_date'] != null) {
            final expiry = DateTime.tryParse(row['expiry_date'].toString());
            if (expiry != null) {
              row['days_remaining'] =
                  expiry.difference(DateTime.now()).inDays.clamp(0, 9999);
            }
          }
        }

        setState(() {
          _data = list;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Server returned ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _exportCsv() async {
    if (_active == null) return;
    try {
      final client = sl<ApiClient>();
      if (_active == _ReportType.payrollEncashment) {
        await client.get(ApiConstants.reportsPayroll, queryParameters: {
          'month': _payrollMonth,
          'export_format': 'csv',
        });
      } else {
        final qp = <String, dynamic>{
          'report_type': _active!.backendType,
          'export_format': 'csv',
        };
        if (_active!.hasDateFilter && _fromDate != null) {
          qp['from_date'] = DateFormat('yyyy-MM-dd').format(_fromDate!);
        }
        if (_active!.hasDateFilter && _toDate != null) {
          qp['to_date'] = DateFormat('yyyy-MM-dd').format(_toDate!);
        }
        if (_active!.hasDeptFilter && _deptId != null) {
          qp['department_id'] = _deptId;
        }
        if (_active == _ReportType.expiryForecast) {
          qp['days'] = _expiryDays;
        }
        await client.get(ApiConstants.reports, queryParameters: qp);
      }
      _snack('CSV export initiated');
    } catch (_) {
      _snack('Export failed', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade600 : null,
    ));
  }

  void _goBack() => setState(() {
        _active = null;
        _data = [];
        _error = null;
      });

  // ── build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _active == null ? _buildGrid() : _buildDetail(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  GRID
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reports',
              style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Generate, filter and export detailed organizational reports',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 28),
          LayoutBuilder(builder: (ctx, constraints) {
            final cardWidth =
                (constraints.maxWidth - 40) / 3; // 3 cols with gaps
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: _ReportType.values.map((t) {
                return SizedBox(
                  width: cardWidth.clamp(260, 500),
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
  Widget _buildDetail() {
    final type = _active!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
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
                        style: GoogleFonts.outfit(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(type.subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _fetchReport(type),
                icon: const Icon(Icons.refresh, size: 15),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8)),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _data.isNotEmpty ? _exportCsv : null,
                icon: const Icon(Icons.download_rounded, size: 15),
                label: const Text('Export CSV'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── filters ──
          _buildFilters(type),

          // ── summary cards ──
          if (!_loading && _data.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSummary(type),
          ],

          const SizedBox(height: 20),

          // ── content ──
          if (_loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(60),
                    child: CircularProgressIndicator())),
          if (_error != null)
            Center(
                child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(children: [
                Icon(Icons.error_outline, color: Colors.red.shade300),
                const SizedBox(height: 8),
                Text(_error!,
                    style: TextStyle(fontSize: 13, color: Colors.red.shade600)),
                const SizedBox(height: 12),
                OutlinedButton(
                    onPressed: () => _fetchReport(type),
                    child: const Text('Retry')),
              ]),
            )),
          if (!_loading && _error == null && _data.isEmpty)
            Center(
                child: Padding(
              padding: const EdgeInsets.all(60),
              child: Column(children: [
                Icon(Icons.inbox_rounded,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text('No records found for the selected filters',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ]),
            )),
          if (!_loading && _data.isNotEmpty) _buildTable(type),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  FILTERS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFilters(_ReportType type) {
    if (!type.hasDateFilter &&
        !type.hasDeptFilter &&
        type != _ReportType.payrollEncashment &&
        type != _ReportType.expiryForecast) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded,
              size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),

          // Date range
          if (type.hasDateFilter) ...[
            _FilterChip(
              label: _fromDate != null
                  ? DateFormat('dd MMM yyyy').format(_fromDate!)
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
            Text('→', style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(width: 8),
            _FilterChip(
              label: _toDate != null
                  ? DateFormat('dd MMM yyyy').format(_toDate!)
                  : 'To Date',
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
            const SizedBox(width: 16),
          ],

          // Department filter
          if (type.hasDeptFilter && _departments.isNotEmpty) ...[
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color:
                    _deptId != null ? Colors.blue.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _deptId != null
                        ? Colors.blue.shade200
                        : Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _deptId,
                  hint: Text('All Departments',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  isDense: true,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Departments')),
                    ..._departments.map((d) => DropdownMenuItem(
                        value: d['id'] as int?,
                        child: Text(d['name']?.toString() ?? ''))),
                  ],
                  onChanged: (v) {
                    setState(() => _deptId = v);
                    _fetchReport(type);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
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
                          sel ? const Color(0xFF1E56BD) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? const Color(0xFF1E56BD)
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
              label: _payrollMonth,
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

          const Spacer(),
          Text('${_data.length} records',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SUMMARY STAT CARDS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSummary(_ReportType type) {
    final stats = _computeStats(type);
    return Row(
      children: stats
          .map((s) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      Text(s.value,
                          style: GoogleFonts.inter(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(s.label,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  List<_Stat> _computeStats(_ReportType type) {
    switch (type) {
      case _ReportType.recognitions:
        return _recognitionStats();
      case _ReportType.redemptions:
        return _redemptionStats();
      case _ReportType.walletUtilization:
        return _walletStats();
      case _ReportType.expiryForecast:
        return _expiryStats();
      case _ReportType.payrollEncashment:
        return _payrollStats();
    }
  }

  List<_Stat> _recognitionStats() {
    final total = _data.length;
    final totalPts =
        _data.fold<int>(0, (s, r) => s + ((r['points'] as num?)?.toInt() ?? 0));
    final senders = _data.map((r) => r['actor_name']).toSet().length;
    final receivers = _data.map((r) => r['receiver_name']).toSet().length;

    // Top source type
    final typeCounts = <String, int>{};
    for (final r in _data) {
      final t = r['source_type']?.toString() ?? '';
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }
    String topType = '—';
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

  List<_Stat> _redemptionStats() {
    final total = _data.length;
    final totalPts = _data.fold<int>(
        0, (s, r) => s + ((r['points_used'] as num?)?.toInt() ?? 0));
    final employees = _data.map((r) => r['user_name']).toSet().length;
    final fulfilled = _data.where((r) => r['status'] == 'FULFILLED').length;

    // Most popular reward
    final rwdCounts = <String, int>{};
    for (final r in _data) {
      final rw = r['reward_name']?.toString() ?? '';
      rwdCounts[rw] = (rwdCounts[rw] ?? 0) + 1;
    }
    String topReward = '—';
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

  List<_Stat> _walletStats() {
    final count = _data.length;
    final totalAlloc = _data.fold<int>(
        0, (s, r) => s + ((r['total_allocated'] as num?)?.toInt() ?? 0));
    final totalSpent = _data.fold<int>(
        0, (s, r) => s + ((r['total_spent'] as num?)?.toInt() ?? 0));
    final avgUtil = count > 0
        ? _data.fold<double>(
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

  List<_Stat> _expiryStats() {
    final totalPts = _data.fold<int>(
        0, (s, r) => s + ((r['total_points'] as num?)?.toInt() ?? 0));
    final totalUsers = _data.fold<int>(
        0, (s, r) => s + ((r['user_count'] as num?)?.toInt() ?? 0));
    final dates = _data.length;

    // Earliest expiry
    int minDays = 999;
    for (final r in _data) {
      final d = (r['days_remaining'] as num?)?.toInt() ?? 999;
      if (d < minDays) {
        minDays = d;
      }
    }

    return [
      _Stat('Points at Risk', '${_fmt(totalPts)} pts',
          Icons.warning_amber_rounded, const Color(0xFFEF4444)),
      _Stat('Users Affected', _fmt(totalUsers), Icons.people_outline_rounded,
          const Color(0xFFF59E0B)),
      _Stat('Expiry Dates', _fmt(dates), Icons.event_rounded,
          const Color(0xFF3B82F6)),
      _Stat('Earliest Expiry', minDays < 999 ? '$minDays days' : '—',
          Icons.timer_outlined, const Color(0xFF8B5CF6)),
    ];
  }

  List<_Stat> _payrollStats() {
    final total = _data.length;
    final totalPts = _data.fold<int>(
        0, (s, r) => s + ((r['points_converted'] as num?)?.toInt() ?? 0));
    final totalCash = _data.fold<double>(
        0, (s, r) => s + ((r['cash_amount'] as num?)?.toDouble() ?? 0));
    final avgRate = totalPts > 0 ? (totalCash / totalPts) : 0.0;

    return [
      _Stat('Total Conversions', _fmt(total), Icons.sync_alt_rounded,
          const Color(0xFF6366F1)),
      _Stat('Points Converted', '${_fmt(totalPts)} pts', Icons.stars_rounded,
          const Color(0xFFF59E0B)),
      _Stat('Cash Value', '\$${totalCash.toStringAsFixed(2)}',
          Icons.payments_rounded, const Color(0xFF10B981)),
      _Stat('Avg Rate', '\$${avgRate.toStringAsFixed(3)}/pt',
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
  Widget _buildTable(_ReportType type) {
    final cols = type.columns;
    const maxRows = 100;
    final rows = _data.take(maxRows).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: cols
                  .map((c) => Expanded(
                        flex: c.flex,
                        child: Text(
                          c.label.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const Divider(height: 1),
          // Rows
          ...rows.map((row) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: cols
                    .map((c) => Expanded(
                          flex: c.flex,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _renderCell(c.key, row[c.key], type),
                          ),
                        ))
                    .toList(),
              ),
            );
          }),
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Showing ${rows.length} of ${_data.length} records',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
                const Spacer(),
                if (_data.length > maxRows)
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
      return Text('—',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400));
    }

    // Dates
    if (key == 'created_at' || key == 'approved_at' || key == 'expiry_date') {
      final dt = DateTime.tryParse(val.toString());
      if (dt != null) {
        final formatted = key == 'expiry_date'
            ? DateFormat('dd MMM yyyy').format(dt)
            : DateFormat('dd MMM yyyy, HH:mm').format(dt);
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
      return Text('\$${n.toStringAsFixed(2)}',
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -2.0 : 0, 0),
        child: Material(
          color: Colors.white,
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
                  Text(widget.type.title,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700)),
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
    final s = status.toUpperCase();
    final Color bg;
    final Color fg;
    if (s == 'APPROVED' ||
        s == 'FULFILLED' ||
        s == 'PROCESSED' ||
        s == 'PAID') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (s == 'PENDING' || s == 'REQUESTED') {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade700;
    } else if (s == 'REJECTED' || s == 'CANCELLED') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    } else {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(s,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
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
    final label = type.replaceAll('_', ' ');

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
}
