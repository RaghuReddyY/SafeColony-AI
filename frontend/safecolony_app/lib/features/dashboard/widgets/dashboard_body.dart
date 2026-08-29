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
            onOpen: (activity) => _open(
              context,
              NotificationScreen(category: activity.notificationType),
            ),
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
    final accent = alert ? const Color(0xffDC2626) : const Color(0xff4658B8);
    final accentSoft = alert
        ? const Color(0xffFEF2F2)
        : const Color(0xffEEF2FF);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: .08)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 7),
              color: Colors.black.withValues(alpha: .07),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -22,
                top: -22,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: .035),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: accentSoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(icon, color: accent, size: 27),
                        ),
                        const Spacer(),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: .07),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Color(0xff64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accentSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: Color(0xff64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
