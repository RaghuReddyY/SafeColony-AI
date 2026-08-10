import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/guard_visitor_provider.dart';
import '../cards/approved_visitor_card.dart';

class ApprovedVisitorsSection extends ConsumerWidget {
  const ApprovedVisitorsSection({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      guardVisitorProvider,
    );

    if (state.approvedVisitors.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        const Text(
          "Approved Visitors",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount:
              state.approvedVisitors.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (_, index) {
            final visitor =
                state.approvedVisitors[index];

            return ApprovedVisitorCard(
              visitor: visitor,
            );
          },
        ),
      ],
    );
  }
}