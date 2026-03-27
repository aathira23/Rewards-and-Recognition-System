import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import 'package:rr_frontend/core/theme/app_theme.dart';
import 'package:rr_frontend/core/presentation/models/nav_destination.dart';
import 'package:rr_frontend/core/utils/responsive.dart';
import 'package:rr_frontend/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:rr_frontend/core/widgets/app_dialog.dart';

class MainLayout extends StatefulWidget {
  final List<NavDestination> destinations;
  final int initialIndex;
  final String userName;
  final String userRole;
  final VoidCallback? onLogout;

  const MainLayout({
    super.key,
    required this.destinations,
    required this.userName,
    required this.userRole,
    this.initialIndex = 0,
    this.onLogout,
  });

  static MainLayoutState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainLayoutState>();
  }

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Overlay for user profile popup
  final GlobalKey _avatarKey = GlobalKey();
  OverlayEntry? _profileOverlay;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= widget.destinations.length) {
      _selectedIndex = 0;
    }
  }

  @override
  void dispose() {
    _removeProfileOverlay();
    super.dispose();
  }

  void selectIndex(int index) {
    setState(() => _selectedIndex = index);
    _removeProfileOverlay();
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void selectTabByTitle(String title) {
    final idx = widget.destinations.indexWhere((d) => d.title == title);
    if (idx != -1) selectIndex(idx);
  }

  // ── Profile overlay ────────────────────────────────────────────────
  void _removeProfileOverlay() {
    _profileOverlay?.remove();
    _profileOverlay = null;
  }

  void _toggleProfilePopup() {
    if (_profileOverlay != null) {
      _removeProfileOverlay();
      if (mounted) setState(() {});
      return;
    }

    final box = _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final pos = box.localToGlobal(Offset.zero);
    final sz = box.size;

    _profileOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Tap-outside barrier
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _removeProfileOverlay();
                if (mounted) setState(() {});
              },
              child: const SizedBox.expand(),
            ),
          ),
          // Popup card — positioned to the right of the avatar
          Positioned(
            left: pos.dx + sz.width + 10,
            bottom: MediaQuery.of(context).size.height - pos.dy - sz.height,
            child: _ProfilePopupCard(
              userName: widget.userName,
              userRole: widget.userRole,
              onLogout: widget.onLogout != null
                  ? () {
                      _removeProfileOverlay();
                      if (mounted) setState(() {});
                      _showLogoutConfirmation(context);
                    }
                  : null,
              onClose: () {
                _removeProfileOverlay();
                if (mounted) setState(() {});
              },
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_profileOverlay!);
    if (mounted) setState(() {});
  }

  void _showLogoutConfirmation(BuildContext context) {
    if (widget.onLogout == null) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Confirm Logout',
        maxWidth: 400,
        showCloseButton: false,
        content: Text(
          'Are you sure you want to log out of the application?',
          style: AppTextStyles.bodyLarge(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel',
                style: AppTextStyles.bodyBold(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onLogout!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text('Logout',
                style: AppTextStyles.bodyBold(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Compact icon+label sidebar nav (desktop) ──────────────────────
  Widget _buildCompactNavList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        for (int index = 0; index < widget.destinations.length; index++)
          if (!widget.destinations[index].isHidden)
            _buildCompactNavItem(index, widget.destinations[index]),
      ],
    );
  }

  Widget _buildCompactNavItem(int index, NavDestination dest) {
    final isSelected = _selectedIndex == index;

    return Tooltip(
      message: dest.title,
      preferBelow: false,
      child: InkWell(
        onTap: () => selectIndex(index),
        splashColor: Colors.white.withValues(alpha: 0.1),
        highlightColor: Colors.white.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  dest.icon,
                  size: 22,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dest.title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.55),
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Row-style nav for mobile drawer ──────────────────────────────
  Widget _buildDrawerNavList(ThemeData theme) {
    final visibleIndices = <int>[];
    for (int i = 0; i < widget.destinations.length; i++) {
        if (!widget.destinations[i].isHidden) visibleIndices.add(i);
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleIndices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, listIndex) {
        final index = visibleIndices[listIndex];
        final dest = widget.destinations[index];
        final isSelected = _selectedIndex == index;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => selectIndex(index),
            borderRadius: BorderRadius.circular(8),
            splashColor: Colors.white.withValues(alpha: 0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(dest.icon,
                      size: 20,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      dest.title,
                      style: AppTextStyles.navItem(
                        isSelected: isSelected,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.65),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Compact brand ─────────────────────────────────────────────────
  Widget _buildCompactBrand() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.hub_outlined, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  // ── Compact user avatar — clicking opens popup ────────────────────
  Widget _buildCompactUserProfile() {
    final isPopupOpen = _profileOverlay != null;
    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: _avatarKey,
            onTap: _toggleProfilePopup,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPopupOpen
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                  width: isPopupOpen ? 2 : 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: isPopupOpen
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.18),
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : 'U',
                  style: AppTextStyles.smallBold(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Mobile drawer brand + user ────────────────────────────────────
  Widget _buildDrawerBrand() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          const Icon(Icons.hub_outlined, color: Colors.white),
          const SizedBox(width: 12),
          Text('engage', style: AppTextStyles.headline1(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildDrawerUserProfile() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              widget.userName.isNotEmpty
                  ? widget.userName[0].toUpperCase()
                  : 'U',
              style: AppTextStyles.smallBold(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName,
                    style: AppTextStyles.bodyBold(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                Text(widget.userRole,
                    style: AppTextStyles.caption(
                        color: Colors.white.withValues(alpha: 0.6)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              ],
            ),
          ),
          if (widget.onLogout != null)
            IconButton(
              icon: Icon(Icons.logout_rounded,
                  size: 20, color: Colors.white.withValues(alpha: 0.6)),
              onPressed: () => _showLogoutConfirmation(context),
              tooltip: 'Logout',
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSidebar = Responsive.showSidebar(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,

      // ── Mobile Drawer ─────────────────────────────────────────────
      drawer: showSidebar
          ? null
          : Drawer(
              backgroundColor: AppTheme.brandSecondary,
              child: SafeArea(
                child: Column(
                  children: [
                    _buildDrawerBrand(),
                    Divider(
                        height: 1, color: Colors.white.withValues(alpha: 0.12)),
                    const SizedBox(height: 8),
                    Expanded(child: _buildDrawerNavList(theme)),
                    _buildDrawerUserProfile(),
                  ],
                ),
              ),
            ),

      body: Row(
        children: [
          // ── Desktop Compact Sidebar ────────────────────────────────
          if (showSidebar)
            Container(
              width: 75,
              color: AppTheme.brandSecondary,
              child: Column(
                children: [
                  _buildCompactBrand(),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: 0.12)),
                  const SizedBox(height: 4),
                  Expanded(child: _buildCompactNavList()),
                  _buildCompactUserProfile(),
                ],
              ),
            ),

          // ── Main Content ───────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: isMobile ? 60 : 64,
                  padding: EdgeInsets.only(
                    // Remove the left inset when the mobile drawer (no sidebar)
                    // is used so the hamburger icon can sit at the extreme left.
                    left: !showSidebar ? 0 : (isMobile ? 16 : 24),
                    right: isMobile ? 16 : 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandBlue,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (!showSidebar)
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.destinations[_selectedIndex].heading ??
                                  widget.destinations[_selectedIndex].title,
                              style:
                                  AppTextStyles.headline1(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            if (widget.destinations[_selectedIndex].subtitle !=
                                null) ...[
                              const SizedBox(height: 1),
                              Text(
                                widget.destinations[_selectedIndex].subtitle!,
                                style: AppTextStyles.small(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const NotificationBell(),
                    ],
                  ),
                ),
                // Content Area
                Expanded(
                  child: Container(
                    color: theme.colorScheme.surfaceContainer,
                    child: widget.destinations[_selectedIndex].page,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile popup card — appears to the right of the avatar
// ─────────────────────────────────────────────────────────────────────────────

class _ProfilePopupCard extends StatelessWidget {
  final String userName;
  final String userRole;
  final VoidCallback? onLogout;
  final VoidCallback onClose;

  const _ProfilePopupCard({
    required this.userName,
    required this.userRole,
    required this.onLogout,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(14),
      shadowColor: Colors.black.withValues(alpha: 0.18),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── User info header ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: AppTheme.brandSecondary.withValues(alpha: 0.06),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        AppTheme.brandSecondary.withValues(alpha: 0.15),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: AppTextStyles.sectionTitle(
                          color: AppTheme.brandSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: AppTextStyles.bodyBold(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userRole,
                          style: AppTextStyles.caption(
                              color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Logout row ──
            if (onLogout != null)
              InkWell(
                onTap: onLogout,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.logout_rounded,
                            size: 16, color: Colors.red.shade600),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Logout',
                        style:
                            AppTextStyles.bodyBold(color: Colors.red.shade600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
