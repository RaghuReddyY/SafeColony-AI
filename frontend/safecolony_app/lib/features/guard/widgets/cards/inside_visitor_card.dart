import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/guard_visitor.dart';
import '../../providers/guard_visitor_provider.dart';

class InsideVisitorCard
    extends ConsumerWidget {

  final GuardVisitor visitor;

  const InsideVisitorCard({
    super.key,
    required this.visitor,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref) {

    return Card(

      child: Padding(

        padding:
            const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Text(
              visitor.visitorName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(visitor.phone),

            Text(visitor.visitorType),

            Text(visitor.purpose),

            const Spacer(),

            SizedBox(

              width: double.infinity,

              child: FilledButton.icon(

                icon: const Icon(
                    Icons.logout),

                label: const Text(
                    "CHECK OUT"),

onPressed: () async {

  final confirm =
      await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title:
                  const Text("Check Out Visitor"),
              content: Text(
                "Check out ${visitor.visitorName}?",
              ),
              actions: [

                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    context,
                    false,
                  ),
                  child:
                      const Text("Cancel"),
                ),

                FilledButton(
                  onPressed: () =>
                      Navigator.pop(
                    context,
                    true,
                  ),
                  child:
                      const Text("Check Out"),
                ),
              ],
            ),
          ) ??
          false;

  if (!confirm) return;

  try {

    await ref
        .read(
          guardVisitorProvider.notifier,
        )
        .checkOut(visitor.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        backgroundColor:
            Colors.green,

        content: Text(
          "${visitor.visitorName} checked out successfully.",
        ),
      ),
    );

  } catch (e) {

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        backgroundColor: Colors.red,
        content: Text(e.toString()),
      ),
    );
  }
},
              ),
            ),
          ],
        ),
      ),
    );
  }
}