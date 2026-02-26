import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../pages/notifications_history_page.dart';

/// Bell icon in the top bar with an unread count badge.
/// Clicking it toggles a fixed-size dropdown panel showing all notifications.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final _bellKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  late final NotificationsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<NotificationsBloc>()
      ..add(GetNotificationsRequested())
      ..add(GetUnreadCountRequested());
  }

  @override
  void dispose() {
    _removeOverlay();
    _bloc.close();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _togglePanel() {
    if (_overlayEntry != null) {
      _removeOverlay();
      if (mounted) setState(() {});
      return;
    }

    final box = _bellKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final pos = box.localToGlobal(Offset.zero);
    final sz = box.size;
    final screenW = MediaQuery.of(context).size.width;
    // Right-align the panel with the bell's right edge, with a minimum of 8px from screen edge.
    final rightEdge =
        (screenW - pos.dx - sz.width).clamp(8.0, screenW - 380 - 8);

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Tap-outside barrier
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _removeOverlay();
                if (mounted) setState(() {});
              },
              child: const SizedBox.expand(),
            ),
          ),
          // Dropdown panel
          Positioned(
            top: pos.dy + sz.height + 6,
            right: rightEdge,
            child: BlocProvider.value(
              value: _bloc,
              child: _NotificationsPanel(
                closePanel: () {
                  _removeOverlay();
                  if (mounted) setState(() {});
                },
                outerContext: context,
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          final count = state.unreadCount;
          final isOpen = _overlayEntry != null;

          return Stack(
            key: _bellKey,
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  isOpen
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_outlined,
                  size: 24,
                  color: isOpen
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.85),
                ),
                onPressed: _togglePanel,
                tooltip: 'Notifications',
              ),
              if (count > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IgnorePointer(
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: AppTextStyles.micro(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dropdown panel
// ─────────────────────────────────────────────────────────────

class _NotificationsPanel extends StatelessWidget {
  final VoidCallback closePanel;
  final BuildContext outerContext;
  const _NotificationsPanel(
      {required this.closePanel, required this.outerContext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 380,
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 6, 10),
                  child: Row(
                    children: [
                      Text(
                        'Notifications',
                        style: AppTextStyles.sectionTitle(),
                      ),
                      if (state.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${state.unreadCount}',
                            style: AppTextStyles.captionBold(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (state.unreadCount > 0)
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => context
                              .read<NotificationsBloc>()
                              .add(MarkAllAsReadRequested()),
                          child: const Text('Mark all read',
                              style: TextStyle(fontSize: 12)),
                        ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        tooltip: 'Refresh',
                        onPressed: () {
                          context
                              .read<NotificationsBloc>()
                              .add(GetNotificationsRequested());
                          context
                              .read<NotificationsBloc>()
                              .add(GetUnreadCountRequested());
                        },
                      ),
                    ],
                  ),
                ),
                // ── Body ──
                Flexible(child: _buildBody(context, state, theme)),
                // ── Footer ──
                const Divider(height: 1, thickness: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextButton(
                    onPressed: () {
                      closePanel();
                      Navigator.push(
                        outerContext,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsHistoryPage(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View All History',
                          style: AppTextStyles.bodyBold(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, NotificationsState state, ThemeData theme) {
    if (state.status == NotificationsStatus.loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == NotificationsStatus.failure) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Could not load notifications',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              "You're all caught up!",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: state.notifications.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100),
      itemBuilder: (ctx, i) => _NotificationItem(
        notification: state.notifications[i],
        bloc: context.read<NotificationsBloc>(),
        onClosePanel: closePanel,
        outerContext: outerContext,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Individual notification row
// ─────────────────────────────────────────────────────────────

class _NotificationItem extends StatelessWidget {
  final NotificationEntity notification;
  final NotificationsBloc bloc;
  final VoidCallback onClosePanel;
  final BuildContext outerContext;
  const _NotificationItem({
    required this.notification,
    required this.bloc,
    required this.onClosePanel,
    required this.outerContext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _iconFor(notification.type);
    final color = _colorFor(notification.type);

    return InkWell(
      onTap: () {
        // Mark as read whenever the item is opened
        if (!notification.isRead) {
          bloc.add(MarkOneAsReadRequested(notification.id));
        }
        // Close the overlay panel BEFORE opening the dialog so the
        // tap-outside barrier doesn't steal the Dismiss tap.
        onClosePanel();
        _showDetailModal(outerContext, icon, color, Theme.of(outerContext));
      },
      child: Container(
        color: notification.isRead
            ? Colors.transparent
            : theme.colorScheme.primary.withValues(alpha: 0.03),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(top: 2), // Align icon with first line
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notification.title.isNotEmpty) ...[
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    notification.message,
                    style: AppTextStyles.small(color: Colors.grey.shade600),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: AppTextStyles.caption(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDetailModal(
      BuildContext context, IconData icon, Color color, ThemeData theme) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _labelFor(notification.type),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _exactDate(notification.createdAt),
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 18, color: Colors.grey.shade400),
                        onPressed: () => Navigator.pop(ctx),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: Colors.grey.shade100),

                // ── Body ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notification.title.isNotEmpty) ...[
                        Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── Summary strip ──
                      Builder(builder: (context) {
                        final summary = _parseSummary(notification, color);
                        if (summary.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  for (int i = 0; i < summary.length; i++) ...[
                                    if (i > 0)
                                      Container(
                                          width: 1,
                                          height: 32,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 14),
                                          color: Colors.grey.shade200),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          summary[i].label,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          summary[i].value,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: summary[i].valueColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        );
                      }),

                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.grey.shade600,
                          height: 1.6,
                        ),
                      ),

                      // ── Contextual tip ──
                      _buildContextCard(notification.type, color),

                      const SizedBox(height: 20),

                      // ── Button ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Got it',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Parse structured key facts from the message for the summary strip.
  List<({String label, String value, Color valueColor})> _parseSummary(
      NotificationEntity n, Color accent) {
    final items = <({String label, String value, Color valueColor})>[];
    final t = n.type.toLowerCase();
    final msg = n.message;

    // Points
    final ptsMatch = RegExp(r'(\d+)\s*(?:points?|pts)', caseSensitive: false)
        .firstMatch(msg);
    final pts = ptsMatch != null ? int.tryParse(ptsMatch.group(1)!) : null;

    // Quoted item name (badge / reward / award)
    final quotedMatch = RegExp(r"'([^']+)'").firstMatch(msg);
    final quotedName = quotedMatch?.group(1);

    // Sender (e.g. "David Chen appreciated")
    final senderMatch = RegExp(
            r'^([A-Z][a-z]+(?:\s[A-Z][a-z]+)*)\s+(?:appreciated|nominated|awarded|sent|gave)',
            caseSensitive: true)
        .firstMatch(msg);
    final sender = senderMatch?.group(1);

    // Days remaining (expiry)
    final daysMatch =
        RegExp(r'(\d+)\s+day', caseSensitive: false).firstMatch(msg);

    if (t == 'ecard' || t == 'award' || t == 'manager_reward') {
      if (sender != null)
        items.add((
          label: 'From',
          value: sender,
          valueColor: Colors.black87,
        ));
      if (quotedName != null)
        items.add((
          label: t == 'award' ? 'Award' : 'Badge',
          value: quotedName,
          valueColor: Colors.black87,
        ));
      if (pts != null)
        items.add((
          label: 'Points Earned',
          value: '+$pts pts',
          valueColor: Colors.green.shade600,
        ));
    } else if (t == 'expiry_reminder' || t == 'expiry') {
      if (pts != null)
        items.add((
          label: 'Points at Risk',
          value: '$pts pts',
          valueColor: Colors.orange.shade700,
        ));
      if (daysMatch != null)
        items.add((
          label: 'Days Left',
          value: daysMatch.group(1)!,
          valueColor: Colors.orange.shade700,
        ));
    } else if (t == 'redemption' || msg.toLowerCase().contains('redeemed')) {
      if (quotedName != null)
        items.add((
          label: 'Reward',
          value: quotedName,
          valueColor: Colors.black87,
        ));
      if (pts != null)
        items.add((
          label: 'Points Used',
          value: '$pts pts',
          valueColor: Colors.red.shade500,
        ));
    } else if (t == 'conversion') {
      if (pts != null)
        items.add((
          label: 'Points Converted',
          value: '$pts pts',
          valueColor: Colors.purple.shade600,
        ));
    } else if (t == 'celebration') {
      if (pts != null)
        items.add((
          label: 'Points Gifted',
          value: '+$pts pts',
          valueColor: Colors.pink.shade500,
        ));
    }

    return items;
  }

  /// Type-specific context/hint card shown below the message.
  Widget _buildContextCard(String type, Color color) {
    final hint = _hintFor(type);
    if (hint == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 15, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(String type) {
    switch (type.toLowerCase()) {
      case 'ecard':
        return 'RECOGNITION';
      case 'award':
        return 'AWARD';
      case 'manager_reward':
        return 'MANAGER REWARD';
      case 'redemption':
        return 'REDEMPTION';
      case 'conversion':
        return 'CASH CONVERSION';
      case 'celebration':
        return 'CELEBRATION';
      case 'expiry_reminder':
      case 'expiry':
        return 'EXPIRY ALERT';
      default:
        return type.isEmpty ? 'NOTIFICATION' : type.toUpperCase();
    }
  }

  String? _hintFor(String type) {
    switch (type.toLowerCase()) {
      case 'ecard':
      case 'manager_reward':
        return 'Points from recognitions are credited to your wallet. '
            'Head to the Rewards Store to see what you can redeem.';
      case 'award':
        return 'Points from awards are added directly to your wallet. '
            'You can redeem them in the Rewards Store anytime.';
      case 'redemption':
        return 'Your redemption request has been submitted. '
            'Once fulfilled, the reward will be delivered or credited to your account.';
      case 'conversion':
        return 'Your points-to-cash conversion request has been submitted. '
            'HR will process it during the next payroll cycle.';
      case 'celebration':
        return 'Celebration points are added to your wallet automatically. '
            'Check the Rewards Store to redeem them.';
      case 'expiry_reminder':
      case 'expiry':
        return 'These points will expire soon. Use them before the date to '
            'avoid losing them — redeem in the Rewards Store or request a cash conversion.';
      default:
        return null;
    }
  }

  String _exactDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
    } catch (_) {
      return '';
    }
  }

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'award':
        return Icons.emoji_events_rounded;
      case 'ecard':
        return Icons.card_giftcard_rounded;
      case 'manager_reward':
        return Icons.workspace_premium_rounded;
      case 'redemption':
        return Icons.storefront_rounded;
      case 'conversion':
        return Icons.currency_rupee_rounded;
      case 'celebration':
        return Icons.cake_rounded;
      case 'expiry_reminder':
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
      case 'ecard':
        return Colors.blue.shade600;
      case 'manager_reward':
        return Colors.indigo.shade500;
      case 'redemption':
        return Colors.green.shade600;
      case 'conversion':
        return Colors.purple.shade600;
      case 'celebration':
        return Colors.pink.shade400;
      case 'expiry_reminder':
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
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
