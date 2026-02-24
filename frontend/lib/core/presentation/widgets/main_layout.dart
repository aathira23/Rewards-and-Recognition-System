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

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  void _selectIndex(int index) {
    setState(() => _selectedIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: widget.destinations.length,
      itemBuilder: (context, index) {
        final dest = widget.destinations[index];
        final isSelected = _selectedIndex == index;

        return Tooltip(
          message: dest.title,
          preferBelow: false,
          child: InkWell(
            onTap: () => _selectIndex(index),
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon container — white rounded square when selected
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
                  // Label
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
      },
    );
  }

  // ── Row-style nav for mobile drawer ──────────────────────────────
  Widget _buildDrawerNavList(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.destinations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final dest = widget.destinations[index];
        final isSelected = _selectedIndex == index;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectIndex(index),
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

  // ── Compact brand (centered icon only) ───────────────────────────
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

  // ── Compact user avatar at bottom ────────────────────────────────
  Widget _buildCompactUserProfile() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: widget.onLogout != null ? 'Logout' : widget.userName,
            child: GestureDetector(
              onTap: widget.onLogout != null
                  ? () => _showLogoutConfirmation(context)
                  : null,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : 'U',
                  style: AppTextStyles.smallBold(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (widget.onLogout != null)
            GestureDetector(
              onTap: () => _showLogoutConfirmation(context),
              child: Icon(Icons.logout_rounded,
                  size: 14, color: Colors.white.withValues(alpha: 0.45)),
            ),
        ],
      ),
    );
  }

  // ── Full-width brand for mobile drawer ───────────────────────────
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

  // ── Mobile drawer user profile ───────────────────────────────────
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

      // ── Mobile Drawer ───────────────────────────────────────────
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
          // ── Desktop Compact Sidebar ──────────────────────────────
          if (showSidebar)
            Container(
              width: 72,
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

          // ── Main Content ─────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: isMobile ? 60 : 64,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
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
