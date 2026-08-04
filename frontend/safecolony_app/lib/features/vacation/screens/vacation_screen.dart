import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vacation_provider.dart';
import 'add_vacation_screen.dart';

class VacationScreen extends ConsumerWidget {
  const VacationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vacations = ref.watch(vacationHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vacation Mode"),
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddVacationScreen(),
            ),
          );

          if (created == true) {
            ref.invalidate(vacationHistoryProvider);
          }
        },
      ),

      body: vacations.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text(
                "No vacations found.\nTap + to create one.",
                textAlign: TextAlign.center,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vacationHistoryProvider);
            },
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, index) {
                final vacation = list[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.beach_access),
                    ),
                    title: Text(
                      vacation.status,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          "${vacation.startDate.toString().split(' ').first} → ${vacation.endDate.toString().split(' ').first}",
                        ),
                        if (vacation.reason != null &&
                            vacation.reason!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(vacation.reason!),
                          ),
                      ],
                    ),
                    trailing: vacation.status == "ACTIVE"
                        ? IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              await ref
                                  .read(vacationProvider)
                                  .cancel(vacation.id);

                              ref.invalidate(vacationHistoryProvider);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Vacation cancelled",
                                    ),
                                  ),
                                );
                              }
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text(e.toString()),
        ),
      ),
    );
  }
}