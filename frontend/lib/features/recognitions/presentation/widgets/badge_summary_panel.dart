import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/badge_utils.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/entities/appreciation_stats_entity.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/entities/recognition_entity.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../bloc/recognitions_bloc.dart';
import '../bloc/recognitions_event.dart';
import 'compact_send_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Badges Earned Summary — horizontal badge icons with counts
// ─────────────────────────────────────────────────────────────────────────────
class BadgesEarnedSummary extends StatelessWidget {
  final AppreciationStatsEntity stats;
  const BadgesEarnedSummary({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final badgeCounts = stats.badgeCounts;
    final badgeIcons = stats.badgeIcons;
    final totalBadges = stats.receivedCount;
    final received = stats.receivedRecognitions ?? [];
    final totalPoints =
        received.fold<int>(0, (sum, r) => sum + r.pointsAwarded);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Badges Earned Summary',
                    style: AppTextStyles.pageTitle()),
              ),
              if (totalBadges > 0) ...[
                _pill('$totalBadges Total', const Color(0xFFEEF2FF),
                    const Color(0xFF4636A6)),
                const SizedBox(width: 8),
                _pill('\u2605 +$totalPoints pts', const Color(0xFFFEF9C3),
                    const Color(0xFFCA8A04)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (badgeCounts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('No badges earned yet',
                        style: AppTextStyles.body(color: Colors.grey[400])),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: badgeCounts.entries.map((entry) {
                  final name = entry.key;
                  final count = entry.value;
                  final iconUrl = badgeIcons[name];
                  final info = BadgeUtils.getDisplayInfo(name);
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      width: 130,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.grey.shade200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: info.color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: _badgeIcon(info, iconUrl, 26),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(name,
                              style: AppTextStyles.smallMedium(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center),
                          if (count > 0) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('$count Received',
                                  style: AppTextStyles.captionBold(
                                      color: const Color(0xFF4636A6))),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: AppTextStyles.captionBold(color: textColor)),
    );
  }

  Widget _badgeIcon(BadgeDisplayInfo info, String? iconUrl, double size) {
    if (iconUrl != null) {
      return Image.network(iconUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _fallbackIcon(info, size));
    }
    return _fallbackIcon(info, size);
  }

  Widget _fallbackIcon(BadgeDisplayInfo info, double size) {
    return info.hasEmoji
        ? Text(info.emoji!, style: TextStyle(fontSize: size * 0.7))
        : Icon(info.icon, color: info.color, size: size);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  My eCards Panel — carousel of received eCards
// ─────────────────────────────────────────────────────────────────────────────
class MyEcardsPanel extends StatefulWidget {
  final AppreciationStatsEntity stats;
  const MyEcardsPanel({super.key, required this.stats});
  @override
  State<MyEcardsPanel> createState() => _MyEcardsPanelState();
}

class _MyEcardsPanelState extends State<MyEcardsPanel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final received = (widget.stats.receivedRecognitions ?? [])
        .where((r) => (r.sourceType ?? '').toUpperCase() != 'AWARD')
        .toList();
    final cardCount = received.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My eCards', style: AppTextStyles.pageTitle()),
          const SizedBox(height: 16),
          if (received.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mail_outline_rounded,
                        size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('No eCards received yet',
                        style: AppTextStyles.body(color: Colors.grey[400])),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 270,
              child: PageView.builder(
                controller: _pageController,
                itemCount: cardCount,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) =>
                    _EcardPreviewCard(recognition: received[index]),
              ),
            ),
            if (cardCount > 1) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  cardCount,
                  (i) => Container(
                    width: _currentPage == i ? 10 : 8,
                    height: _currentPage == i ? 10 : 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? const Color(0xFF4636A6)
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _EcardPreviewCard extends StatelessWidget {
  final RecognitionEntity recognition;
  const _EcardPreviewCard({required this.recognition});

  @override
  Widget build(BuildContext context) {
    final badgeName = recognition.badge?.name ?? 'Badge';
    final info = BadgeUtils.getDisplayInfo(badgeName);
    final receiverName = recognition.receiverName ?? 'You';
    final senderName = recognition.senderName ?? 'Someone';
    final message = recognition.message;
    final timeAgo = _timeAgo(recognition.createdAt);

    final badgeColor = info.color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // ── Section 1: Badge color background ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: badgeColor.withValues(alpha: 0.08),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: recognition.badge?.iconUrl != null
                        ? Image.network(recognition.badge!.iconUrl!,
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _fallbackIcon(info))
                        : _fallbackIcon(info),
                  ),
                ),
                const SizedBox(height: 8),
                Text('${badgeName.toUpperCase()} !!!',
                    style: AppTextStyles.captionBold(color: badgeColor)
                        .copyWith(fontSize: 13, letterSpacing: 0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // ── Section 2: White background — TO, name, underline, message ──
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              color: Colors.white,
              child: Column(
                children: [
                  Text('TO',
                      style: AppTextStyles.caption(color: Colors.grey[400])
                          .copyWith(fontSize: 11, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(receiverName,
                      style: AppTextStyles.bodyBold().copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                  if (message != null && message.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('"$message"',
                        style: AppTextStyles.small(color: Colors.grey[600])
                            .copyWith(fontStyle: FontStyle.italic, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center),
                  ],
                  const Spacer(),
                ],
              ),
            ),
          ),
          // ── Section 3: #F9FAFB background — sender & date ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFFF9FAFB),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text('By - $senderName',
                      style: AppTextStyles.small(color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Text(timeAgo,
                    style: AppTextStyles.small(color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon(BadgeDisplayInfo info) {
    return info.hasEmoji
        ? Text(info.emoji!, style: const TextStyle(fontSize: 22))
        : Icon(info.icon, color: info.color, size: 26);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Feed Panel — compact activity feed
// ─────────────────────────────────────────────────────────────────────────────
class EcardFeedPanel extends StatelessWidget {
  final List<RecognitionEntity> feed;
  const EcardFeedPanel({super.key, required this.feed});

  @override
  Widget build(BuildContext context) {
    final filteredFeed = feed.where((r) => (r.sourceType ?? '').toUpperCase() != 'AWARD').toList();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Feed', style: AppTextStyles.pageTitle()),
          const SizedBox(height: 16),
          if (filteredFeed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No recent activity',
                    style: AppTextStyles.body(color: Colors.grey[400])),
              ),
            )
          else
            SizedBox(
              height: 230,
              child: ListView.separated(
                clipBehavior: Clip.hardEdge,
                itemCount: filteredFeed.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _FeedItem(recognition: filteredFeed[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedItem extends StatelessWidget {
  final RecognitionEntity recognition;
  const _FeedItem({required this.recognition});

  @override
  Widget build(BuildContext context) {
    final senderName = recognition.senderName ?? 'Someone';
    final receiverName = recognition.receiverName ?? 'Someone';
    final badgeName = recognition.badge?.name ?? 'Badge';
    final info = BadgeUtils.getDisplayInfo(badgeName);
    final timeAgo = _timeAgo(recognition.createdAt);
    final points = recognition.pointsAwarded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with points badge overlay
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: info.color.withValues(alpha: 0.12),
                child: Text(senderName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                        color: info.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
              if (points > 0)
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: info.color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text('$points',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.small(color: Colors.black87)
                        .copyWith(height: 1.4),
                    children: [
                      TextSpan(
                          text: senderName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' sent a '),
                      TextSpan(
                          text: '$badgeName !!!',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: info.color)),
                      const TextSpan(text: ' to '),
                      TextSpan(
                          text: receiverName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(timeAgo,
                    style: AppTextStyles.caption(color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Send an eCard — badge grid panel
// ─────────────────────────────────────────────────────────────────────────────
class SendEcardPanel extends StatelessWidget {
  final AppreciationStatsEntity? stats;
  final List<BadgeEntity> badges;
  final List<UserEntity> users;

  const SendEcardPanel({
    super.key,
    required this.stats,
    required this.badges,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    final sentCount = stats?.sentCount ?? 0;

    final sortedBadges = List<BadgeEntity>.from(badges)
      ..sort((a, b) => a.name.compareTo(b.name));
    final displayBadges = BadgeUtils.interleaveByColor<BadgeEntity>(
      sortedBadges,
      (b) => b.name,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
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
                    Text('Send an eCard', style: AppTextStyles.pageTitle()),
                    const SizedBox(height: 8),
                    Text('Select a badge to start creating your eCard',
                        style: AppTextStyles.body(color: Colors.grey[500])),
                  ],
                ),
              ),
              Text('$sentCount eCards Sent',
                  style:
                      AppTextStyles.bodyBold(color: const Color(0xFF4636A6))),
            ],
          ),
          const SizedBox(height: 40),
          // Badge grid
          if (badges.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No badges available',
                    style: AppTextStyles.body(color: Colors.grey[400])),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemCount: displayBadges.length,
              itemBuilder: (ctx, i) {
                final badge = displayBadges[i];
                return _SendBadgeCard(
                  badge: badge,
                  onTap: () => _openSendDialog(context, badge),
                );
              },
            ),
        ],
      ),
    );
  }

  void _openSendDialog(BuildContext context, BadgeEntity badge) {
    showDialog(
      context: context,
      builder: (dialogCtx) => BadgePickerDialog(
        badges: badges,
        users: users,
        outerContext: context,
        initialBadge: badge,
      ),
    );
  }
}

class _SendBadgeCard extends StatefulWidget {
  final BadgeEntity badge;
  final VoidCallback onTap;
  const _SendBadgeCard({required this.badge, required this.onTap});
  @override
  State<_SendBadgeCard> createState() => _SendBadgeCardState();
}

class _SendBadgeCardState extends State<_SendBadgeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final info = BadgeUtils.getDisplayInfo(widget.badge.name);
    final pts = widget.badge.points;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: _hovered ? info.color.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? info.color.withValues(alpha: 0.4)
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: widget.badge.iconUrl != null
                      ? Image.network(widget.badge.iconUrl!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _fallback(info))
                      : _fallback(info),
                ),
              ),
              const SizedBox(height: 8),
              Text('${widget.badge.name} !!!',
                  style: AppTextStyles.small(color: Colors.grey[800]),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              if (pts != null && pts > 0)
                Text('$pts pts',
                    style: AppTextStyles.caption(color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback(BadgeDisplayInfo info) {
    return info.hasEmoji
        ? Text(info.emoji!, style: const TextStyle(fontSize: 18))
        : Icon(info.icon, color: info.color, size: 22);
  }
}

// _SendFormDialog replaced by BadgePickerDialog from compact_send_panel.dart

// ─────────────────────────────────────────────────────────────────────────────
//  eCard History Table — All / Received / Sent tabs
// ─────────────────────────────────────────────────────────────────────────────
class EcardHistoryTable extends StatefulWidget {
  final AppreciationStatsEntity stats;
  const EcardHistoryTable({super.key, required this.stats});
  @override
  State<EcardHistoryTable> createState() => _EcardHistoryTableState();
}

class _EcardHistoryTableState extends State<EcardHistoryTable> {
  int _selectedTab = 0; // 0=All, 1=Received, 2=Sent
  int _page = 1;
  static const _perPage = 5;

  @override
  Widget build(BuildContext context) {
    final received = (widget.stats.receivedRecognitions ?? [])
        .map((r) => _HistoryEntry(type: 'RECEIVED', recognition: r))
        .toList();
    final sent = (widget.stats.sentRecognitions ?? [])
        .map((r) => _HistoryEntry(type: 'SENT', recognition: r))
        .toList();

    List<_HistoryEntry> allItems;
    switch (_selectedTab) {
      case 1:
        allItems = received;
        break;
      case 2:
        allItems = sent;
        break;
      default:
        allItems = [...received, ...sent]..sort((a, b) =>
            b.recognition.createdAt.compareTo(a.recognition.createdAt));
    }

    final total = allItems.length;
    final startIndex = (_page - 1) * _perPage;
    final endIndex = (startIndex + _perPage).clamp(0, total);
    final pageItems =
        total > 0 ? allItems.sublist(startIndex, endIndex) : <_HistoryEntry>[];
    final hasPrev = _page > 1;
    final hasNext = endIndex < total;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with tabs
          Row(
            children: [
              Text('eCard History', style: AppTextStyles.pageTitle()),
              const Spacer(),
              _tabBtn('All', 0),
              const SizedBox(width: 4),
              _tabBtn('Received', 1),
              const SizedBox(width: 4),
              _tabBtn('Sent', 2),
            ],
          ),
          const SizedBox(height: 20),
          // Table header
          _headerRow(),
          const SizedBox(height: 4),
          if (pageItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                  child: Text('No eCards yet',
                      style: AppTextStyles.body(color: Colors.grey[400]))),
            )
          else
            ...pageItems.map(_buildRow),
          // Pagination footer
          if (total > _perPage) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Text(
                    'Showing ${startIndex + 1}\u2013$endIndex of $total records',
                    style: AppTextStyles.caption(color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  _PageBtn(
                    icon: Icons.chevron_left,
                    enabled: hasPrev,
                    onTap: hasPrev ? () => setState(() => _page--) : null,
                  ),
                  const SizedBox(width: 6),
                  _PageBtn(
                    icon: Icons.chevron_right,
                    enabled: hasNext,
                    onTap: hasNext ? () => setState(() => _page++) : null,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTab = index;
        _page = 1;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? const Color(0xFF4F46E5) : Colors.grey.shade300),
        ),
        child: Text(label,
            style: AppTextStyles.smallMedium(
                color: selected ? Colors.white : Colors.grey[600])),
      ),
    );
  }

  Widget _headerRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                  width: w * 0.10, child: Text('TYPE', style: _headerStyle())),
              SizedBox(
                  width: w * 0.28,
                  child: Text('BADGE (ECARD)', style: _headerStyle())),
              SizedBox(
                  width: w * 0.28,
                  child: Text('PERSON', style: _headerStyle())),
              SizedBox(
                  width: w * 0.18, child: Text('DATE', style: _headerStyle())),
              SizedBox(
                  width: w * 0.10,
                  child: Text('POINTS',
                      style: _headerStyle(), textAlign: TextAlign.right)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(_HistoryEntry item) {
    final r = item.recognition;
    final badgeName = r.badge?.name ?? 'Badge';
    final info = BadgeUtils.getDisplayInfo(badgeName);
    final pillStyle = BadgeUtils.getPillStyle(badgeName);
    final isReceived = item.type == 'RECEIVED';
    final personLabel = isReceived
        ? 'From:${r.senderName ?? "Someone"}'
        : 'To:${r.receiverName ?? "Someone"}';
    final date = DateFormat('MMM d, yyyy').format(r.createdAt);
    final points = r.pointsAwarded;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              // Type pill
              SizedBox(
                width: w * 0.10,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isReceived
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.type,
                      style: AppTextStyles.captionBold(
                          color: isReceived
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF2563EB)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              // Badge
              SizedBox(
                width: w * 0.28,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: info.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: r.badge?.iconUrl != null
                            ? Image.network(r.badge!.iconUrl!,
                                width: 16,
                                height: 16,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                    pillStyle.icon,
                                    size: 14,
                                    color: info.color))
                            : Icon(pillStyle.icon, size: 14, color: info.color),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(badgeName,
                          style: AppTextStyles.smallMedium(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              // Person
              SizedBox(
                width: w * 0.28,
                child: Text(personLabel,
                    style: AppTextStyles.small(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              // Date
              SizedBox(
                  width: w * 0.18,
                  child: Text(date,
                      style: AppTextStyles.small(color: Colors.grey[600]))),
              // Points
              SizedBox(
                width: w * 0.10,
                child: Text(
                  isReceived && points > 0 ? '+$points' : '-',
                  style: AppTextStyles.smallMedium(
                      color: isReceived && points > 0
                          ? const Color(0xFF16A34A)
                          : Colors.grey[400]),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  TextStyle _headerStyle() => AppTextStyles.captionBold(color: Colors.grey[500])
      .copyWith(letterSpacing: 0.5);
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  const _PageBtn({required this.icon, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
    );
  }
}

class _HistoryEntry {
  final String type;
  final RecognitionEntity recognition;
  _HistoryEntry({required this.type, required this.recognition});
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared helpers
// ─────────────────────────────────────────────────────────────────────────────
BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays >= 7) return DateFormat.yMMMd().format(date);
  if (diff.inDays >= 2) return '${diff.inDays} days ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inHours >= 1) return '${diff.inHours}h ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
  return 'Just now';
}
