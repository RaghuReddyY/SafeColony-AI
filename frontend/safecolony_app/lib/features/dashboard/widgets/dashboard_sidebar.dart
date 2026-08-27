import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../auth/providers/auth_provider.dart';
import '../../ai/screens/ai_assistant_screen.dart';
import '../../chat/screens/community_chat_screen.dart';
import '../../delivery/screens/delivery_dashboard_screen.dart';
import '../../delivery/screens/guard_delivery_screen.dart';
import '../../auth/login_screen.dart';
import '../../guard/screens/guard_dashboard_screen.dart';
import '../../guard/screens/qr_scanner_screen.dart';
import '../../vacation/screens/vacation_screen.dart';
import '../../guard/screens/guard_visitors_screen.dart';
import '../../visitors/screens/visitor_list_screen.dart';
import '../../maintenance/screens/maintenance_admin_screen.dart';
import '../../maintenance/screens/maintenance_resident_screen.dart';
import '../../maintenance/screens/community_finance_screen.dart';
import '../../admin/screens/organization_money_details_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../community_services/screens/community_services_screen.dart';
import '../../complaints/screens/complaint_screen.dart';
import '../../incidents/screens/incident_screen.dart';
import '../../emergency/screens/emergency_alerts_screen.dart';
import '../../emergency/screens/emergency_sos_screen.dart';
import '../../amenities/screens/amenity_screen.dart';
import '../../admin/screens/block_admin_management_screen.dart';
import '../../admin/screens/resident_approval_screen.dart';
import '../../admin/property/screens/property_list_screen.dart';
import '../../admin/section/screens/section_list_screen.dart';
import '../../admin/unit/screens/unit_list_screen.dart';
import '../../admin/screens/organization_user_management_screen.dart';
import '../../admin/guard/screens/guard_list_screen.dart';
import '../../marketplace/screens/marketplace_screen.dart';
import '../../marketplace/screens/marketplace_admin_screen.dart';
import '../../marketplace/screens/marketplace_vendor_screen.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../super_app/screens/super_app_screen.dart';

