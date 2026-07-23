import 'package:flutter/material.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';


class RoleRouter {

  static Widget getHomeScreen({
    required String role,
    String? residentStatus,
  }) {

    switch(role) {

      case "SYSTEM_ADMIN":
        return const DashboardScreen();


      case "ORGANIZATION_ADMIN":
         return const AdminDashboardScreen();


      case "RESIDENT":

        if(residentStatus == "PENDING"){
          return const DashboardScreen();
        }

        return const DashboardScreen();


      case "SECURITY_MANAGER":
        return const DashboardScreen();


      case "SECURITY_GUARD":
        return const DashboardScreen();


      default:
        return const DashboardScreen();
    }

  }
}