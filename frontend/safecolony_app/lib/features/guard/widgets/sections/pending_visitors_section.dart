import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/guard_visitor_provider.dart';
import '../cards/pending_visitor_card.dart';

class PendingVisitorsSection
    extends ConsumerStatefulWidget {
  const PendingVisitorsSection({
    super.key,
  });

  @override
  ConsumerState<PendingVisitorsSection>
      createState() =>
          _PendingVisitorsSectionState();
}

class _PendingVisitorsSectionState
    extends ConsumerState<PendingVisitorsSection> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(
            guardVisitorProvider.notifier,
          )
          .loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(guardVisitorProvider);

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

    if (state.pendingVisitors.isEmpty) {
      return const Center(
        child: Text(
          "No Pending Visitors",
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount:
          state.pendingVisitors.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (_, index) {
        final visitor =
            state.pendingVisitors[index];

        return PendingVisitorCard(
          visitor: visitor,

          onApprove: () async {
            await ref
                .read(
                  guardVisitorProvider
                      .notifier,
                )
                .checkIn(
                  visitor.id,
                );
          },

          onReject: () {
            // We'll implement Reject later
          },
        );
      },
    );
  }
}