class DashboardSidebar extends ConsumerWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    return Drawer(
      elevation: 0,
      child: Container(
        color: const Color(0xff1E293B),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff4F46E5),
                      Color(0xff2563EB),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 38,
                        color: Colors.indigo,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      user?.fullName ?? "Unknown User",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      user?.role ?? "",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // The sidebar mirrors the modules available to the current
              // role's dashboard. Do not show resident-only modules to
              // administrators/guards, or admin-only modules to residents.
              _menu(
                context,
                ref,
                role: user?.role ?? "",
                icon: Icons.dashboard,
                title: "Dashboard",
                selected: true,
              ),

              if (user?.role == "RESIDENT") ...[
                _menu(context, ref, role: user?.role ?? "", icon: Icons.hub_rounded, title: "SafeColony Hub"),

                _menu(context, ref, role: user?.role ?? "", icon: Icons.people, title: "Visitors"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.inventory_2, title: "Deliveries"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.account_balance_wallet_rounded, title: "Maintenance"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.account_balance_rounded, title: "Community Finance"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.beach_access, title: "Vacation"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.support_agent, title: "Complaints"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.report_problem_outlined, title: "Incidents"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.emergency_outlined, title: "Emergency"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.pool_outlined, title: "Amenities"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.notifications, title: "Notifications"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.forum_rounded, title: "Community Chat"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.handyman_rounded, title: "Community Services"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.storefront_rounded, title: "Marketplace"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.auto_awesome, title: "AI Assistant"),
              ],

              if (user?.role == "ORGANIZATION_ADMIN") ...[
                _menu(context, ref, role: user?.role ?? "", icon: Icons.hub_rounded, title: "SafeColony Hub"),

                _menu(context, ref, role: user?.role ?? "", icon: Icons.person_add_alt_1_rounded, title: "Resident Approvals"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.apartment_rounded, title: "Properties"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.grid_view_rounded, title: "Sections"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.home_work_rounded, title: "Units"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.admin_panel_settings_rounded, title: "Block Admins & Finance"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.manage_accounts_rounded, title: "User Management"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.shield_rounded, title: "Security Guards"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.account_balance_wallet_rounded, title: "Maintenance"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.receipt_long_rounded, title: "Money Details"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.account_balance_rounded, title: "Community Finance"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.notifications_active_rounded, title: "Notifications"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.sos_rounded, title: "Emergency Alerts"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.forum_rounded, title: "Community Chat"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.report_problem_rounded, title: "Incidents"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.handyman_rounded, title: "Community Services"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.storefront_rounded, title: "Marketplace"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.auto_awesome, title: "AI Assistant"),
              ],

              if (user?.role == "BLOCK_ADMIN") ...[
                _menu(context, ref, role: user?.role ?? "", icon: Icons.hub_rounded, title: "SafeColony Hub"),

                _menu(context, ref, role: user?.role ?? "", icon: Icons.support_agent_rounded, title: "Complaints"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.report_problem_rounded, title: "Incidents"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.account_balance_wallet_rounded, title: "Maintenance"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.notifications_active_rounded, title: "Notifications"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.forum_rounded, title: "Community Chat"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.handyman_rounded, title: "Community Services"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.storefront_rounded, title: "Marketplace"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.auto_awesome, title: "AI Assistant"),
              ],

              if (user?.role == "COMMUNITY_FINANCE_ADMIN") ...[
                _menu(context, ref, role: user?.role ?? "", icon: Icons.hub_rounded, title: "SafeColony Hub"),

                _menu(context, ref, role: user?.role ?? "", icon: Icons.account_balance_wallet_rounded, title: "Community Funds"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.notifications_active_rounded, title: "Notifications"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.forum_rounded, title: "Community Chat"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.handyman_rounded, title: "Community Services"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.storefront_rounded, title: "Marketplace"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.auto_awesome, title: "AI Assistant"),
              ],

              if (user?.role == "VENDOR") ...[
                _menu(context, ref, role: user?.role ?? "", icon: Icons.storefront_rounded, title: "Marketplace"),
              ],

              if (user?.role == "SECURITY_GUARD" || user?.role == "SECURITY_MANAGER") ...[
                _menu(context, ref, role: user?.role ?? "", icon: Icons.people, title: "Visitors"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.qr_code_scanner, title: "Guard Scanner"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.inventory_2, title: "Deliveries"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.emergency_outlined, title: "Emergency"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.report_problem_outlined, title: "Incidents"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.notifications, title: "Notifications"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.forum_rounded, title: "Community Chat"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.handyman_rounded, title: "Community Services"),
                _menu(context, ref, role: user?.role ?? "", icon: Icons.auto_awesome, title: "AI Assistant"),
              ],

              const Divider(color: Colors.white24, height: 30),

              _menu(
                context,
                ref,
                role: user?.role ?? "",
                icon: Icons.logout,
                title: "Logout",
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menu(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String role,
    bool selected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: .12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        onTap: () async {
          Navigator.pop(context);

          switch (title) {
            case "Dashboard":
              break;

case "Visitors":

  if (role == "SECURITY_GUARD" ||
      role == "SECURITY_MANAGER") {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GuardVisitorsScreen(),
      ),
    );

  } else {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VisitorListScreen(),
      ),
    );

  }

  break;

            case "Guard Scanner":
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QRScannerScreen(),
                ),
              );
              break;

            case "Deliveries":
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      (role == "SECURITY_GUARD" ||
                              role == "SECURITY_MANAGER")
                          ? const GuardDeliveryScreen()
                          : const DeliveryDashboardScreen(),
                ),
              );
              break;

            case "Maintenance":
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => role == "RESIDENT"
                      ? const MaintenanceResidentScreen()
                      : const MaintenanceAdminScreen(),
                ),
              );
              break;

            case "Community Finance":
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CommunityFinanceScreen(),
                ),
              );
              break;

            case "Notifications":
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationScreen(),
                ),
              );
              break;

            case "Community Chat":
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CommunityChatScreen(),
                ),
              );
              break;

            case "Community Services":
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CommunityServicesScreen(),
                ),
              );
              break;

            case "SafeColony Hub":
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperAppScreen()));
              break;

            case "Marketplace":
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    if (role == "VENDOR") return const MarketplaceVendorScreen();
                    if (role == "ORGANIZATION_ADMIN") return const MarketplaceAdminScreen();
                    return const MarketplaceScreen();
                  },
                ),
              );
              break;

            case "AI Assistant":
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AIAssistantScreen(),
                ),
              );
              break;

            case "Complaints":
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintScreen()));
              break;

            case "Incidents":
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentScreen()));
              break;

            case "Emergency":
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencySOSScreen()));
              break;

            case "Emergency Alerts":
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyAlertsScreen()));
              break;

            case "Amenities":
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AmenityScreen()));
              break;

            case "Resident Approvals":
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ResidentApprovalScreen()));
              break;

            case "Properties":
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PropertyListScreen()));
              break;

            case "Sections":
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SectionListScreen()));
              break;

            case "Units":
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UnitListScreen()));
              break;

            case "Block Admins & Finance":
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockAdminManagementScreen()));
              break;

            case "User Management":
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizationUserManagementScreen()));
              break;

            case "Security Guards":
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GuardListScreen()));
              break;

            case "Money Details":
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrganizationMoneyDetailsScreen(),
                ),
              );
              break;

            case "Community Funds":
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityFinanceScreen()));
              break;

            case "Settings":
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
              break;

            case "Vacation":
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VacationScreen(),
                    ),
                  );
                  break;
            case "Logout":
              await ref.read(authProvider.notifier).logout();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(
    builder: (_) => const LoginScreen(),
  ),
  (_) => false,
);
              break;

            default:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$title module is coming soon."),
                ),
              );
          }
        },
      ),
    );
  }
}