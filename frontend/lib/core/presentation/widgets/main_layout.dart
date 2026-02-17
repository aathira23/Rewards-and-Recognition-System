import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rr_frontend/core/presentation/models/nav_destination.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          if (isDesktop)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
              ),
              child: Column(
                children: [
                  // Logo / Brand
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Icon(Icons.hub_outlined,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          'engage',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Nav Items
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.destinations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final destination = widget.destinations[index];
                        final isSelected = _selectedIndex == index;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _selectedIndex = index),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                        .withValues(alpha: 0.05)
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
                                  Text(
                                    destination.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // User Profile Mini
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.userRole,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (widget.onLogout != null)
                          IconButton(
                            icon: const Icon(Icons.logout_rounded,
                                size: 18, color: Colors.grey),
                            onPressed: widget.onLogout,
                            tooltip: 'Logout',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom:
                          BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (!isDesktop)
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            // TODO: Add Drawer for mobile
                          },
                        ),
                      Text(
                        widget.destinations[_selectedIndex].title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.notifications_none_outlined,
                            size: 24),
                        onPressed: () {},
                      ),
                      if (widget.onLogout != null)
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, size: 24),
                          onPressed: widget.onLogout,
                          tooltip: 'Logout',
                        ),
                    ],
                  ),
                ),
                // Content Area
                Expanded(
                  child: Container(
                    color: const Color(
                        0xFFF8F9FA), // Light grey background for content
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
