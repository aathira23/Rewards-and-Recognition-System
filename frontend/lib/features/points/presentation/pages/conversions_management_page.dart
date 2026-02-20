import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/widgets/action_buttons.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../injection_container.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/utils/date_formatter.dart';
import '../bloc/conversions_mgmt_bloc.dart';
import '../bloc/conversions_mgmt_event.dart';
import '../bloc/conversions_mgmt_state.dart';

class ConversionsManagementPage extends StatelessWidget {
  const ConversionsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ConversionsMgmtBloc>()..add(LoadPendingConversions()),
      child: const _ConversionsManagementView(),
    );
  }
}

class _ConversionsManagementView extends StatelessWidget {
  const _ConversionsManagementView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<ConversionsMgmtBloc, ConversionsMgmtState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ));
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
            ));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPageHeader(
                  title: 'Points Conversions',
                  subtitle:
                      'Approve or reject employee points conversion requests',
                  action: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => context
                        .read<ConversionsMgmtBloc>()
                        .add(LoadPendingConversions()),
                  ),
                ),
                const SizedBox(height: 24),
                if (state.isLoading && state.pending.isEmpty)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator())),
                if (!state.isLoading &&
                    state.pending.isEmpty &&
                    state.error == null)
                  const EmptyStateView(
                    icon: Icons.check_circle_outline,
                    title: 'No pending conversions',
                    message: 'All requests have been processed.',
                  ),
                if (state.pending.isNotEmpty)
                  ...state.pending.map(
                      (conv) => _buildConversionCard(context, conv, theme)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversionCard(
      BuildContext context, Map<String, dynamic> conv, ThemeData theme) {
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
        color: theme.colorScheme.surface,
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
                Text(userName, style: AppTextStyles.cardTitle()),
                const SizedBox(height: 4),
                Text(
                  '$type • $points pts → ₹$amount',
                  style: AppTextStyles.small(color: Colors.grey.shade600),
                ),
                Text(AppDateFormatter.format(date),
                    style: AppTextStyles.caption(color: Colors.grey.shade400)),
              ],
            ),
          ),
          if (status == 'PENDING') ...[
            RejectButton(
              isCompact: true,
              onPressed: () => context
                  .read<ConversionsMgmtBloc>()
                  .add(ActionConversionRequested(id: id, action: 'REJECTED')),
            ),
            const SizedBox(width: 4),
            ApproveButton(
              isCompact: true,
              onPressed: () => context
                  .read<ConversionsMgmtBloc>()
                  .add(ActionConversionRequested(id: id, action: 'APPROVED')),
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
                  style: AppTextStyles.captionBold(
                    color: status == 'APPROVED' ? Colors.green : Colors.red,
                  )),
            ),
        ],
      ),
    );
  }
}
