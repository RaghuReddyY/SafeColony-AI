import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/guard_visitor.dart';
import '../../providers/guard_visitor_provider.dart';

class ApprovedVisitorCard
    extends ConsumerWidget {

  final GuardVisitor visitor;

  const ApprovedVisitorCard({
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
                    Icons.login),

                label: const Text(
                    "CHECK IN"),

onPressed: () async {

  final confirm =
      await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title:
                  const Text("Check In Visitor"),
              content: Text(
                "Check in ${visitor.visitorName}?",
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
                      const Text("Check In"),
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
        .checkIn(visitor.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        backgroundColor:
            Colors.green,

        content: Text(
          "${visitor.visitorName} checked in successfully.",
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