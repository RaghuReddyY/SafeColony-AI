import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ai/screens/ai_assistant_screen.dart';
import '../../../shared/widgets/dashboard_quick_access_fabs.dart';
import '../../chat/screens/community_chat_screen.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../emergency/providers/emergency_provider.dart';
import '../../emergency/screens/emergency_alerts_screen.dart';
import '../../maintenance/providers/maintenance_provider.dart';
import '../../maintenance/screens/maintenance_admin_screen.dart';
import '../../incidents/screens/incident_screen.dart';
import '../../complaints/screens/complaint_screen.dart';
import '../../amenities/screens/amenity_screen.dart';
import '../guard/screens/guard_list_screen.dart';
import '../property/screens/property_list_screen.dart';
import '../section/screens/section_list_screen.dart';
import '../unit/screens/unit_list_screen.dart';
import '../providers/admin_provider.dart';
import 'resident_approval_screen.dart';
import 'block_admin_management_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(adminProvider.notifier).loadPendingResidents();
      ref.invalidate(maintenanceDashboardProvider);
    });
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await ref.read(authProvider.notifier).logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  void _open(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final maintenanceAsync =
        ref.watch(maintenanceDashboardProvider);
    final emergencyAsync =
        ref.watch(unresolvedEmergencyProvider);

    final pendingResidents = adminState.residents.length;
    final activeEmergencyCount =
        emergencyAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 20,

        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xffEEF2FF),
              child: Icon(
                Icons.shield_rounded,
                color: Color(0xff4F46E5),
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'SafeColony AI',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        actions: [
          // Notification Bell
          const NotificationBell(),

          const SizedBox(width: 4),

          // AI Assistant
          IconButton(
            tooltip: 'AI Assistant',
            icon: const Icon(
              Icons.auto_awesome_rounded,
            ),
            onPressed: () {
              _open(
                const AIAssistantScreen(),
              );
            },
          ),

          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: const DashboardQuickAccessFabs(),

      // ============================================================
      // BODY
      // ============================================================

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(adminProvider.notifier)
                .loadPendingResidents();

            ref.invalidate(
              maintenanceDashboardProvider,
            );
            ref.invalidate(
              unresolvedEmergencyProvider,
            );
          },

          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              32,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // --------------------------------------------------
                // HERO
                // --------------------------------------------------

                _hero(),

                const SizedBox(height: 14),

                _organizationCodeCard(),

                const SizedBox(height: 22),

                // --------------------------------------------------
                // STATISTICS
                // --------------------------------------------------

                _stats(
                  context,
                  pendingResidents,
                  maintenanceAsync,
                ),

                const SizedBox(height: 26),

                // --------------------------------------------------
                // MONEY MANAGEMENT
                // --------------------------------------------------

                _sectionHeader(
                  'Money Management',
                  'Track collections, expenses and the community balance',
                  Icons.account_balance_wallet_rounded,
                ),

                const SizedBox(height: 12),

                _moneyCard(
                  maintenanceAsync,
                ),

                const SizedBox(height: 28),

                // --------------------------------------------------
                // COMMUNITY MANAGEMENT
                // --------------------------------------------------

                _sectionHeader(
                  'Community Management',
                  'Manage residents and the physical community structure',
                  Icons.apartment_rounded,
                ),

                const SizedBox(height: 12),

                _managementGrid(
                  [
                    _ActionData(
                      'Resident Approvals',
                      'Review pending residents',
                      Icons.person_add_alt_1_rounded,
                      const Color(0xff4F46E5),
                      () {
                        _open(
                          const ResidentApprovalScreen(),
                        );
                      },
                      badge: pendingResidents,
                    ),

                    _ActionData(
                      'Properties',
                      'Create and manage properties',
                      Icons.apartment_rounded,
                      const Color(0xff0891B2),
                      () {
                        _open(
                          const PropertyListScreen(),
                        );
                      },
                    ),

                    _ActionData(
                      'Sections',
                      'Manage community sections',
                      Icons.grid_view_rounded,
                      const Color(0xff7C3AED),
                      () {
                        _open(
                          const SectionListScreen(),
                        );
                      },
                    ),

                    _ActionData(
                      'Units',
                      'Manage flats and units',
                      Icons.home_work_rounded,
                      const Color(0xff2563EB),
                      () {
                        _open(
                          const UnitListScreen(),
                        );
                      },
                    ),

                    _ActionData(
                      'Block Admins & Finance',
                      'Assign admins to blocks or one collector to all blocks',
                      Icons.admin_panel_settings_rounded,
                      const Color(0xff9333EA),
                      () => _open(const BlockAdminManagementScreen()),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // --------------------------------------------------
                // SECURITY MANAGEMENT
                // --------------------------------------------------

                _sectionHeader(
                  'Security Management',
                  'Keep your community safe and connected',
                  Icons.security_rounded,
                ),

                const SizedBox(height: 12),

                _managementGrid(
                  [
                    _ActionData(
                      'Security Guards',
                      'Create and manage guards',
                      Icons.shield_rounded,
                      const Color(0xff059669),
                      () {
                        _open(
                          const GuardListScreen(),
                        );
                      },
                    ),

                    _ActionData(
                      'Notifications',
                      'Review community notifications',
                      Icons.notifications_active_rounded,
                      const Color(0xffEA580C),
                      () {
                        _open(
                          const NotificationScreen(),
                        );
                      },
                    ),

                    _ActionData(
                      'Emergency Alerts',
                      'View and resolve active SOS alerts',
                      Icons.sos_rounded,
                      const Color(0xffDC2626),
                      () {
                        _open(
                          const EmergencyAlertsScreen(),
                        );
                      },
                      badge: activeEmergencyCount,
                    ),

                    _ActionData(
                      'Community Chat',
                      'Chat with residents, guards and administrators',
                      Icons.forum_rounded,
                      const Color(0xff0F766E),
                      () => _open(const CommunityChatScreen()),
                    ),

                    _ActionData(
                      'AI Assistant',
                      'Ask SafeColony AI anything',
                      Icons.auto_awesome_rounded,
                      const Color(0xff4F46E5),
                      () {
                        _open(
                          const AIAssistantScreen(),
                        );
                      },
                    ),

                    _ActionData(
                      'Money Details',
                      'Open the full finance dashboard',
                      Icons.receipt_long_rounded,
                      const Color(0xff16A34A),
                      () {
                        _open(
                          const MaintenanceAdminScreen(),
                        );
                      },
                    ),

                    _ActionData(
                      'Incidents',
                      'Investigate and resolve incidents',
                      Icons.report_problem_rounded,
                      const Color(0xffB91C1C),
                      () => _open(const IncidentScreen()),
                    ),

                    _ActionData(
                      'Complaints',
                      'Assign and resolve resident complaints',
                      Icons.support_agent_rounded,
                      const Color(0xff7C3AED),
                      () => _open(const ComplaintScreen()),
                    ),

                    _ActionData(
                      'Amenities',
                      'Manage facilities and bookings',
                      Icons.pool_rounded,
                      const Color(0xff0891B2),
                      () => _open(const AmenityScreen()),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // --------------------------------------------------
                // AI BANNER
                // --------------------------------------------------

                _aiBanner(),

                const SizedBox(height: 28),

                // --------------------------------------------------
                // LOGOUT
                // --------------------------------------------------

                SizedBox(
                  width: double.infinity,

                  child: OutlinedButton.icon(
                    onPressed: _logout,

                    icon: const Icon(
                      Icons.logout_rounded,
                    ),

                    label: const Text(
                      'Logout',
                    ),

                    style:
                        OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 16,
                      ),

                      foregroundColor:
                          const Color(0xff475569),

                      side: const BorderSide(
                        color: Color(0xffCBD5E1),
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // HERO
  // ================================================================

  Widget _hero() {
    final user = ref.watch(authProvider).user;

    final firstName =
        user?.fullName.split(' ').first ?? 'Admin';

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff312E81),
            Color(0xff4F46E5),
            Color(0xff2563EB),
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.circular(26),

        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(
              alpha: .20,
            ),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final compact =
              constraints.maxWidth < 600;

          final content =
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Icon(
                Icons.waving_hand_rounded,
                color: Colors.amber,
                size: 30,
              ),

              const SizedBox(height: 12),

              Text(
                'Welcome $firstName 👋',

                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Manage your community, security and finances from one place.',

                style:
                    TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ],
          );

          final aiButton =
              FilledButton.icon(
            onPressed: () {
              _open(
                const AIAssistantScreen(),
              );
            },

            icon: const Icon(
              Icons.auto_awesome_rounded,
            ),

            label: const Text(
              'Ask SafeColony AI',
            ),

            style:
                FilledButton.styleFrom(
              backgroundColor:
                  Colors.white,

              foregroundColor:
                  const Color(
                0xff3730A3,
              ),

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                content,

                const SizedBox(
                  height: 18,
                ),

                aiButton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: content,
              ),

              const SizedBox(
                width: 20,
              ),

              aiButton,
            ],
          );
        },
      ),
    );
  }

  Widget _organizationCodeCard() {
    final user = ref.watch(authProvider).user;
    final code = user?.organizationCode;
    final orgId = user?.organizationId;
    final name = user?.organizationName ?? 'Your Community';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xffEEF2FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.business_rounded, color: Color(0xff4F46E5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xff0F172A))),
                const SizedBox(height: 4),
                Text('Organization Code: ${code ?? 'Not available'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xff475569))),
                if (orgId != null)
                  Text('Organization ID: $orgId', style: const TextStyle(fontSize: 11, color: Color(0xff94A3B8))),
              ],
            ),
          ),
          if (code != null)
            IconButton(
              tooltip: 'Copy organization code',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Organization code copied.')));
              },
            ),
        ],
      ),
    );
  }

  // ================================================================
  // STATISTICS
  // ================================================================

  Widget _stats(
    BuildContext context,
    int pendingResidents,
    AsyncValue maintenanceAsync,
  ) {
    final period =
        maintenanceAsync.valueOrNull?.period;

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final columns =
            constraints.maxWidth >= 1050
                ? 4
                : constraints.maxWidth >= 650
                    ? 2
                    : 1;

        final width =
            (constraints.maxWidth -
                    (columns - 1) * 12) /
                columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,

          children: [
            SizedBox(
              width: width,

              child: _statCard(
                'Pending Residents',
                '$pendingResidents',
                'Need approval',
                Icons.person_add_alt_1_rounded,
                const Color(0xff4F46E5),
              ),
            ),

            SizedBox(
              width: width,

              child: _statCard(
                'Maintenance Collected',
                period == null
                    ? '—'
                    : _money(
                        period.collectedTotal,
                      ),
                period == null
                    ? 'No period yet'
                    : _month(
                        period.month,
                      ),
                Icons.payments_rounded,
                const Color(0xff059669),
              ),
            ),

            SizedBox(
              width: width,

              child: _statCard(
                'Expenses',
                period == null
                    ? '—'
                    : _money(
                        period.expenseTotal,
                      ),
                period == null
                    ? 'No period yet'
                    : _month(
                        period.month,
                      ),
                Icons.trending_down_rounded,
                const Color(0xffEA580C),
              ),
            ),

            SizedBox(
              width: width,

              child: _statCard(
                'Balance',
                period == null
                    ? '—'
                    : _money(
                        period.closingBalance,
                      ),
                period == null
                    ? 'No period yet'
                    : _month(
                        period.month,
                      ),
                Icons.account_balance_rounded,
                const Color(0xff2563EB),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // STAT CARD
  // ================================================================

  Widget _statCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color:
              const Color(0xffE2E8F0),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration:
                BoxDecoration(
              color:
                  color.withValues(
                alpha: .10,
              ),

              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),

            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style:
                      const TextStyle(
                    color:
                        Color(0xff64748B),
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xff0F172A),
                  ),
                ),

                Text(
                  subtitle,

                  style:
                      const TextStyle(
                    color:
                        Color(0xff94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SECTION HEADER
  // ================================================================

  Widget _sectionHeader(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,

          decoration:
              BoxDecoration(
            color:
                const Color(0xffEEF2FF),

            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),

          child: Icon(
            icon,
            color:
                const Color(0xff4F46E5),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style:
                    const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xff0F172A),
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                subtitle,

                style:
                    const TextStyle(
                  color:
                      Color(0xff64748B),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // MANAGEMENT GRID
  // ================================================================

  Widget _managementGrid(
    List<_ActionData> actions,
  ) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final columns =
            constraints.maxWidth >= 950
                ? 4
                : constraints.maxWidth >= 600
                    ? 2
                    : 1;

        final width =
            (constraints.maxWidth -
                    (columns - 1) * 12) /
                columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,

          children:
              actions.map(
            (action) {
              return SizedBox(
                width: width,

                // IMPORTANT:
                // Explicit finite height prevents
                // unbounded RenderFlex errors inside Wrap.
                height: 165,

                child:
                    _actionCard(
                  action,
                ),
              );
            },
          ).toList(),
        );
      },
    );
  }

  // ================================================================
  // ACTION CARD
  // ================================================================
// ================================================================
// ACTION CARD
// ================================================================

Widget _actionCard(
  _ActionData action,
) {
  return Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),

    child: InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(20),

      child: Container(
        width: double.infinity,
        height: double.infinity,

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: const Color(0xffE2E8F0),
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ------------------------------------------------------
            // ICON + BADGE
            // ------------------------------------------------------

            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,

                  decoration: BoxDecoration(
                    color: action.color.withValues(
                      alpha: .10,
                    ),

                    borderRadius:
                        BorderRadius.circular(14),
                  ),

                  child: Icon(
                    action.icon,
                    color: action.color,
                  ),
                ),

                const Spacer(),

                if (action.badge != null &&
                    action.badge! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xffFEF2F2),

                      borderRadius:
                          BorderRadius.circular(20),
                    ),

                    child: Text(
                      '${action.badge}',

                      style: const TextStyle(
                        color: Color(0xffDC2626),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ------------------------------------------------------
            // TITLE
            // ------------------------------------------------------

            Text(
              action.title,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xff0F172A),
              ),
            ),

            const SizedBox(height: 4),

            // ------------------------------------------------------
            // DESCRIPTION
            // ------------------------------------------------------

            Expanded(
              child: Text(
                action.subtitle,

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xff64748B),
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // ================================================================
  // MONEY CARD
  // ================================================================

  Widget _moneyCard(
    AsyncValue maintenanceAsync,
  ) {
    if (maintenanceAsync.isLoading) {
      return Container(
        height: 180,

        alignment:
            Alignment.center,

        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            22,
          ),
        ),

        child:
            const CircularProgressIndicator(),
      );
    }

    final dashboard =
        maintenanceAsync.valueOrNull;

    final period =
        dashboard?.period;

    if (period == null) {
      return _emptyCard(
        Icons.account_balance_wallet_outlined,
        'No maintenance period created yet',
        'Open Money Management to create the current monthly period.',
        () {
          _open(
            const MaintenanceAdminScreen(),
          );
        },
      );
    }

    return Container(
      padding:
          const EdgeInsets.all(22),

      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xffECFDF5),
            Color(0xffF0FDFA),
          ],

          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.circular(
          22,
        ),

        border: Border.all(
          color:
              const Color(
            0xffBBF7D0,
          ),
        ),
      ),

      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final compact =
              constraints.maxWidth <
                  700;

          final summary =
              Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [
              _moneyMetric(
                'Collected',
                period.collectedTotal,
                const Color(
                  0xff059669,
                ),
              ),

              _moneyMetric(
                'Expenses',
                period.expenseTotal,
                const Color(
                  0xffEA580C,
                ),
              ),

              _moneyMetric(
                'Balance',
                period.closingBalance,
                const Color(
                  0xff2563EB,
                ),
              ),
            ],
          );

          final details =
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                _month(
                  period.month,
                ),

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xff14532D),
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                '${period.paidBills} paid • ${period.unpaidBills} pending • Due ${_date(period.dueDate)}',

                style:
                    const TextStyle(
                  color:
                      Color(0xff475569),
                  fontSize: 13,
                ),
              ),
            ],
          );

          final button =
              OutlinedButton.icon(
            onPressed: () {
              _open(
                const MaintenanceAdminScreen(),
              );
            },

            icon: const Icon(
              Icons.arrow_forward_rounded,
            ),

            label: const Text(
              'View Details',
            ),

            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  const Color(
                0xff166534,
              ),

              side:
                  const BorderSide(
                color:
                    Color(0xff86EFAC),
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                details,

                const SizedBox(
                  height: 18,
                ),

                summary,

                const SizedBox(
                  height: 18,
                ),

                button,
              ],
            );
          }

          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Expanded(
                    child:
                        details,
                  ),

                  button,
                ],
              ),

              const SizedBox(
                height: 22,
              ),

              summary,
            ],
          );
        },
      ),
    );
  }

  // ================================================================
  // MONEY METRIC
  // ================================================================

  Widget _moneyMetric(
    String label,
    double value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            label,

            style:
                const TextStyle(
              color:
                  Color(0xff64748B),
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            _money(value),

            style:
                TextStyle(
              color: color,
              fontSize: 21,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // AI BANNER
  // ================================================================

  Widget _aiBanner() {
    return InkWell(
      onTap: () {
        _open(
          const AIAssistantScreen(),
        );
      },

      borderRadius:
          BorderRadius.circular(24),

      child: Container(
        padding:
            const EdgeInsets.all(22),

        decoration:
            BoxDecoration(
          gradient:
              const LinearGradient(
            colors: [
              Color(0xffEEF2FF),
              Color(0xffF5F3FF),
            ],
          ),

          borderRadius:
              BorderRadius.circular(
            24,
          ),

          border: Border.all(
            color:
                const Color(
              0xffC7D2FE,
            ),
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,

              decoration:
                  BoxDecoration(
                gradient:
                    const LinearGradient(
                  colors: [
                    Color(0xff4F46E5),
                    Color(0xff7C3AED),
                  ],
                ),

                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),

              child:
                  const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    'Need help running the community?',

                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w800,
                      fontSize: 16,
                      color:
                          Color(0xff1E1B4B),
                    ),
                  ),

                  SizedBox(
                    height: 5,
                  ),

                  Text(
                    'Ask SafeColony AI about maintenance, residents, visitors, security or daily admin tasks.',

                    style:
                        TextStyle(
                      color:
                          Color(0xff475569),
                      height: 1.35,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_rounded,
              color:
                  Color(0xff4F46E5),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // EMPTY CARD
  // ================================================================

  Widget _emptyCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(
        22,
      ),

      child: Container(
        padding:
            const EdgeInsets.all(22),

        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            22,
          ),

          border: Border.all(
            color:
                const Color(
              0xffE2E8F0,
            ),
          ),
        ),

        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color:
                  const Color(
                0xff16A34A,
              ),
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    subtitle,

                    style:
                        const TextStyle(
                      color:
                          Color(0xff64748B),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  String _money(
    double value,
  ) {
    return '₹${value.toStringAsFixed(0)}';
  }

  String _month(
    DateTime date,
  ) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  String _date(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }
}

// ================================================================
// ACTION DATA
// ================================================================

class _ActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  const _ActionData(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap, {
    this.badge,
  });
}