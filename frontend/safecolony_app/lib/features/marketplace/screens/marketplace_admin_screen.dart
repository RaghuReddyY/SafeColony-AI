import 'package:flutter/material.dart';
import '../models/marketplace.dart';
import '../services/marketplace_service.dart';

class MarketplaceAdminScreen extends StatefulWidget {
  const MarketplaceAdminScreen({super.key});

  @override
  State<MarketplaceAdminScreen> createState() => _MarketplaceAdminScreenState();
}

class _MarketplaceAdminScreenState extends State<MarketplaceAdminScreen> {
  final api = MarketplaceService();
  late Future<List<MarketplaceEvent>> eventsFuture;
  late Future<List<MarketplaceVendor>> vendorsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    eventsFuture = api.events();
    vendorsFuture = api.vendors();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Marketplace Admin'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      backgroundColor: const Color(0xffF5F7FB),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hero(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _addVendor,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Create Vendor Account'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addEvent,
                  icon: const Icon(Icons.event),
                  label: const Text('Create Community Day'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Vendors',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _vendorsList(),
          const SizedBox(height: 20),
          const Text(
            'Community Days',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _eventsList(),
        ],
      ),
    );
  }

  Widget _vendorsList() {
    return FutureBuilder<List<MarketplaceVendor>>(
      future: vendorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Unable to load vendors: ${snapshot.error}');
        }

        final vendors = snapshot.data ?? <MarketplaceVendor>[];
        if (vendors.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No vendors yet.'),
            ),
          );
        }

        return Column(
          children: vendors.map((vendor) {
            final login = vendor.email == null
                ? vendor.userId == null
                    ? 'Vendor account not linked'
                    : 'Vendor account linked'
                : 'Login: ${vendor.email}';

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.store),
                ),
                title: Text(vendor.name),
                subtitle: Text(
                  '${vendor.category}'
                  '${vendor.phone == null ? '' : ' • ${vendor.phone}'}\n'
                  '$login',
                ),
                isThreeLine: true,
                trailing: Icon(
                  vendor.userId == null
                      ? Icons.link_off
                      : Icons.verified_user,
                  color: vendor.userId == null ? Colors.orange : Colors.green,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _eventsList() {
    return FutureBuilder<List<MarketplaceEvent>>(
      future: eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Unable to load events: ${snapshot.error}');
        }

        final events = snapshot.data ?? <MarketplaceEvent>[];
        if (events.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No community days yet.'),
            ),
          );
        }

        return Column(children: events.map(_event).toList());
      },
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff0F766E), Color(0xff2563EB)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.storefront_rounded, color: Colors.white, size: 32),
          SizedBox(height: 8),
          Text(
            'Community Vendor Network',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Create vendor accounts, assign community days and monitor consolidated resident demand.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _event(MarketplaceEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            event.eventType == 'SERVICE'
                ? Icons.build
                : Icons.shopping_basket,
          ),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${event.category} • ${event.vendorName ?? 'No vendor'}\n'
          '${event.apartmentCount ?? 0} apartments • '
          '${event.orderCount ?? 0} orders • ${event.status}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            try {
              if (value == 'aggregate') {
                await _aggregate(event);
              } else if (value == 'orders') {
                await _orders(event);
              } else if (value == 'close') {
                await api.updateEventStatus(event.id, 'CLOSED');
                _reload();
              } else if (value == 'open') {
                await api.updateEventStatus(event.id, 'OPEN');
                _reload();
              }
            } catch (error) {
              _snack(error);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'aggregate',
              child: Text('View aggregated demand'),
            ),
            const PopupMenuItem(
              value: 'orders',
              child: Text('View resident orders'),
            ),
            if (event.status == 'OPEN')
              const PopupMenuItem(
                value: 'close',
                child: Text('Close ordering'),
              ),
            if (event.status == 'CLOSED')
              const PopupMenuItem(
                value: 'open',
                child: Text('Re-open ordering'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addVendor() async {
    final name = TextEditingController();
    final category = TextEditingController(text: 'GROCERY');
    final phone = TextEditingController();
    final fullName = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController(text: 'Vendor@123');
    final notes = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Vendor Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Business name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fullName,
                decoration: const InputDecoration(
                  labelText: 'Vendor user name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Login email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Temporary password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: category,
                decoration: const InputDecoration(
                  labelText: 'Category (GROCERY/SERVICE/PHARMACY)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        final vendor = await api.createVendorAccount(
          name: name.text.trim(),
          category: category.text.trim(),
          phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
          notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
          fullName: fullName.text.trim(),
          email: email.text.trim(),
          password: password.text,
        );
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Vendor account created'),
            content: Text(
              'Login: ${vendor.email ?? email.text.trim()}\n'
              'Temporary password: ${password.text}\n\n'
              'Ask the vendor to change the password after first login.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Done'),
              ),
            ],
          ),
        );
        _reload();
      } catch (error) {
        _snack(error);
      }
    }

    for (final controller in [
      name,
      category,
      phone,
      fullName,
      email,
      password,
      notes,
    ]) {
      controller.dispose();
    }
  }

  Future<void> _addEvent() async {
    final title = TextEditingController();
    final category = TextEditingController(text: 'GROCERY');
    final description = TextEditingController();
    int? vendorId;

    try {
      final vendors = await api.vendors();
      if (!mounted) return;

      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Create Community Day'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: vendorId,
                    decoration: const InputDecoration(
                      labelText: 'Vendor',
                      border: OutlineInputBorder(),
                    ),
                    items: vendors
                        .map(
                          (vendor) => DropdownMenuItem<int>(
                            value: vendor.id,
                            child: Text(vendor.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => vendorId = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: description,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      );

      if (ok == true && title.text.trim().isNotEmpty) {
        await api.createEvent(
          title: title.text.trim(),
          category: category.text.trim(),
          eventType: category.text.trim().toUpperCase().contains('SERVICE')
              ? 'SERVICE'
              : 'PRODUCT',
          vendorId: vendorId,
          description: description.text.trim().isEmpty
              ? null
              : description.text.trim(),
        );
        _reload();
      }
    } catch (error) {
      if (mounted) _snack(error);
    } finally {
      title.dispose();
      category.dispose();
      description.dispose();
    }
  }

  Future<void> _aggregate(MarketplaceEvent event) async {
    try {
      final aggregate = await api.aggregate(event.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(aggregate.eventTitle),
          content: SizedBox(
            width: 500,
            height: 400,
            child: ListView(
              children: [
                Text(
                  '${aggregate.apartmentCount} apartments • '
                  '${aggregate.orderCount} orders • '
                  '₹${aggregate.totalAmount.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 12),
                ...aggregate.items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text('${item.orderCount} orders'),
                    trailing: Text(
                      '${item.quantity} ${item.unit}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      _snack(error);
    }
  }

  Future<void> _orders(MarketplaceEvent event) async {
    try {
      final orders = await api.adminOrders(eventId: event.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('${event.title} — Resident Orders'),
          content: SizedBox(
            width: 650,
            height: 450,
            child: orders.isEmpty
                ? const Center(child: Text('No resident orders yet.'))
                : ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, index) => const Divider(),
                    itemBuilder: (_, index) {
                      final order = orders[index];
                      return ListTile(
                        title: Text(
                          order.residentName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${order.items.map((item) => '${item.name} ${item.quantity} ${item.unit}').join(', ')}\n'
                          'Status: ${order.status}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          '₹${order.totalAmount.toStringAsFixed(0)}',
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      _snack(error);
    }
  }

  void _snack(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }
}
