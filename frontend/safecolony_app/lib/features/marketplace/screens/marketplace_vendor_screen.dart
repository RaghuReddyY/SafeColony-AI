import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/marketplace.dart';
import '../services/marketplace_service.dart';

class MarketplaceVendorScreen extends ConsumerStatefulWidget {
  const MarketplaceVendorScreen({super.key});

  @override
  ConsumerState<MarketplaceVendorScreen> createState() =>
      _MarketplaceVendorScreenState();
}

class _MarketplaceVendorScreenState
    extends ConsumerState<MarketplaceVendorScreen>
    with SingleTickerProviderStateMixin {
  final api = MarketplaceService();

  late TabController tabs;
  late Future<VendorDashboard> dashboard;
  late Future<List<MarketplaceEvent>> events;
  late Future<List<MarketplaceOrder>> orders;
  late Future<List<ServiceRequest>> serviceRequests;

  MarketplaceAggregate? aggregate;
  int? aggregateEventId;

  @override
  void initState() {
    super.initState();

    tabs = TabController(
      length: 5,
      vsync: this,
    );

    reload();
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  void reload() {
    setState(() {
      dashboard = api.vendorDashboard();
      events = api.vendorEvents();
      orders = api.vendorOrders();
      serviceRequests = api.vendorServiceRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('Vendor Portal'),
        actions: [
          IconButton(
            onPressed: reload,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: tabs,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Community Days'),
            Tab(text: 'Orders'),
            Tab(text: 'Services'),
            Tab(text: 'Offers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabs,
        children: [
          _overview(),
          _events(),
          _orders(),
          _serviceRequests(),
          _offers(),
        ],
      ),
    );
  }

  Widget _overview() {
    return FutureBuilder<VendorDashboard>(
      future: dashboard,
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (s.hasError) {
          return _error(s.error);
        }

        final d = s.data!;

        return RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _hero(d),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.8,
                children: [
                  _stat(
                    'Open Days',
                    '${d.openEvents}',
                    Icons.event_available,
                  ),
                  _stat(
                    'Upcoming',
                    '${d.upcomingEvents}',
                    Icons.calendar_month,
                  ),
                  _stat(
                    'Pending Orders',
                    '${d.pendingOrders}',
                    Icons.pending_actions,
                  ),
                  _stat(
                    'Ready',
                    '${d.readyOrders}',
                    Icons.inventory_2,
                  ),
                  _stat(
                    'Delivered',
                    '${d.deliveredOrders}',
                    Icons.check_circle,
                  ),
                  _stat(
                    'Total Orders',
                    '${d.totalOrders}',
                    Icons.shopping_bag,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Community sales',
                            style: TextStyle(
                              color: Color(0xff64748B),
                            ),
                          ),
                          Text(
                            '₹${d.totalSales.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _portalGuide(),
            ],
          ),
        );
      },
    );
  }

  Widget _hero(VendorDashboard d) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xff0F766E),
            Color(0xff2563EB),
          ],
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            child: Icon(
              Icons.storefront,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.vendorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  d.category,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
                if (d.phone != null)
                  Text(
                    d.phone!,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xff64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _portalGuide() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'How SafeColony works',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text('1. Review community delivery days'),
            Text('2. See consolidated apartment demand'),
            Text('3. Prepare one community shipment'),
            Text(
              '4. Update each order as it moves to READY and DELIVERED',
            ),
            Text(
              '5. Complete the community day after delivery',
            ),
          ],
        ),
      ),
    );
  }

  Widget _events() {
    return FutureBuilder<List<MarketplaceEvent>>(
      future: events,
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (s.hasError) {
          return _error(s.error);
        }

        final list = s.data!;

        if (list.isEmpty) {
          return const Center(
            child: Text(
              'No community days assigned to your vendor account.',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) => _eventCard(list[i]),
        );
      },
    );
  }

  Widget _eventCard(MarketplaceEvent e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    e.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Chip(
                  label: Text(e.status),
                ),
              ],
            ),
            Text(
              '${e.category} • ${e.orderCount ?? 0} orders • '
              '${e.apartmentCount ?? 0} apartments',
              style: const TextStyle(
                color: Color(0xff64748B),
              ),
            ),
            if (e.cutoffAt != null)
              Text(
                'Cutoff: ${_fmt(e.cutoffAt!)}',
              ),
            if (e.scheduledFor != null)
              Text(
                'Delivery: ${_fmt(e.scheduledFor!)}',
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showAggregate(e),
                  icon: const Icon(Icons.summarize),
                  label: const Text('Consolidated order'),
                ),
                if (e.status == 'OPEN')
                  OutlinedButton(
                    onPressed: () => _eventStatus(
                      e,
                      'CLOSED',
                    ),
                    child: const Text('Close orders'),
                  ),
                if (e.status == 'CLOSED')
                  FilledButton(
                    onPressed: () => _eventStatus(
                      e,
                      'COMPLETED',
                    ),
                    child: const Text('Complete day'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceRequests() {
    return FutureBuilder<List<ServiceRequest>>(
      future: serviceRequests,
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (s.hasError) {
          return _error(s.error);
        }

        final list = s.data ?? [];

        if (list.isEmpty) {
          return const Center(
            child: Text(
              'No service requests assigned to your vendor.',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final r = list[i];

            return Card(
              child: ExpansionTile(
                title: Text(
                  r.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${r.category} • ${r.status}'
                  '${r.preferredSlot == null ? '' : ' • ${r.preferredSlot}'}',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.description != null)
                          Text(r.description!),
                        if (r.quotedAmount != null)
                          Text(
                            'Quote: ₹${r.quotedAmount!.toStringAsFixed(2)}',
                          ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (r.status == 'REQUESTED')
                              OutlinedButton(
                                onPressed: () => _serviceStatus(
                                  r,
                                  'ASSIGNED',
                                ),
                                child: const Text('Accept'),
                              ),
                            if ([
                              'REQUESTED',
                              'ASSIGNED',
                              'QUOTED',
                            ].contains(r.status))
                              TextButton(
                                onPressed: () => _serviceStatus(
                                  r,
                                  'CANCELLED',
                                ),
                                child: const Text('Reject'),
                              ),
                            if (r.status == 'ASSIGNED')
                              OutlinedButton(
                                onPressed: () => _quoteService(r),
                                child: const Text('Quote'),
                              ),
                            if ([
                              'ASSIGNED',
                              'QUOTED',
                              'APPROVED',
                            ].contains(r.status))
                              OutlinedButton(
                                onPressed: () => _serviceStatus(
                                  r,
                                  'IN_PROGRESS',
                                ),
                                child: const Text('Start'),
                              ),
                            if (r.status == 'IN_PROGRESS')
                              FilledButton(
                                onPressed: () => _serviceStatus(
                                  r,
                                  'COMPLETED',
                                ),
                                child: const Text('Complete'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _offers() {
    return FutureBuilder<List<VendorOffer>>(
      future: api.vendorOffers(),
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (s.hasError) {
          return _error(s.error);
        }

        final list = s.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _addOffer,
                icon: const Icon(
                  Icons.local_offer_outlined,
                ),
                label: const Text('Create offer'),
              ),
            ),
            const SizedBox(height: 10),
            if (list.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'No active offers. Create a community discount '
                    'such as 10% off when 50 apartments order.',
                  ),
                ),
              ),
            ...list.map(
              (o) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.percent),
                  ),
                  title: Text(o.title),
                  subtitle: Text(
                    '${o.discountPercent.toStringAsFixed(0)}% off • '
                    'minimum ${o.minOrders} orders\n'
                    '${o.description ?? ''}',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addOffer() async {
    final title = TextEditingController();
    final desc = TextEditingController();
    final discount = TextEditingController(text: '10');
    final min = TextEditingController(text: '50');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Community Offer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'Offer title',
                ),
              ),
              TextField(
                controller: desc,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
              ),
              TextField(
                controller: discount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Discount %',
                ),
              ),
              TextField(
                controller: min,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minimum apartment orders',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              false,
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              true,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (ok != true || title.text.trim().isEmpty) {
      title.dispose();
      desc.dispose();
      discount.dispose();
      min.dispose();
      return;
    }

    try {
      await api.createVendorOffer(
        title: title.text.trim(),
        description: desc.text.trim().isEmpty
            ? null
            : desc.text.trim(),
        discountPercent:
            double.tryParse(discount.text) ?? 0,
        minOrders:
            int.tryParse(min.text) ?? 1,
      );

      reload();
    } catch (e) {
      _snack(e);
    } finally {
      title.dispose();
      desc.dispose();
      discount.dispose();
      min.dispose();
    }
  }

  Widget _orders() {
    return FutureBuilder<List<MarketplaceOrder>>(
      future: orders,
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (s.hasError) {
          return _error(s.error);
        }

        final list = s.data!;

        if (list.isEmpty) {
          return const Center(
            child: Text('No orders yet.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) => _orderCard(list[i]),
        );
      },
    );
  }

  Widget _orderCard(MarketplaceOrder o) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          o.residentName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${o.eventTitle} • ₹${o.totalAmount.toStringAsFixed(2)} • '
          '${o.status}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final i in o.items)
                  Text(
                    '• ${i.name}: ${i.quantity} ${i.unit}',
                  ),
                if (o.notes != null &&
                    o.notes!.isNotEmpty)
                  Text(
                    'Note: ${o.notes}',
                  ),
                if (o.serviceSlot != null)
                  Text(
                    'Slot: ${o.serviceSlot}',
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    if (o.status == 'PLACED')
                      OutlinedButton(
                        onPressed: () => _status(
                          o,
                          'ACCEPTED',
                        ),
                        child: const Text('Accept'),
                      ),
                    if ([
                      'PLACED',
                      'ACCEPTED',
                    ].contains(o.status))
                      OutlinedButton(
                        onPressed: () => _status(
                          o,
                          'PREPARING',
                        ),
                        child: const Text('Preparing'),
                      ),
                    if (o.status == 'PREPARING')
                      OutlinedButton(
                        onPressed: () => _status(
                          o,
                          'READY',
                        ),
                        child: const Text('Ready'),
                      ),
                    if (o.status == 'READY')
                      FilledButton(
                        onPressed: () => _status(
                          o,
                          'DELIVERED',
                        ),
                        child: const Text('Delivered'),
                      ),
                    if (![
                      'DELIVERED',
                      'CANCELLED',
                    ].contains(o.status))
                      TextButton(
                        onPressed: () => _status(
                          o,
                          'CANCELLED',
                        ),
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAggregate(
    MarketplaceEvent e,
  ) async {
    try {
      final a = await api.vendorAggregate(e.id);

      if (!mounted) {
        return;
      }

      setState(() {
        aggregate = a;
        aggregateEventId = e.id;
      });

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _aggregateSheet(a),
      );
    } catch (err) {
      _snack(err);
    }
  }

  Widget _aggregateSheet(
    MarketplaceAggregate a,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.eventTitle,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${a.apartmentCount} apartments • '
              '${a.orderCount} orders • '
              '₹${a.totalAmount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            ...a.items.map(
              (i) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.inventory_2_outlined,
                ),
                title: Text(i.name),
                subtitle: Text(
                  '${i.orderCount} orders',
                ),
                trailing: Text(
                  '${i.quantity} ${i.unit}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _quoteService(
    ServiceRequest r,
  ) async {
    final c = TextEditingController(
      text: r.quotedAmount?.toString() ?? '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (x) => AlertDialog(
        title: const Text('Service Quote'),
        content: TextField(
          controller: c,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Quoted amount (₹)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              x,
              false,
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              x,
              true,
            ),
            child: const Text('Send Quote'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final q = double.tryParse(
        c.text.trim(),
      );

      if (q == null) {
        _snack('Enter a valid quote.');
      } else {
        await _serviceStatus(
          r,
          'QUOTED',
          quote: q,
        );
      }
    }

    c.dispose();
  }

  Future<void> _serviceStatus(
    ServiceRequest r,
    String status, {
    double? quote,
  }) async {
    try {
      await api.updateVendorServiceRequest(
        r.id,
        status,
        quote: quote,
      );

      reload();
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _status(
    MarketplaceOrder o,
    String status,
  ) async {
    try {
      await api.updateVendorOrder(
        o.id,
        status,
      );

      reload();
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _eventStatus(
    MarketplaceEvent e,
    String status,
  ) async {
    try {
      await api.updateVendorEventStatus(
        e.id,
        status,
      );

      reload();
    } catch (x) {
      _snack(x);
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              false,
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              true,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    await ref
        .read(authProvider.notifier)
        .logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Widget _error(Object? e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Unable to load vendor portal.\n$e',
        ),
      ),
    );
  }

  void _snack(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );
  }

  String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}