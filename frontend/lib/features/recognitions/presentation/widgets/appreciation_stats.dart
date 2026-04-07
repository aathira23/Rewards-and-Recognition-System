import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/badge_utils.dart';
import '../../domain/entities/appreciation_stats_entity.dart';
import '../../domain/entities/recognition_entity.dart';

class AppreciationStats extends StatefulWidget {
  final AppreciationStatsEntity stats;

  const AppreciationStats({super.key, required this.stats});

  @override
  State<AppreciationStats> createState() => _AppreciationStatsState();
}

class _AppreciationStatsState extends State<AppreciationStats> {
  late final ScrollController _controller;
  bool _showLeft = false;
  bool _showRight = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    _controller.removeListener(_updateArrows);
    _controller.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    final offset = _controller.offset;
    final showLeft = offset > 5.0;
    final showRight = offset < (max - 5.0);
    if (showLeft != _showLeft || showRight != _showRight) {
      setState(() {
        _showLeft = showLeft;
        _showRight = showRight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Appreciations Received',
                    style: AppTextStyles.pageTitle(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (stats.receivedCount > 0) ...[
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${stats.receivedCount} Total',
                          style: AppTextStyles.bodyBold(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Builder(builder: (context) {
                        final totalPoints = (stats.receivedRecognitions ?? [])
                            .fold<int>(
                                0, (sum, r) => sum + (r.pointsAwarded).toInt());
                        if (totalPoints <= 0) return const SizedBox.shrink();
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+$totalPoints pts',
                                    style: AppTextStyles.bodyBold(
                                      color: Colors.amber[700]!,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your achievements and recognitions from colleagues',
              style: AppTextStyles.body(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (stats.receivedCount == 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.grey.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No appreciations yet',
                      style: AppTextStyles.sectionTitle(
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Great work starts with small steps. Keep going!',
                      style: AppTextStyles.small(color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 140,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ListView.separated(
                      controller: _controller,
                      // allow touch/drag scrolling in addition to arrow navigation
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemBuilder: (context, index) {
                        final recognition =
                            (stats.receivedRecognitions ?? [])[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: _ReceivedHoverCard(recognition: recognition),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox.shrink(),
                      itemCount: (stats.receivedRecognitions ?? []).length,
                    ),
                    // Left arrow
                    if (_showLeft)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withOpacity(0.0),
                                Theme.of(context).colorScheme.surface,
                              ],
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              if (!_controller.hasClients) return;
                              final next = (_controller.offset - 240).clamp(
                                  0.0, _controller.position.maxScrollExtent);
                              _controller.animateTo(
                                next,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                          ),
                        ),
                      ),

                    // Right arrow
                    if (_showRight)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withOpacity(0.0),
                                Theme.of(context).colorScheme.surface,
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              if (!_controller.hasClients) return;
                              final maxScroll =
                                  _controller.position.maxScrollExtent;
                              final next = (_controller.offset + 240)
                                  .clamp(0.0, maxScroll);
                              _controller.animateTo(
                                next,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A compact badge card that expands on hover to reveal sender & message details.
class _ReceivedHoverCard extends StatefulWidget {
  final RecognitionEntity recognition;

  const _ReceivedHoverCard({required this.recognition});

  @override
  State<_ReceivedHoverCard> createState() => _ReceivedHoverCardState();
}

class _ReceivedHoverCardState extends State<_ReceivedHoverCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  // Compact (collapsed) dimensions
  static const double _compactWidth = 110;
  static const double _compactHeight = 100;

  // Expanded dimensions
  static const double _expandedHeight = 160;

  @override
  Widget build(BuildContext context) {
    final badgeName = widget.recognition.badge?.name ?? 'Badge';
    final badgeInfo = BadgeUtils.getDisplayInfo(badgeName);
    final senderName = widget.recognition.senderName ?? 'Someone';
    final message = widget.recognition.message;
    final date =
        DateFormat('MMM dd, yyyy').format(widget.recognition.createdAt);
    final iconUrl = widget.recognition.badge?.iconUrl;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _isHovered = !_isHovered),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          clipBehavior: Clip.hardEdge,
          width: _isHovered ? 280.0 : _compactWidth,
          height: _isHovered ? _expandedHeight : _compactHeight,
          padding: _isHovered ? EdgeInsets.zero : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isHovered
                ? badgeInfo.color.withOpacity(0.06)
                : Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: _isHovered
                  ? badgeInfo.color.withOpacity(0.4)
                  : Colors.grey[200]!,
              width: _isHovered ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(_isHovered ? 16 : 14),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: badgeInfo.color.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: _isHovered
              ? OverflowBox(
                  alignment: Alignment.topLeft,
                  maxWidth: 280,
                  maxHeight: _expandedHeight,
                  child: SizedBox(
                    width: 280,
                    height: _expandedHeight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildExpandedContent(
                        badgeInfo,
                        badgeName,
                        senderName,
                        message,
                        date,
                        iconUrl,
                      ),
                    ),
                  ),
                )
              : _buildCompactContent(badgeInfo, badgeName, iconUrl),
        ), // AnimatedContainer
      ), // GestureDetector
    ); // MouseRegion
  }

  /// Collapsed state: just icon + badge name
  Widget _buildCompactContent(
      BadgeDisplayInfo badgeInfo, String badgeName, String? iconUrl) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: badgeInfo.color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _buildBadgeIcon(badgeInfo, iconUrl, 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          badgeName,
          style: AppTextStyles.small(color: Colors.grey[700]),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Expanded state: full details with sender, message, date
  Widget _buildExpandedContent(BadgeDisplayInfo badgeInfo, String badgeName,
      String senderName, String? message, String date, String? iconUrl) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: badgeInfo.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _buildBadgeIcon(badgeInfo, iconUrl, 24),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  badgeName,
                  style: AppTextStyles.cardTitle().copyWith(
                    color: badgeInfo.color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'From $senderName',
                        style: AppTextStyles.small(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (message != null && message.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '"$message"',
                    style: AppTextStyles.small(
                      color: Colors.grey[700],
                    ).copyWith(fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: AppTextStyles.small(color: Colors.grey[400]),
                    ),
                    if (widget.recognition.pointsAwarded > 0) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeInfo.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+${widget.recognition.pointsAwarded} pts',
                          style: AppTextStyles.small(
                            color: badgeInfo.color,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon(
      BadgeDisplayInfo badgeInfo, String? iconUrl, double size) {
    if (iconUrl != null) {
      return Image.network(
        iconUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => badgeInfo.hasEmoji
            ? Text(badgeInfo.emoji!, style: AppTextStyles.emoji())
            : Icon(badgeInfo.icon, color: badgeInfo.color, size: size),
      );
    }
    return badgeInfo.hasEmoji
        ? Text(badgeInfo.emoji!, style: AppTextStyles.emoji())
        : Icon(badgeInfo.icon, color: badgeInfo.color, size: size);
  }
}
