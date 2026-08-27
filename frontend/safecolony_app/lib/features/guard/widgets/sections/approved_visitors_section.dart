import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/guard_visitor_provider.dart';
import '../cards/approved_visitor_card.dart';
import '../../screens/visitor_detail_screen.dart';

class ApprovedVisitorsSection
    extends ConsumerWidget {
  const ApprovedVisitorsSection({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final state =
        ref.watch(guardVisitorProvider);

    if (state.approvedVisitors.isEmpty) {
      return const SizedBox.shrink();
    }

    final width =
        MediaQuery.of(context).size.width;

    final crossAxisCount =
        width >= 1200
            ? 3
            : width >= 700
                ? 2
                : 1;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          "Approved Visitors",
          style: TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
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
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,

            // Fixed card height prevents huge widgets.
            mainAxisExtent: 210,
          ),
          itemBuilder: (_, index) {
            final visitor =
                state.approvedVisitors[index];

            return ApprovedVisitorCard(
              visitor: visitor,

              onDetails: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuardVisitorDetailScreen(
                      visitor: visitor,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}