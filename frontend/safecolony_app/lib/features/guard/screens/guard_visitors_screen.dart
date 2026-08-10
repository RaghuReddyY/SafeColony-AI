import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/guard_visitor_provider.dart';

class GuardVisitorsScreen extends ConsumerStatefulWidget {
  const GuardVisitorsScreen({super.key});

  @override
  ConsumerState<GuardVisitorsScreen> createState() =>
      _GuardVisitorsScreenState();
}

class _GuardVisitorsScreenState
    extends ConsumerState<GuardVisitorsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(guardVisitorProvider.notifier)
          .loadAll();
    });
  }

  Future<void> _refresh() async {
    await ref
        .read(guardVisitorProvider.notifier)
        .loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guardVisitorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Guard Visitors"),
      ),
      body: Builder(
        builder: (_) {
          if (state.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.error != null) {
            return Center(
              child: Text(state.error!),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                //--------------------------------------------------
                // Pending Visitors
                //--------------------------------------------------

                const Text(
                  "Pending Visitors",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (state.pendingVisitors.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          "No Pending Visitors",
                        ),
                      ),
                    ),
                  )
                else
                  ...state.pendingVisitors.map(
                    (visitor) => Card(
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(visitor.visitorName),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(visitor.phone),
                            Text(visitor.visitorType),
                            Text(visitor.purpose),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                //--------------------------------------------------
                // Visitors Inside
                //--------------------------------------------------

                const Text(
                  "Visitors Inside",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (state.insideVisitors.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          "No Visitors Inside",
                        ),
                      ),
                    ),
                  )
                else
                  ...state.insideVisitors.map(
                    (visitor) => Card(
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(
                            Icons.login,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(visitor.visitorName),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(visitor.phone),
                            Text(visitor.visitorType),
                            Text(visitor.purpose),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.logout,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}