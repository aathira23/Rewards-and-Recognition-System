import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/utils/date_formatter.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsBloc>()
        ..add(GetNotificationsRequested())
        ..add(GetUnreadCountRequested()),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.pagePadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPageHeader(
                  title: 'Notifications',
                  subtitle: state.unreadCount > 0
                      ? '${state.unreadCount} unread'
                      : 'You are all caught up',
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.unreadCount > 0)
                        TextButton.icon(
                          onPressed: () {
                            context
                                .read<NotificationsBloc>()
                                .add(MarkAllAsReadRequested());
                          },
                          icon: const Icon(Icons.done_all, size: 18),
                          label: const Text('Mark all read'),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () {
                          context
                              .read<NotificationsBloc>()
                              .add(GetNotificationsRequested());
                          context
                              .read<NotificationsBloc>()
                              .add(GetUnreadCountRequested());
                        },
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (state.status == NotificationsStatus.loading)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  )),
                if (state.status == NotificationsStatus.failure)
                  EmptyStateView(
                    icon: Icons.error_outline_rounded,
                    title: 'Failed to load notifications',
                    message: state.errorMessage,
                    onRetry: () => context
                        .read<NotificationsBloc>()
                        .add(GetNotificationsRequested()),
                  ),
                if (state.status == NotificationsStatus.success &&
                    state.notifications.isEmpty)
                  const EmptyStateView(
                    icon: Icons.notifications_off_outlined,
                    title: 'No notifications yet',
                    message: 'Stay tuned! We\'ll notify you here.',
                  ),
                if (state.notifications.isNotEmpty)
                  ...state.notifications
                      .map((n) => _buildNotificationTile(context, n, theme)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(
      BuildContext context, NotificationEntity notification, ThemeData theme) {
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : theme.colorScheme.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.shade200
              : theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight:
                        notification.isRead ? FontWeight.w500 : FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: AppTextStyles.body(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Text(
                  AppDateFormatter.format(notification.createdAt),
                  style: AppTextStyles.caption(color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'award':
        return Icons.emoji_events_rounded;
      case 'recognition':
        return Icons.card_giftcard_rounded;
      case 'points':
        return Icons.account_balance_wallet_rounded;
      case 'celebration':
        return Icons.cake_rounded;
      case 'expiry':
        return Icons.timer_off_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'award':
        return Colors.amber.shade700;
      case 'recognition':
        return Colors.blue.shade600;
      case 'points':
        return Colors.green.shade600;
      case 'celebration':
        return Colors.pink.shade400;
      case 'expiry':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}
