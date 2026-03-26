import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/badge_utils.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/entities/appreciation_stats_entity.dart';
import '../../../profile/domain/entities/user_entity.dart';
import '../bloc/recognitions_bloc.dart';
import '../bloc/recognitions_event.dart';
import 'sent_recognitions_list.dart';
import '../bloc/recognitions_state.dart';

/// A compact card on the left column.
/// Shows total sent + last-used badges.
/// "Send New" button opens a full badge-picker + send dialog.
class CompactSendPanel extends StatelessWidget {
  final AppreciationStatsEntity? stats;
  final List<BadgeEntity> badges;
  final List<UserEntity> users;

  const CompactSendPanel({
    super.key,
    required this.stats,
    required this.badges,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    final sentCount = stats?.sentCount ?? 0;
    const brandBlue = Color(0xFF1A60FF);

    // ── Limit / cooldown state ──────────────────────────────────
    final int? monthlyLimit = stats?.monthlyLimit;
    final int monthlySent = stats?.monthlySent ?? 0;
    final DateTime? nextAvailableAt = stats?.nextAvailableAt;
    final bool limitReached =
        monthlyLimit != null && monthlySent >= monthlyLimit;
    final bool onCooldown =
        nextAvailableAt != null && DateTime.now().isBefore(nextAvailableAt);
    final bool canSend = badges.isNotEmpty && !limitReached && !onCooldown;

    // Collect up to 5 recent unique badges with their entities
    final rawRecent = <_RecentBadge>[];
    for (final r in stats?.sentRecognitions ?? []) {
      if (r.badge == null) continue;
      final already = rawRecent.any((rb) => rb.name == r.badge!.name);
      if (!already) {
        rawRecent.add(_RecentBadge(
          name: r.badge!.name,
          iconUrl: r.badge!.iconUrl,
        ));
        if (rawRecent.length == 5) break;
      }
    }

    // Sort alphabetically then interleave for visual diversity and consistency
    // with the "Received" panel order.
    final recentBadges = BadgeUtils.interleaveByColor<_RecentBadge>(
      rawRecent..sort((a, b) => a.name.compareTo(b.name)),
      (rb) => rb.name,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Appreciations Sent',
                  style: AppTextStyles.pageTitle(),
                ),
                const Spacer(),
                // Pills sit right next to "View all"
                _StatusPills(
                  monthlyLimit: monthlyLimit,
                  monthlySent: monthlySent,
                  limitReached: limitReached,
                  onCooldown: onCooldown,
                  nextAvailableAt: nextAvailableAt,
                  brandBlue: brandBlue,
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showSentHistory(context),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View all',
                    style: AppTextStyles.bodyBold(color: brandBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Recognitions you have given to colleagues',
              style: AppTextStyles.body(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // ── Stat + recently-used row ────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: brandBlue.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: brandBlue.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  // Left: icon + big number (takes all available space)
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: brandBlue.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded,
                              color: brandBlue, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$sentCount',
                              style:
                                  AppTextStyles.sectionHeader(color: brandBlue)
                                      .copyWith(fontSize: 26),
                            ),
                            Text(
                              'Total Sent',
                              style: AppTextStyles.caption(
                                  color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  if (recentBadges.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Container(
                        width: 1,
                        height: 44,
                        color: brandBlue.withValues(alpha: 0.12)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Recently used',
                          style: AppTextStyles.caption(
                              color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: recentBadges.map((rb) {
                            final info = BadgeUtils.getDisplayInfo(rb.name);
                            return Tooltip(
                              message: rb.name,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: info.color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: info.color.withValues(alpha: 0.3)),
                                ),
                                child: Center(
                                  child: rb.iconUrl != null
                                      ? ClipOval(
                                          child: Image.network(
                                            rb.iconUrl!,
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                info.hasEmoji
                                                    ? Text(
                                                        info.emoji!,
                                                        style: const TextStyle(
                                                            fontSize: 14),
                                                      )
                                                    : Icon(info.icon,
                                                        color: info.color,
                                                        size: 16),
                                          ),
                                        )
                                      : (info.hasEmoji
                                          ? Text(info.emoji!,
                                              style:
                                                  const TextStyle(fontSize: 14))
                                          : Icon(info.icon,
                                              color: info.color, size: 16)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Send button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canSend ? () => _showBadgePicker(context) : null,
                icon: Icon(
                  limitReached
                      ? Icons.block_rounded
                      : onCooldown
                          ? Icons.timer_outlined
                          : Icons.add_reaction_outlined,
                  size: 18,
                ),
                label: Text(
                  limitReached
                      ? 'Monthly Limit Reached'
                      : onCooldown
                          ? 'Cooldown Active'
                          : 'Send New Appreciation',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Full-screen badge picker — user taps a badge then fills in details.
  void _showBadgePicker(BuildContext outerContext) {
    showDialog(
      context: outerContext,
      builder: (dialogCtx) => BadgePickerDialog(
        badges: badges,
        users: users,
        outerContext: outerContext,
      ),
    );
  }

  void _showSentHistory(BuildContext context) {
    final bloc = context.read<RecognitionsBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AppDialog(
          title: 'Appreciations Sent',
          maxWidth: 600,
          content: BlocBuilder<RecognitionsBloc, RecognitionsState>(
            builder: (context, state) {
              final recognitions = state.stats?.sentRecognitions ?? [];
              return SentRecognitionsList(recognitions: recognitions);
            },
          ),
        ),
      ),
    );
  }
}

/// Simple data holder for a recently-used badge
class _RecentBadge {
  final String name;
  final String? iconUrl;
  _RecentBadge({required this.name, this.iconUrl});
}

// ─────────────────────────────────────────────────────────────────────────────
// Status pills row — shown below the card subtitle
// ─────────────────────────────────────────────────────────────────────────────
class _StatusPills extends StatelessWidget {
  final int? monthlyLimit;
  final int monthlySent;
  final bool limitReached;
  final bool onCooldown;
  final DateTime? nextAvailableAt;
  final Color brandBlue;

  const _StatusPills({
    required this.monthlyLimit,
    required this.monthlySent,
    required this.limitReached,
    required this.onCooldown,
    required this.nextAvailableAt,
    required this.brandBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (monthlyLimit != null) _monthlyPill(),
        _cooldownPill(), // always shown — green "Ready" when not on cooldown
      ],
    );
  }

  Widget _monthlyPill() {
    final ratio = (monthlySent / monthlyLimit!).clamp(0.0, 1.0);
    final remaining = (monthlyLimit! - monthlySent).clamp(0, monthlyLimit!);
    final isNearLimit = ratio >= 0.8;

    final Color fg;
    final Color bg;
    if (limitReached) {
      fg = const Color(0xFFDC2626);
      bg = const Color(0xFFDC2626);
    } else if (isNearLimit) {
      fg = const Color(0xFFD97706);
      bg = const Color(0xFFD97706);
    } else {
      fg = brandBlue;
      bg = brandBlue;
    }

    final label = limitReached
        ? 'Limit Reached · $monthlySent / $monthlyLimit'
        : '$monthlySent / $monthlyLimit · $remaining left';

    final tooltipMsg = limitReached
        ? 'Monthly limit reached. You can send again next month.'
        : isNearLimit
            ? 'Almost at your monthly limit — only $remaining eCard${remaining == 1 ? '' : 's'} left this month.'
            : 'Monthly eCards: $monthlySent sent, $remaining remaining this month.';

    return Tooltip(
        message: tooltipMsg,
        preferBelow: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: fg.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                limitReached
                    ? Icons.block_rounded
                    : isNearLimit
                        ? Icons.warning_amber_rounded
                        : Icons.calendar_month_outlined,
                size: 13,
                color: fg,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ));
  }

  Widget _cooldownPill() {
    if (!onCooldown || nextAvailableAt == null) {
      // Ready state — green
      return Tooltip(
        message: 'No cooldown active — you can send an appreciation right now.',
        preferBelow: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF34D399).withValues(alpha: 0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 13, color: Color(0xFF059669)),
              SizedBox(width: 5),
              Text(
                'Ready',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final diff = nextAvailableAt!.difference(now);
    final String timeLeft;
    if (diff.inHours >= 24) {
      final days = diff.inDays;
      timeLeft = '$days day${days == 1 ? '' : 's'}';
    } else if (diff.inHours >= 1) {
      timeLeft = '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    } else {
      timeLeft = '${diff.inMinutes + 1} min';
    }

    const fg = Color(0xFFD97706);
    return Tooltip(
      message:
          'You sent appreciations too quickly. Wait $timeLeft before sending again.',
      preferBelow: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, size: 13, color: fg),
            const SizedBox(width: 5),
            Text(
              'Cooldown: $timeLeft',
              style: const TextStyle(
                  fontSize: 12, color: fg, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class BadgePickerDialog extends StatefulWidget {
  final List<BadgeEntity> badges;
  final List<UserEntity> users;
  final BuildContext outerContext;

  const BadgePickerDialog({
    super.key,
    required this.badges,
    required this.users,
    required this.outerContext,
  });

  @override
  State<BadgePickerDialog> createState() => _BadgePickerDialogState();
}

class _BadgePickerDialogState extends State<BadgePickerDialog> {
  BadgeEntity? _selected;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: _selected == null ? 'Choose a Badge' : 'Send Appreciation',
      maxWidth: 600,
      showCloseButton: false,
      content: _selected == null ? _buildBadgeGrid() : _buildSendForm(context),
      actions: _selected == null
          ? [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ]
          : const [], // actions live inside the form for step 2
    );
  }

  Widget _buildBadgeGrid() {
    // 1. Sort by name for stability
    final sortedBadges = List<BadgeEntity>.from(widget.badges)
      ..sort((a, b) => a.name.compareTo(b.name));

    // 2. Interleave for visual diversity
    final displayBadges = BadgeUtils.interleaveByColor<BadgeEntity>(
      sortedBadges,
      (b) => b.name,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.75,
      ),
      itemCount: displayBadges.length,
      itemBuilder: (ctx, i) {
        final badge = displayBadges[i];
        return _PickerBadgeCard(
          badge: badge,
          onTap: () => setState(() => _selected = badge),
        );
      },
    );
  }

  Widget _buildSendForm(BuildContext context) {
    final badge = _selected!;
    final info = BadgeUtils.getDisplayInfo(badge.name);
    int? receiverId;
    String? message;

    return StatefulBuilder(
      builder: (ctx, setLocal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Selected badge banner ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: info.color.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: info.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: badge.iconUrl != null
                          ? Image.network(
                              badge.iconUrl!,
                              width: 34,
                              height: 34,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => info.hasEmoji
                                  ? Text(info.emoji!,
                                      style: const TextStyle(fontSize: 22))
                                  : Icon(info.icon,
                                      color: info.color, size: 28),
                            )
                          : (info.hasEmoji
                              ? Text(info.emoji!,
                                  style: const TextStyle(fontSize: 22))
                              : Icon(info.icon, color: info.color, size: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.name,
                          style: AppTextStyles.sectionHeader(color: info.color),
                        ),
                        if (badge.description != null &&
                            badge.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            badge.description!,
                            style: AppTextStyles.small(color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (badge.points != null && badge.points! > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: info.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+${badge.points} pts',
                              style:
                                  AppTextStyles.captionBold(color: info.color),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Back / change badge
                  IconButton(
                    tooltip: 'Change badge',
                    icon: Icon(Icons.swap_horiz_rounded,
                        color: info.color.withValues(alpha: 0.7)),
                    onPressed: () => setState(() => _selected = null),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── Recipient ──────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text('Recipient', style: AppTextStyles.sectionTitle()),
              ],
            ),
            const SizedBox(height: 8),
            DropdownMenu<int>(
              expandedInsets: EdgeInsets.zero,
              menuHeight: 250,
              inputDecorationTheme: InputDecorationTheme(
                hintStyle: AppTextStyles.body(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              hintText: 'Search employee name...',
              dropdownMenuEntries: widget.users.map((u) {
                return DropdownMenuEntry<int>(value: u.id, label: u.name);
              }).toList(),
              onSelected: (v) => receiverId = v,
              textStyle: AppTextStyles.body(),
            ),

            const SizedBox(height: 20),

            // ── Message ────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.edit_note_rounded,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text('Message', style: AppTextStyles.sectionTitle()),
                const SizedBox(width: 6),
                Text('(optional)',
                    style: AppTextStyles.caption(color: Colors.grey.shade400)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              style: AppTextStyles.body(),
              decoration: InputDecoration(
                hintText: 'Tell them why they deserve this recognition…',
                hintStyle: AppTextStyles.body(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 4,
              onChanged: (v) => message = v,
            ),

            const SizedBox(height: 24),

            // ── Action row ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _selected = null),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (receiverId == null) {
                        AppSnackbar.warning(ctx, 'Please select a recipient.');
                        return;
                      }
                      widget.outerContext
                          .read<RecognitionsBloc>()
                          .add(SendRecognitionRequested(
                            receiverId: receiverId!,
                            badgeId: _selected!.id,
                            message: message,
                          ));
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Send Recognition'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Single badge card inside the picker grid
class _PickerBadgeCard extends StatefulWidget {
  final BadgeEntity badge;
  final VoidCallback onTap;

  const _PickerBadgeCard({required this.badge, required this.onTap});

  @override
  State<_PickerBadgeCard> createState() => _PickerBadgeCardState();
}

class _PickerBadgeCardState extends State<_PickerBadgeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final info = BadgeUtils.getDisplayInfo(widget.badge.name);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _hovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _hovered
                  ? info.color.withValues(alpha: 0.07)
                  : Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: _hovered
                    ? info.color.withValues(alpha: 0.5)
                    : Colors.grey.shade200,
                width: _hovered ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (_hovered)
                  BoxShadow(
                    color: info.color.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: widget.badge.iconUrl != null
                        ? Image.network(
                            widget.badge.iconUrl!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => info.hasEmoji
                                ? Text(info.emoji!,
                                    style: AppTextStyles.emoji())
                                : Icon(info.icon, color: info.color, size: 28),
                          )
                        : (info.hasEmoji
                            ? Text(info.emoji!, style: AppTextStyles.emoji())
                            : Icon(info.icon, color: info.color, size: 28)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.badge.name,
                  style: AppTextStyles.small(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.badge.points != null &&
                    widget.badge.points! > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+${widget.badge.points} pts',
                    style: AppTextStyles.captionBold(color: info.color),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
