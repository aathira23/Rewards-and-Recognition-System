import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../injection_container.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsHistoryPage extends StatefulWidget {
  const NotificationsHistoryPage({super.key});

  @override
  State<NotificationsHistoryPage> createState() =>
      _NotificationsHistoryPageState();
}

class _NotificationsHistoryPageState extends State<NotificationsHistoryPage> {
  late final NotificationsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<NotificationsBloc>()
      ..add(GetNotificationsRequested())
      ..add(GetUnreadCountRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Notification History'),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                if (state.unreadCount > 0) {
                  return TextButton.icon(
                    onPressed: () => _bloc.add(MarkAllAsReadRequested()),
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Mark all as read'),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state.status == NotificationsStatus.loading &&
                state.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.notifications.isEmpty) {
              return const EmptyStateView(
                icon: Icons.notifications_none_rounded,
                title: 'No notifications found',
                message: 'Your history is empty',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _bloc.add(GetNotificationsRequested());
                _bloc.add(GetUnreadCountRequested());
              },
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: Responsive.pagePadding(context),
                ),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return _NotificationHistoryItem(notification: notification);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationHistoryItem extends StatelessWidget {
  final NotificationEntity notification;

  const _NotificationHistoryItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(notification.type);
    final color = _colorFor(notification.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead
              ? Colors.grey.shade200
              : color.withOpacity(0.3),
          width: notification.isRead ? 1 : 1.5,
        ),
      ),
      color: notification.isRead ? Colors.white : color.withOpacity(0.02),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            context
                .read<NotificationsBloc>()
                .add(MarkOneAsReadRequested(notification.id));
          }
          _showDetailDialog(context, icon, color);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.bodyBold(
                              color: notification.isRead
                                  ? Colors.black87
                                  : Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          _timeAgo(notification.createdAt),
                          style: AppTextStyles.caption(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: AppTextStyles.body(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (!notification.isRead) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NEW',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: Text(notification.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
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

  Color _colorFor(String type) {
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

  String _timeAgo(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return dateStr;
    }
  }
}
