import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../bloc/payroll_bloc.dart';
import '../bloc/payroll_event.dart';
import '../bloc/payroll_state.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/utils/date_formatter.dart';

class PayrollEncashmentPage extends StatelessWidget {
  const PayrollEncashmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final initialMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return BlocProvider(
      create: (_) => sl<PayrollBloc>()..add(LoadPayroll(month: initialMonth)),
      child: _PayrollView(initialMonth: initialMonth),
    );
  }
}

class _PayrollView extends StatefulWidget {
  final String initialMonth;
  const _PayrollView({required this.initialMonth});

  @override
  State<_PayrollView> createState() => _PayrollViewState();
}

class _PayrollViewState extends State<_PayrollView> {
  late String _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth;
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
    context.read<PayrollBloc>().add(LoadPayroll(month: _selectedMonth));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<PayrollBloc, PayrollState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.successMessage!),
            behavior: SnackBarBehavior.floating,
          ));
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                AppPageHeader(
                  title: 'Payroll Encashment',
                  subtitle: 'View and export points encashment requests',
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Month picker
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(_selectedMonth,
                                  style: AppTextStyles.bodyBold()),
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
                        onPressed: () => context
                            .read<PayrollBloc>()
                            .add(ExportPayrollCsv(month: _selectedMonth)),
                        icon: const Icon(Icons.download_rounded, size: 15),
                        label: const Text('Export to CSV/Excel'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (state.isLoading)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(60),
                          child: CircularProgressIndicator())),
                if (!state.isLoading && state.error == null)
                  _buildTable(state.data, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> data, ThemeData theme) {
    if (data.isEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_rounded,
        title: 'No records for $_selectedMonth',
        message: 'No encashment requests were made during this period.',
        padding: 60,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
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
          ...data.map((row) => _buildRow(row, theme)),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text('Showing ${data.length} results',
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
    final approvedAt = row['approved_at']?.toString() ?? '\u2014';
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
            child: Text('₹${cash.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700)),
          ),
          Expanded(
            flex: 2,
            child: StatusBadge(
              status: status,
              label: isApproved ? 'Processed' : null,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(AppDateFormatter.format(approvedAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }
}
