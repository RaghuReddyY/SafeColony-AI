import 'package:flutter/material.dart';

import '../../../models/dashboard_summary.dart';
import '../../maintenance/screens/community_finance_screen.dart';
import '../../maintenance/screens/community_expenses_screen.dart';
import '../../maintenance/screens/maintenance_resident_screen.dart';
import '../../maintenance/screens/maintenance_admin_screen.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../ai/screens/ai_assistant_screen.dart';
import 'activity_timeline.dart';
import 'ai_card.dart';
import 'dashboard_header.dart';
import 'quick_action_grid.dart';
import 'family_invite_card.dart';
import '../../community_services/widgets/community_services_card.dart';

class DashboardBody extends StatelessWidget {
  final DashboardSummary dashboard;
  final bool showFamilyInvite;

  const DashboardBody({
    super.key,
    required this.dashboard,
    this.showFamilyInvite = false,
  });

  String _money(double value) => '₹${value.toStringAsFixed(2)}';

  String _month(DateTime? value) {
    if (value == null) return 'Previous period';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[value.month - 1]} ${value.year}';
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 600 ? 16.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            resident: dashboard.residentName,
            unit: dashboard.unitNumber,
            block: dashboard.sectionName,
            organizationName: dashboard.organizationName,
            organizationCode: dashboard.organizationCode,
            score: dashboard.securityScore,
          ),
          const SizedBox(height: 18),
          const Text('My Home', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _moneyGrid(context),
          const SizedBox(height: 20),
          const Text('Quick Actions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const QuickActionGrid(),
          const SizedBox(height: 18),
          const CommunityServicesCard(),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => _open(context, const AIAssistantScreen()),
            child: AICard(dashboard: dashboard),
          ),
          if (showFamilyInvite) ...[
            const SizedBox(height: 18),
            const FamilyInviteCard(),
          ],
          const SizedBox(height: 18),
          ActivityTimeline(
            activities: dashboard.recentActivity,
            onOpen: () => _open(context, const NotificationScreen()),
          ),
          const SizedBox(height: 16),
          // Detailed visitor analytics is intentionally not placed on the
          // primary resident dashboard; it is available from Visitors.
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _moneyGrid(BuildContext context) {
    final cards = <Widget>[
      _actionCard(
        context,
        title: 'Maintenance',
        value: _money(dashboard.pendingMaintenance),
        subtitle: dashboard.latestMaintenanceStatus ?? 'Current',
        detail: dashboard.latestMaintenanceCarryForward > 0
            ? 'Carry forward ${_money(dashboard.latestMaintenanceCarryForward)} from ${_month(dashboard.latestMaintenancePeriodMonth)}'
            : dashboard.latestMaintenanceDueDate == null
                ? 'No payment due'
                : 'Due ${_month(dashboard.latestMaintenanceDueDate)}',
        icon: Icons.account_balance_wallet_outlined,
        alert: dashboard.pendingMaintenance > 0,
        onTap: () => _open(
          context,
          showFamilyInvite
              ? const MaintenanceResidentScreen()
              : const MaintenanceAdminScreen(),
        ),
      ),
      _actionCard(
        context,
        title: 'Community Finance',
        value: _money(dashboard.communityFinancePending),
        subtitle: dashboard.communityFinancePending > 0 ? 'Pending contribution' : 'No mandatory payment pending',
        detail: '${dashboard.communityFinanceActive} active collection${dashboard.communityFinanceActive == 1 ? '' : 's'}',
        icon: Icons.volunteer_activism_outlined,
        alert: dashboard.communityFinancePending > 0,
        onTap: () => _open(context, const CommunityFinanceScreen()),
      ),
      _actionCard(
        context,
        title: 'Community Expenses',
        value: _money(dashboard.communityExpenseTotal),
        subtitle: 'Published community expenses',
        detail: 'Tap to view expense details',
        icon: Icons.receipt_long_outlined,
        onTap: () => _open(context, const CommunityExpensesScreen()),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 3 : constraints.maxWidth >= 560 ? 2 : 1;
        final gap = 12.0;
        final cardWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards.map((card) => SizedBox(width: cardWidth, child: card)).toList(),
        );
      },
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required String detail,
    required IconData icon,
    required VoidCallback onTap,
    bool alert = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: alert ? Colors.red.withValues(alpha: .10) : Colors.indigo.withValues(alpha: .10),
                    foregroundColor: alert ? Colors.red : Colors.indigo,
                    child: Icon(icon),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: alert ? Colors.red : Colors.indigo)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xff64748B))),
            ],
          ),
        ),
      ),
    );
  }
}
