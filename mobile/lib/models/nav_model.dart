import 'package:flutter/material.dart';

/// Navigation item model — can be a single route or a group with children.
class NavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? route;
  final String? sectionLabel;
  final List<NavItem>? children;

  const NavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.route,
    this.sectionLabel,
    this.children,
  });

  bool get isGroup => children != null && children!.isNotEmpty;
}

/// Nav structure — exact mirror of the web `AppSidebar.vue` navItems array.
class NavModel {
  static const List<NavItem> items = [
    // ── MAIN ────────────────────────────────────────────────
    NavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/app',
      sectionLabel: 'MAIN',
    ),

    // ── ASSETS ──────────────────────────────────────────────
    NavItem(
      icon: Icons.view_list_outlined,
      label: 'Assets',
      sectionLabel: 'ASSETS',
      children: [
        NavItem(icon: Icons.directions_car_outlined, label: 'Vehicles', route: '/app/vehicles'),
        NavItem(icon: Icons.build_outlined, label: 'Equipment', route: '/equipment'),
        NavItem(icon: Icons.handshake_outlined, label: 'Lessors', route: '/lessors'),
        NavItem(icon: Icons.tire_repair_outlined, label: 'Tires', route: '/tires'),
        NavItem(icon: Icons.battery_std_outlined, label: 'Batteries', route: '/batteries'),
      ],
    ),

    // ── MAINTENANCE ─────────────────────────────────────────
    NavItem(
      icon: Icons.build_outlined,
      label: 'Maintenance',
      sectionLabel: 'MAINTENANCE',
      children: [
        NavItem(icon: Icons.warning_amber_outlined, label: 'Issues', route: '/issues'),
        NavItem(icon: Icons.build, label: 'Work Orders', route: '/work-orders'),
        NavItem(icon: Icons.miscellaneous_services_outlined, label: 'Services', route: '/services'),
        NavItem(icon: Icons.notifications_outlined, label: 'Reminders', route: '/reminders'),
        NavItem(icon: Icons.assignment_turned_in_outlined, label: 'Inspections', route: '/inspections'),
        NavItem(icon: Icons.account_tree_outlined, label: 'Garage', route: '/garage'),
        NavItem(icon: Icons.car_repair_outlined, label: 'Recalls', route: '/recalls'),
      ],
    ),

    // ── FLEET ───────────────────────────────────────────────
    NavItem(
      icon: Icons.flash_on_outlined,
      label: 'Fuel & Energy',
      sectionLabel: 'FLEET',
      children: [
        NavItem(icon: Icons.local_gas_station_outlined, label: 'Fuel & Energy', route: '/fuel'),
        NavItem(icon: Icons.map_outlined, label: 'IFTA & Trip Logs', route: '/ifta'),
      ],
    ),

    // ── INSIGHTS ────────────────────────────────────────────
    NavItem(
      icon: Icons.analytics_outlined,
      label: 'Analytics',
      sectionLabel: 'INSIGHTS',
      children: [
        NavItem(icon: Icons.directions_car, label: 'Vehicles', route: '/analytics/vehicles'),
        NavItem(icon: Icons.flash_on, label: 'Fuel & Energy', route: '/analytics/fuel-energy'),
        NavItem(icon: Icons.car_rental_outlined, label: 'Car Hire & Rental', route: '/analytics/rentals'),
      ],
    ),
    NavItem(icon: Icons.bar_chart, label: 'Reports', route: '/reports'),

    // ── OPERATIONS ─────────────────────────────────────────
    NavItem(
      icon: Icons.my_location,
      label: 'Operations',
      sectionLabel: 'OPERATIONS',
      children: [
        NavItem(icon: Icons.gps_fixed, label: 'Telematics & GPS', route: '/telematics'),
        NavItem(icon: Icons.location_on_outlined, label: 'Locations & Geofences', route: '/locations'),
        NavItem(icon: Icons.map_outlined, label: 'Dispatch', route: '/dispatch'),
        NavItem(icon: Icons.car_rental, label: 'Car Hire & Rental', route: '/rentals'),
        NavItem(icon: Icons.person_4_outlined, label: 'Driver Hire Rates', route: '/driver-hire-rates'),
        NavItem(icon: Icons.receipt_long_outlined, label: 'Invoices', route: '/invoices'),
        NavItem(icon: Icons.error_outline, label: 'Accidents', route: '/accidents'),
      ],
    ),
    NavItem(
      icon: Icons.contact_page_outlined,
      label: 'Contacts & Drivers',
      route: '/contacts',
      children: [
        NavItem(icon: Icons.contact_page_outlined, label: 'Contacts', route: '/contacts'),
        NavItem(icon: Icons.person_outline, label: 'Drivers', route: '/drivers'),
      ],
    ),
    NavItem(icon: Icons.verified_user_outlined, label: 'Driver Qualification', route: '/dqf'),
    NavItem(icon: Icons.description_outlined, label: 'Documents', route: '/documents'),
    NavItem(icon: Icons.inventory_2_outlined, label: 'Parts & Inventory', route: '/inventory'),
    NavItem(icon: Icons.notifications_active_outlined, label: 'Notifications', route: '/notifications'),
    NavItem(icon: Icons.monetization_on_outlined, label: 'Billing', route: '/billing'),
    NavItem(icon: Icons.receipt_long_outlined, label: 'Expenses', route: '/expenses'),

    // ── SYSTEM ──────────────────────────────────────────────
    NavItem(
      icon: Icons.settings_outlined,
      label: 'Settings',
      sectionLabel: 'SYSTEM',
      children: [
        NavItem(icon: Icons.business_outlined, label: 'Company Profile', route: '/settings'),
        NavItem(icon: Icons.monetization_on, label: 'Currency', route: '/settings/currency'),
        NavItem(icon: Icons.shield_outlined, label: 'Roles & Permissions', route: '/settings/roles'),
      ],
    ),
  ];

  /// Flatten all routable items (including children) — used to build the
  /// named-route table in main.dart.
  static List<NavItem> get flat {
    final result = <NavItem>[];
    for (final item in items) {
      if (item.route != null) result.add(item);
      if (item.children != null) {
        for (final child in item.children!) {
          if (child.route != null) result.add(child);
        }
      }
    }
    return result;
  }
}
