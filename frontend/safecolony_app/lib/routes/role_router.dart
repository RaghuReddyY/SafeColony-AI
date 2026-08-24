import 'package:flutter/material.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/guard/screens/guard_dashboard_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/scoped_admin_dashboard_screen.dart';
import '../features/marketplace/screens/marketplace_vendor_screen.dart';

class RoleRouter {
  static Widget getHomeScreen({
    required String role,
    String? residentStatus,
  }) {
    switch (role) {
      case "SYSTEM_ADMIN":
        return const DashboardScreen();

      case "ORGANIZATION_ADMIN":
        return const AdminDashboardScreen();

      case "BLOCK_ADMIN":
        return const ScopedAdminDashboardScreen();

      case "COMMUNITY_FINANCE_ADMIN":
        return const ScopedAdminDashboardScreen(financeOnly: true);

      case "RESIDENT":
        return const DashboardScreen();

      case "VENDOR":
        return const MarketplaceVendorScreen();

      case "SECURITY_MANAGER":
        return const GuardDashboardScreen();

      case "SECURITY_GUARD":
        return const GuardDashboardScreen();

      default:
        return const DashboardScreen();
    }
  }
}