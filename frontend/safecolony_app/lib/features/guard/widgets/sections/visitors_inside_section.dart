import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/guard_visitor_provider.dart';
import '../cards/inside_visitor_card.dart';

class VisitorsInsideSection
    extends ConsumerWidget {
  const VisitorsInsideSection({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final state =
        ref.watch(guardVisitorProvider);

    if (state.insideVisitors.isEmpty) {
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
          "Visitors Inside",
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
              state.insideVisitors.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 200,
          ),
          itemBuilder: (_, index) {
            return InsideVisitorCard(
              visitor:
                  state.insideVisitors[index],
            );
          },
        ),
      ],
    );
  }
}