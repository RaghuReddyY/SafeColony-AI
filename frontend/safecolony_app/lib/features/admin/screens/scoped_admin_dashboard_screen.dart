import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/widgets/dashboard_sidebar.dart';

import '../../ai/screens/ai_assistant_screen.dart';
import '../../chat/screens/community_chat_screen.dart';
import '../../complaints/screens/complaint_screen.dart';
import '../../incidents/screens/incident_screen.dart';
import '../../maintenance/screens/maintenance_admin_screen.dart';
import '../../maintenance/screens/community_finance_screen.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../../../shared/widgets/dashboard_quick_access_fabs.dart';
import '../../auth/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../community_services/widgets/community_services_card.dart';

class ScopedAdminDashboardScreen extends ConsumerWidget {
  final bool financeOnly;
  const ScopedAdminDashboardScreen({super.key, this.financeOnly = false});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final title = financeOnly ? 'Community Finance' : 'Block Administration';
    final subtitle = financeOnly
        ? 'Collect and manage community-wide funds across all blocks.'
        : 'Manage the blocks assigned to you without seeing unrelated blocks.';

    return Scaffold(
      drawer: const DashboardSidebar(),
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Notifications are available to both Block Admin and
          // Community Finance Admin.  The shared bell loads the
          // authenticated user's own notification count.
          const NotificationBell(),
          IconButton(
            tooltip: 'AI Assistant',
            onPressed: () => _open(context, const AIAssistantScreen()),
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButton: const DashboardQuickAccessFabs(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xffE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome ${user?.fullName ?? ''}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  if (user?.organizationName != null && user!.organizationName!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      user.organizationName!,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff334155),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  if (user?.role == 'BLOCK_ADMIN' && (user?.sectionNames.isNotEmpty ?? false))
                    Text(
                      'Block${user!.sectionNames.length > 1 ? 's' : ''}: ${user.sectionNames.join(', ')}',
                      style: const TextStyle(color: Color(0xff64748B), fontSize: 15),
                    )
                  else
                    Text(
                      financeOnly ? 'Organization Finance Admin' : 'Block Admin',
                      style: const TextStyle(color: Color(0xff64748B), fontSize: 15),
                    ),
                  if (user?.organizationCode != null && user!.organizationCode!.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      'ORG: ${user.organizationCode!}',
                      style: const TextStyle(color: Color(0xff94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(subtitle, style: const TextStyle(color: Color(0xff64748B), fontSize: 15)),
            const SizedBox(height: 18),
            const CommunityServicesCard(),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.45,
              children: [
                if (!financeOnly)
                  _card(context, 'Complaints', 'Handle block complaints', Icons.support_agent_rounded, const Color(0xff7C3AED), const ComplaintScreen()),
                if (!financeOnly)
                  _card(context, 'Incidents', 'Investigate block incidents', Icons.report_problem_rounded, const Color(0xffB91C1C), const IncidentScreen()),
                if (financeOnly)
                  _card(
                    context,
                    'Community Funds',
                    'Manage organization-wide collections and shared expenses',
                    Icons.account_balance_wallet_rounded,
                    const Color(0xff059669),
                    const CommunityFinanceScreen(),
                  )
                else
                  _card(
                    context,
                    'Maintenance',
                    'Block maintenance and payments',
                    Icons.account_balance_wallet_rounded,
                    const Color(0xff059669),
                    const MaintenanceAdminScreen(),
                  ),
                _card(context, 'Notifications', 'Review operational alerts', Icons.notifications_active_rounded, const Color(0xffEA580C), const NotificationScreen()),
                _card(context, 'Community Chat', 'Talk to residents and staff', Icons.forum_rounded, const Color(0xff0F766E), const CommunityChatScreen()),
                _card(context, 'AI Assistant', 'Ask SafeColony AI', Icons.auto_awesome_rounded, const Color(0xff4F46E5), const AIAssistantScreen()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, String title, String subtitle, IconData icon, Color color, Widget page) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(context, page),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(backgroundColor: color.withValues(alpha: .10), foregroundColor: color, child: Icon(icon)),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff64748B), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
