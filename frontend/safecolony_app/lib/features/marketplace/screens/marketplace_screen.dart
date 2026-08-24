import 'package:flutter/material.dart';

import '../models/marketplace.dart';
import '../services/marketplace_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final api = MarketplaceService();
  late Future<List<MarketplaceEvent>> future;

  @override
  void initState() {
    super.initState();
    future = api.events();
  }

  void reload() => setState(() => future = api.events());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Community Marketplace')),
        backgroundColor: const Color(0xffF5F7FB),
        body: RefreshIndicator(
          onRefresh: () async {
            reload();
            await future;
          },
          child: FutureBuilder<List<MarketplaceEvent>>(
            future: future,
            builder: (context, s) {
              if (s.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (s.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Unable to load community marketplace.\n${s.error}'),
                  ),
                );
              }
              final events = s.data ?? const <MarketplaceEvent>[];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _intro(),
                  const SizedBox(height: 16),
                  if (events.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No community days are scheduled yet. Ask your organization admin to create one.',
                        ),
                      ),
                    )
                  else
                    ...events.map(_eventCard),
                  const SizedBox(height: 20),
                  _myOrders(),
                ],
              );
            },
          ),
        ),
      );

  Widget _intro() => Container(
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
            SizedBox(height: 10),
            Text(
              'Bring the vendor to your community',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Add multiple items to one community order. Adjust quantities, review the total and place once.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );

  Widget _eventCard(MarketplaceEvent e) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Icon(
                      e.eventType == 'SERVICE'
                          ? Icons.build_rounded
                          : Icons.shopping_basket_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          '${e.category} • ${e.vendorName ?? "Community vendor"}',
                          style: const TextStyle(color: Color(0xff64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (e.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(e.description!),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (e.scheduledFor != null)
                    Chip(label: Text('Delivery ${_date(e.scheduledFor!)}')),
                  if (e.cutoffAt != null)
                    Chip(label: Text('Cutoff ${_date(e.cutoffAt!)}')),
                  if ((e.apartmentCount ?? 0) > 0)
                    Chip(label: Text('${e.apartmentCount} apartments ordering')),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: e.status == 'OPEN' ? () => _openCart(e) : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Open Cart & Order'),
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _openCart(MarketplaceEvent event) async {
    final cart = <MarketplaceItem>[];
    final slot = TextEditingController();
    final notes = TextEditingController();
    var submitting = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !submitting,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            double total() => cart.fold(
                  0,
                  (sum, item) => sum + item.quantity * item.unitPrice,
                );

            Future<void> addItem() async {
              final item = await _itemDialog(context, event);
              if (item == null) return;
              final index = cart.indexWhere(
                (existing) =>
                    existing.name.toLowerCase() == item.name.toLowerCase() &&
                    existing.unit.toLowerCase() == item.unit.toLowerCase(),
              );
              setDialogState(() {
                if (index >= 0) {
                  final existing = cart[index];
                  cart[index] = MarketplaceItem(
                    name: existing.name,
                    unit: existing.unit,
                    quantity: existing.quantity + item.quantity,
                    unitPrice: item.unitPrice,
                  );
                } else {
                  cart.add(item);
                }
              });
            }

            Future<void> place() async {
              if (cart.isEmpty) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Add at least one item to the cart.')),
                );
                return;
              }
              setDialogState(() => submitting = true);
              try {
                await api.placeOrder(
                  event.id,
                  List<MarketplaceItem>.from(cart),
                  notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
                  serviceSlot: slot.text.trim().isEmpty ? null : slot.text.trim(),
                );
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Community order placed successfully.')),
                );
                reload();
                setState(() {});
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
                setDialogState(() => submitting = false);
              }
            }

            return AlertDialog(
              title: Text('${event.title} — Cart'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.eventType == 'SERVICE'
                            ? 'Add all service details/items required in one request.'
                            : 'Add multiple items. One resident order will contain all cart items.',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      if (cart.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(14),
                            child: Text('Your cart is empty.'),
                          ),
                        )
                      else
                        ...List.generate(cart.length, (index) {
                          final item = cart[index];
                          final line = item.quantity * item.unitPrice;
                          return Card(
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                '${_number(item.quantity)} ${item.unit} × ₹${item.unitPrice.toStringAsFixed(2)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('₹${line.toStringAsFixed(2)}'),
                                  IconButton(
                                    tooltip: 'Remove',
                                    onPressed: submitting
                                        ? null
                                        : () => setDialogState(() => cart.removeAt(index)),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: submitting ? null : addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add another item'),
                      ),
                      const Divider(height: 28),
                      TextField(
                        controller: slot,
                        enabled: !submitting,
                        decoration: const InputDecoration(
                          labelText: 'Preferred slot (optional)',
                          hintText: 'e.g. 10:00–11:00 AM',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notes,
                        enabled: !submitting,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes / delivery instructions',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Order total', style: TextStyle(fontWeight: FontWeight.w800)),
                          Text(
                            '₹${total().toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: submitting ? null : place,
                  icon: submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(submitting ? 'Placing...' : 'Place Order'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      slot.dispose();
      notes.dispose();
    }
  }

  Future<MarketplaceItem?> _itemDialog(
    BuildContext parent,
    MarketplaceEvent event,
  ) async {
    final name = TextEditingController();
    final qty = TextEditingController(text: '1');
    final unit = TextEditingController(text: 'unit');
    final price = TextEditingController(text: '0');
    try {
      return await showDialog<MarketplaceItem>(
        context: parent,
        builder: (context) => AlertDialog(
          title: const Text('Add Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: event.eventType == 'SERVICE' ? 'Service / item required' : 'Item name',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qty,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: unit,
                        decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Expected unit price',
                    helperText: 'Vendor can confirm the final price',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final item = MarketplaceItem(
                  name: name.text.trim(),
                  unit: unit.text.trim().isEmpty ? 'unit' : unit.text.trim(),
                  quantity: double.tryParse(qty.text.trim()) ?? 0,
                  unitPrice: double.tryParse(price.text.trim()) ?? 0,
                );
                if (item.name.isEmpty || item.quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid item and quantity.')),
                  );
                  return;
                }
                Navigator.pop(context, item);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
    } finally {
      name.dispose();
      qty.dispose();
      unit.dispose();
      price.dispose();
    }
  }

  Widget _myOrders() => FutureBuilder<List<MarketplaceOrder>>(
        future: api.myOrders(),
        builder: (c, s) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Community Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (s.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator()
                else if (s.hasError)
                  const Text('Orders will appear here after your first order.')
                else if (s.data!.isEmpty)
                  const Text('No orders yet.')
                else
                  ...s.data!.map(
                    (o) => ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(o.eventTitle),
                      subtitle: Text('Status: ${o.status} • ₹${o.totalAmount.toStringAsFixed(2)}'),
                      children: [
                        ...o.items.map(
                          (i) => ListTile(
                            dense: true,
                            title: Text(i.name),
                            subtitle: Text('${_number(i.quantity)} ${i.unit} × ₹${i.unitPrice.toStringAsFixed(2)}'),
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

  String _number(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);

  String _date(DateTime d) {
    final l = d.toLocal();
    return '${l.day}/${l.month} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}
