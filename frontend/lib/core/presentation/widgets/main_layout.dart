import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import 'package:rr_frontend/core/presentation/models/nav_destination.dart';
import 'package:rr_frontend/core/utils/responsive.dart';
import 'package:rr_frontend/features/notifications/presentation/widgets/notification_bell.dart';

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

  void _showLogoutConfirmation(BuildContext context) {
    if (widget.onLogout == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content:
            const Text('Are you sure you want to log out of the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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
    // Close the drawer if open (mobile)
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  // ── Shared navigation list builder ──────────────────────────────
  Widget _buildNavList(ThemeData theme, {bool inDrawer = false}) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: inDrawer ? 12 : 16),
      shrinkWrap: inDrawer,
      physics: inDrawer ? const NeverScrollableScrollPhysics() : null,
      itemCount: widget.destinations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final destination = widget.destinations[index];
        final isSelected = _selectedIndex == index;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectIndex(index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    destination.icon,
                    size: 20,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      destination.title,
                      style: AppTextStyles.navItem(
                        isSelected: isSelected,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.grey[600],
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

  // ── User profile mini card ──────────────────────────────────────
  Widget _buildUserProfile(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              widget.userName.isNotEmpty
                  ? widget.userName[0].toUpperCase()
                  : 'U',
              style: AppTextStyles.smallBold(color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName,
                    style: AppTextStyles.bodyBold(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                Text(widget.userRole,
                    style: AppTextStyles.caption(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              ],
            ),
          ),
          if (widget.onLogout != null)
            IconButton(
              icon:
                  Icon(Icons.logout_rounded, size: 20, color: Colors.grey[400]),
              onPressed: () => _showLogoutConfirmation(context),
              tooltip: 'Logout',
            ),
        ],
      ),
    );
  }

  // ── Brand header ────────────────────────────────────────────────
  Widget _buildBrand(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Icon(Icons.hub_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            'engage',
            style: AppTextStyles.headline1(color: theme.colorScheme.primary),
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

      // ── Mobile Drawer ─────────────────────────────────────────
      drawer: showSidebar
          ? null
          : Drawer(
              child: SafeArea(
                child: Column(
                  children: [
                    _buildBrand(theme),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildNavList(theme, inDrawer: true),
                    ),
                    const Divider(height: 1),
                    _buildUserProfile(theme),
                  ],
                ),
              ),
            ),

      body: Row(
        children: [
          // ── Desktop Sidebar ─────────────────────────────────────
          if (showSidebar)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  right: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.1)),
                ),
              ),
              child: Column(
                children: [
                  _buildBrand(theme),
                  const SizedBox(height: 20),
                  Expanded(child: _buildNavList(theme)),
                  const Divider(height: 1),
                  _buildUserProfile(theme),
                ],
              ),
            ),

          // ── Main Content ────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: isMobile ? 56 : 70,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 24,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (!showSidebar)
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                        ),
                      if (!isMobile)
                        Expanded(
                          child: Text(
                            'Rewards & Recognition',
                            style: AppTextStyles.headline1(
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      if (isMobile) const Spacer(),
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
