import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../injection_container.dart';

class ConversionsManagementPage extends StatefulWidget {
  const ConversionsManagementPage({super.key});

  @override
  State<ConversionsManagementPage> createState() =>
      _ConversionsManagementPageState();
}

class _ConversionsManagementPageState extends State<ConversionsManagementPage> {
  List<Map<String, dynamic>> _pending = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => _isLoading = true);
    try {
      final client = sl<ApiClient>();
      final response = await client.get(ApiConstants.pointsPendingConversions);
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        setState(() {
          _pending = data.cast<Map<String, dynamic>>();
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

  Future<void> _actionConversion(int id, String action) async {
    try {
      final client = sl<ApiClient>();
      await client.post(
        '${ApiConstants.pointsConversions}/$id/action',
        data: {'action': action},
      );
      _loadPending();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Conversion ${action.toLowerCase()}'),
          backgroundColor: action == 'APPROVED' ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Points Conversions',
                    style: GoogleFonts.outfit(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.refresh), onPressed: _loadPending),
              ],
            ),
            const SizedBox(height: 8),
            Text('Approve or reject employee points conversion requests',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: CircularProgressIndicator())),
            if (_error != null)
              Center(
                  child: Text('Error: $_error',
                      style: TextStyle(color: Colors.red.shade700))),
            if (!_isLoading && _pending.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(64.0),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48, color: Colors.green.shade300),
                      const SizedBox(height: 16),
                      Text('No pending conversions',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            if (!_isLoading && _pending.isNotEmpty)
              ..._pending.map((conv) => _buildConversionCard(conv, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionCard(Map<String, dynamic> conv, ThemeData theme) {
    final id = conv['id'] ?? 0;
    final userName =
        conv['user']?['name'] ?? conv['user_name'] ?? 'Unknown User';
    final type = conv['conversion_type'] ?? '';
    final points = conv['points_converted'] ?? 0;
    final amount = conv['cash_amount'] ?? 0;
    final status = conv['status'] ?? 'PENDING';
    final date = conv['requested_at'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: type == 'PAYROLL'
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              type == 'PAYROLL'
                  ? Icons.payments_rounded
                  : Icons.volunteer_activism_rounded,
              color: type == 'PAYROLL' ? Colors.green : Colors.blue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '$type • $points pts → ₹$amount',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(date,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          if (status == 'PENDING') ...[
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _actionConversion(id, 'REJECTED'),
              tooltip: 'Reject',
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _actionConversion(id, 'APPROVED'),
              tooltip: 'Approve',
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'APPROVED'
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: status == 'APPROVED' ? Colors.green : Colors.red,
                  )),
            ),
        ],
      ),
    );
  }
}
