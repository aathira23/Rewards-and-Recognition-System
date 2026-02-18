import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../injection_container.dart';

/// Report types matching the backend report_type param.
enum _ReportType {
  recognitions(
      'RECOGNITIONS',
      'Recognitions Report',
      'Complete recognition history and trends',
      Icons.description_rounded,
      Color(0xFF3B82F6)),
  walletUtilization(
      'WALLET_UTILIZATION',
      'Wallet Utilization',
      'Manager wallet allocation and usage',
      Icons.attach_money_rounded,
      Color(0xFF8B5CF6)),
  redemptions(
      'REDEMPTIONS',
      'Redemptions Report',
      'Points redemption and reward tracking',
      Icons.card_giftcard_rounded,
      Color(0xFF10B981)),
  engagement(
      'RECOGNITIONS',
      'Employee Engagement',
      'User participation and activity metrics',
      Icons.groups_rounded,
      Color(0xFFF59E0B)),
  department(
      'RECOGNITIONS',
      'Department Analytics',
      'Cross-department comparison report',
      Icons.bar_chart_rounded,
      Color(0xFFEF4444)),
  payrollEncashment(
      'PAYROLL',
      'Payroll Encashment',
      'Points-to-payroll conversion report',
      Icons.attach_money_rounded,
      Color(0xFF6366F1));

  final String backendType;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  const _ReportType(
      this.backendType, this.title, this.description, this.icon, this.color);
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  _ReportType? _activeReport;
  List<dynamic> _reportData = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _fetchReport(_ReportType type) async {
    setState(() {
      _activeReport = type;
      _isLoading = true;
      _error = null;
      _reportData = [];
    });

    try {
      final client = sl<ApiClient>();
      late final dynamic response;

      if (type == _ReportType.payrollEncashment) {
        // Payroll uses a different endpoint with month param
        final now = DateTime.now();
        final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        response = await client.get(ApiConstants.reportsPayroll,
            queryParameters: {'month': month, 'export_format': 'json'});
      } else {
        response = await client.get(ApiConstants.reports, queryParameters: {
          'report_type': type.backendType,
          'export_format': 'json',
        });
      }

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body['data']?['data'] ?? body['data'] ?? [];
        setState(() {
          _reportData = data is List ? data : [data];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load report';
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

  Future<void> _exportCsv() async {
    if (_activeReport == null) return;
    try {
      final client = sl<ApiClient>();
      if (_activeReport == _ReportType.payrollEncashment) {
        final now = DateTime.now();
        final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        await client.get(ApiConstants.reportsPayroll,
            queryParameters: {'month': month, 'export_format': 'csv'});
      } else {
        await client.get(ApiConstants.reports, queryParameters: {
          'report_type': _activeReport!.backendType,
          'export_format': 'csv',
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV export initiated')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export failed')),
        );
      }
    }
  }

  void _goBack() => setState(() => _activeReport = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _activeReport == null ? _buildGrid() : _buildDetail(),
    );
  }

  // ── Grid of report cards ─────────────────────────────────────
  Widget _buildGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reports',
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Generate and export organizational reports',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 28),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 2.1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _ReportType.values.map((type) {
              return _ReportCard(
                type: type,
                onTap: () => _fetchReport(type),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Detail view with table ───────────────────────────────────
  Widget _buildDetail() {
    final type = _activeReport!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb / Back
          Row(
            children: [
              InkWell(
                onTap: _goBack,
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded,
                        size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text('Reports',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('/',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
              const SizedBox(width: 8),
              Text(type.title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          // Title + actions
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.title,
                        style: GoogleFonts.outfit(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(type.description,
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
                onPressed: _exportCsv,
                icon: const Icon(Icons.download_rounded, size: 15),
                label: const Text('Export to CSV'),
                style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Content
          if (_isLoading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(60),
                    child: CircularProgressIndicator())),
          if (_error != null)
            Center(
                child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade300),
                  const SizedBox(height: 8),
                  Text(_error!,
                      style:
                          TextStyle(fontSize: 13, color: Colors.red.shade600)),
                ],
              ),
            )),
          if (!_isLoading && _error == null && _reportData.isEmpty)
            Center(
                child: Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text('No records found',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            )),
          if (!_isLoading && _reportData.isNotEmpty) _buildTable(type),
        ],
      ),
    );
  }

  Widget _buildTable(_ReportType type) {
    // Build columns dynamically from the first row keys
    final firstRow = _reportData.first;
    if (firstRow is! Map) return const SizedBox.shrink();

    final keys = (firstRow as Map<String, dynamic>)
        .keys
        .where((k) => k != 'id')
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: keys.map((k) {
                return Expanded(
                  child: Text(
                    _formatColumnName(k),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.grey.shade600),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          // Data rows
          ...(_reportData.take(50)).map((row) {
            if (row is! Map) return const SizedBox.shrink();
            final map = row as Map<String, dynamic>;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: keys.map((k) {
                  final val = map[k];
                  return Expanded(
                    child: _buildCellValue(k, val),
                  );
                }).toList(),
              ),
            );
          }),
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                    'Showing ${_reportData.length > 50 ? 50 : _reportData.length} of ${_reportData.length} results',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellValue(String key, dynamic val) {
    if (val == null) {
      return Text('—',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400));
    }
    // Status badge
    if (key == 'status') {
      final s = val.toString();
      final isGood = s == 'APPROVED' || s == 'Processed' || s == 'processed';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isGood ? Colors.green.shade50 : Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(s,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isGood ? Colors.green.shade700 : Colors.amber.shade700)),
      );
    }
    // Money values
    if (key.contains('cash') || key.contains('amount')) {
      return Text('\$${_formatMoney(val)}',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700));
    }
    // Points
    if (key.contains('points')) {
      return Text('${val} pts',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600));
    }
    return Text(val.toString(),
        style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis);
  }

  String _formatColumnName(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
            (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ')
        .toUpperCase();
  }

  String _formatMoney(dynamic val) {
    final n = double.tryParse(val.toString()) ?? 0;
    return n.toStringAsFixed(2);
  }
}

// ── Report card widget ───────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final _ReportType type;
  final VoidCallback onTap;
  const _ReportCard({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(type.icon, color: type.color, size: 20),
                  ),
                  Icon(Icons.download_rounded,
                      size: 18, color: Colors.grey.shade400),
                ],
              ),
              const Spacer(),
              Text(type.title,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(type.description,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }
}
