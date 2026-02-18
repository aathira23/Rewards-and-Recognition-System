import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../injection_container.dart';

class PayrollEncashmentPage extends StatefulWidget {
  const PayrollEncashmentPage({super.key});

  @override
  State<PayrollEncashmentPage> createState() => _PayrollEncashmentPageState();
}

class _PayrollEncashmentPageState extends State<PayrollEncashmentPage> {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String? _error;
  late String _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final client = sl<ApiClient>();
      final response = await client.get(ApiConstants.reportsPayroll,
          queryParameters: {'month': _selectedMonth, 'export_format': 'json'});

      if (response.statusCode == 200) {
        final body = response.data;
        final rawData = body['data']?['data'] ?? body['data'] ?? [];
        setState(() {
          _data = (rawData is List)
              ? rawData.cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[];
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
    try {
      final client = sl<ApiClient>();
      await client.get(ApiConstants.reportsPayroll,
          queryParameters: {'month': _selectedMonth, 'export_format': 'csv'});
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

  void _changeMonth(int offset) {
    final parts = _selectedMonth.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) + offset;
    if (month > 12) {
      month = 1;
      year++;
    } else if (month < 1) {
      month = 12;
      year--;
    }
    setState(() {
      _selectedMonth = '$year-${month.toString().padLeft(2, '0')}';
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payroll Encashment',
                          style: GoogleFonts.outfit(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('View and export points encashment requests',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                // Month picker
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 18),
                        onPressed: () => _changeMonth(-1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(_selectedMonth,
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 18),
                        onPressed: () => _changeMonth(1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _exportCsv,
                  icon: const Icon(Icons.download_rounded, size: 15),
                  label: const Text('Export to CSV/Excel'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Table
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
                        style: TextStyle(
                            fontSize: 13, color: Colors.red.shade600)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _fetchData,
                      icon: const Icon(Icons.refresh, size: 15),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8)),
                    ),
                  ],
                ),
              )),
            if (!_isLoading && _error == null) _buildTable(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(ThemeData theme) {
    if (_data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text('No encashment records for $_selectedMonth',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: const [
                Expanded(
                    flex: 3,
                    child: Text('EMPLOYEE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.grey))),
                Expanded(
                    flex: 2,
                    child: Text('POINTS ENCASHED',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.grey))),
                Expanded(
                    flex: 2,
                    child: Text('MONETARY VALUE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.grey))),
                Expanded(
                    flex: 2,
                    child: Text('STATUS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.grey))),
                Expanded(
                    flex: 2,
                    child: Text('APPROVED AT',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.grey))),
              ],
            ),
          ),
          const Divider(height: 1),
          // Data rows
          ..._data.map((row) => _buildRow(row, theme)),
          // Footer
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text('Showing ${_data.length} results',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> row, ThemeData theme) {
    final name = row['user_name']?.toString() ?? 'Unknown';
    final points = row['points_converted'] ?? 0;
    final cash = double.tryParse(row['cash_amount']?.toString() ?? '0') ?? 0;
    final status = row['status']?.toString() ?? '';
    final approvedAt = row['approved_at']?.toString() ?? '—';
    final isApproved = status == 'APPROVED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Text(name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('$points pts',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text('\$${cash.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700)),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isApproved ? Colors.green.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isApproved ? 'Processed' : status,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isApproved
                        ? Colors.green.shade700
                        : Colors.amber.shade700),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
                approvedAt.length >= 10
                    ? approvedAt.substring(0, 10)
                    : approvedAt,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }
}
