import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/visitor.dart';
import '../providers/visitor_provider.dart';
import '../widgets/visitor_card.dart';
import 'add_visitor_screen.dart';

class VisitorListScreen extends ConsumerStatefulWidget {
  const VisitorListScreen({super.key});

  @override
  ConsumerState<VisitorListScreen> createState() =>
      _VisitorListScreenState();
}

class _VisitorListScreenState
    extends ConsumerState<VisitorListScreen> {

  late Future<List<Visitor>> _future;

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  void _loadVisitors() {
    _future = ref
        .read(visitorProvider)
        .loadResidentVisitors(2);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadVisitors();
    });

    await _future;
  }

  Future<void> _approveVisitor(
      Visitor visitor) async {

    final approved =
        await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title:
                    const Text("Approve Visitor"),
                content: Text(
                  "Approve ${visitor.visitorName}?",
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(
                            context, false),
                    child:
                        const Text("Cancel"),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(
                            context, true),
                    child:
                        const Text("Approve"),
                  ),
                ],
              ),
            ) ??
            false;

    if (!approved) return;

    try {
      await ref
          .read(visitorProvider)
          .approveVisitor(visitor.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "${visitor.visitorName} approved successfully.",
          ),
        ),
      );

      await _refresh();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> _rejectVisitor(
      Visitor visitor) async {

    final rejected =
        await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title:
                    const Text("Reject Visitor"),
                content: Text(
                  "Reject ${visitor.visitorName}?",
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(
                            context, false),
                    child:
                        const Text("Cancel"),
                  ),
                  FilledButton(
                    style:
                        FilledButton.styleFrom(
                      backgroundColor:
                          Colors.red,
                    ),
                    onPressed: () =>
                        Navigator.pop(
                            context, true),
                    child:
                        const Text("Reject"),
                  ),
                ],
              ),
            ) ??
            false;

    if (!rejected) return;

    try {
      await ref
          .read(visitorProvider)
          .rejectVisitor(visitor.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "${visitor.visitorName} rejected.",
          ),
        ),
      );

      await _refresh();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Visitors",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () async {
          final created =
              await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AddVisitorScreen(),
            ),
          );

          if (created == true) {
            _refresh();
          }
        },
        icon:
            const Icon(Icons.person_add),
        label:
            const Text("Add Visitor"),
      ),

      body: FutureBuilder<List<Visitor>>(
        future: _future,
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          final visitors =
              snapshot.data ?? [];

          if (visitors.isEmpty) {
            return const Center(
              child: Text(
                "No Visitors",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding:
                  const EdgeInsets.all(18),
              itemCount: visitors.length,
              itemBuilder:
                  (context, index) {

                final visitor =
                    visitors[index];

                return VisitorCard(
                  visitor: visitor,

                  onApprove: () =>
                      _approveVisitor(
                          visitor),

                  onReject: () =>
                      _rejectVisitor(
                          visitor),

                  onRefresh: _refresh,
                );
              },
            ),
          );
        },
      ),
    );
  }
}