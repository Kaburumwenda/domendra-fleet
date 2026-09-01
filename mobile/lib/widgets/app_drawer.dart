import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../models/nav_model.dart';
import '../providers/auth_provider.dart';

/// The main navigation drawer — mirrors the web `AppSidebar.vue`.
///
/// Key design details replicated from the web:
///   - Flat surface background (no gradient hero), box-shadow
///   - Gradient logo box (indigo→purple) with app name
///   - Section labels (MAIN, ASSETS, MAINTENANCE, FLEET, INSIGHTS, OPERATIONS, SYSTEM)
///   - Expandable groups with a vertical connector line + indented children
///   - Active item uses indigo→purple gradient background (not just a tint)
///   - User panel at the bottom with gradient avatar + logout button
class AppDrawer extends StatefulWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  /// Tracks which groups are expanded.
  final Set<String> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    // Auto-expand the group containing the current route
    for (final item in NavModel.items) {
      if (item.isGroup) {
        for (final child in item.children!) {
          if (child.route != null && widget.currentRoute.startsWith(child.route!)) {
            _expandedGroups.add(item.label);
            break;
          }
        }
      }
    }
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pop(context); // close drawer
    final current = ModalRoute.of(context)?.settings.name;
    if (current != route) {
      Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: 300,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            right: BorderSide(color: Color(0x14FFFFFF), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 40,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Brand ────────────────────────────────────────
            const _BrandHeader(),
            const _BrandDivider(),

            // ── Nav items ─────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: _buildItems(),
              ),
            ),

            // ── User footer ───────────────────────────────────
            const _UserDivider(),
            const _UserFooter(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItems() {
    final widgets = <Widget>[];
    for (final item in NavModel.items) {
      // Section label
      if (item.sectionLabel != null) {
        widgets.add(_SectionLabel(item.sectionLabel!));
      }

      if (item.isGroup) {
        widgets.add(_GroupTile(
          item: item,
          selected: _isGroupActive(item),
          expanded: _expandedGroups.contains(item.label),
          onToggle: () {
            setState(() {
              if (_expandedGroups.contains(item.label)) {
                _expandedGroups.remove(item.label);
              } else {
                _expandedGroups.add(item.label);
              }
            });
          },
          onChildTap: (child) => _navigate(context, child.route!),
        ));
      } else if (item.route != null) {
        widgets.add(_NavTile(
          item: item,
          selected: _isRouteActive(item.route!),
          onTap: () => _navigate(context, item.route!),
        ));
      }
    }
    return widgets;
  }

  bool _isRouteActive(String route) {
    if (route == '/app') return widget.currentRoute == '/app' || widget.currentRoute == '/dashboard';
    return widget.currentRoute.startsWith(route);
  }

  bool _isGroupActive(NavItem group) {
    for (final child in group.children!) {
      if (child.route != null && _isRouteActive(child.route!)) return true;
    }
    return false;
  }
}

// ════════════════════════════════════════════════════════════
// Brand Header
// ════════════════════════════════════════════════════════════
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        final current = ModalRoute.of(context)?.settings.name;
        if (current != '/app') {
          Navigator.pushNamed(context, '/app');
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: DomendraTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              AppConfig.appName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: DomendraTheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandDivider extends StatelessWidget {
  const _BrandDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            DomendraTheme.onSurface.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Section Label
// ════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: DomendraTheme.onSurface.withOpacity(0.45),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Single Nav Tile (matches web's active gradient background)
// ════════════════════════════════════════════════════════════
class _NavTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: selected ? DomendraTheme.primaryGradient : null,
              color: selected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    selected ? (item.selectedIcon ?? item.icon) : item.icon,
                    size: 20,
                    color: selected
                        ? Colors.white
                        : DomendraTheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : DomendraTheme.onSurface.withOpacity(0.7),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Group Tile (expandable with children + connector line)
// ════════════════════════════════════════════════════════════
class _GroupTile extends StatelessWidget {
  final NavItem item;
  final bool selected; // true if any child matches currentRoute
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<NavItem> onChildTap;

  const _GroupTile({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.onToggle,
    required this.onChildTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header / activator
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: selected
                        ? DomendraTheme.primary
                        : DomendraTheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? DomendraTheme.onSurface
                            : DomendraTheme.onSurface.withOpacity(0.7),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: selected
                          ? DomendraTheme.primary
                          : DomendraTheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Children with connector line
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Color(0x20000000), // rgba on-surface 0.12
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                children: item.children!.where((c) => c.route != null).map((child) {
                  return _ChildTile(
                    item: child,
                    onTap: () => onChildTap(child),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Child Tile (indented submenu item)
// ════════════════════════════════════════════════════════════
class _ChildTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  _ChildTile({required this.item, required this.onTap, Key? key})
      : selected = false,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 14, top: 8, bottom: 8),
          child: Row(
            children: [
              // Small dot marker
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _isCurrent(currentRoute)
                      ? DomendraTheme.primary
                      : DomendraTheme.onSurface.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(
                item.icon,
                size: 18,
                color: _isCurrent(currentRoute)
                    ? DomendraTheme.primary
                    : DomendraTheme.onSurface.withOpacity(0.55),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _isCurrent(currentRoute) ? FontWeight.w600 : FontWeight.w500,
                    color: _isCurrent(currentRoute)
                        ? DomendraTheme.primary
                        : DomendraTheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isCurrent(String currentRoute) {
    final route = item.route;
    if (route == null) return false;
    if (route == '/app') return currentRoute == '/app' || currentRoute == '/dashboard';
    return currentRoute.startsWith(route);
  }
}

// ════════════════════════════════════════════════════════════
// User Divider & Footer
// ════════════════════════════════════════════════════════════
class _UserDivider extends StatelessWidget {
  const _UserDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            DomendraTheme.onSurface.withOpacity(0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: DomendraTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                auth.initials.isNotEmpty ? auth.initials : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: DomendraTheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  (auth.role.isNotEmpty ? auth.role : 'User').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: DomendraTheme.onSurface.withOpacity(0.5),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 18),
            color: DomendraTheme.danger,
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
