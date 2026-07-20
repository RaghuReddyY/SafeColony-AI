import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/info_tile.dart';

import '../models/guard_scan_result.dart';
import '../providers/guard_provider.dart';

class GuardScanResultScreen extends ConsumerWidget {
  final GuardScanResult visitor;

  const GuardScanResultScreen({
    super.key,
    required this.visitor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(guardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Visitor Details"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 45,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 16),

              // Visitor Name
              Text(
                visitor.visitorName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 12),

              // Status
              AppStatusChip(
                status: visitor.status,
              ),

              const SizedBox(height: 28),

              // Information Card
              AppCard(
                child: Column(
                  children: [
                    InfoTile(
                      icon: Icons.phone,
                      title: "Phone",
                      value: visitor.phone,
                    ),

                    const Divider(),

                    InfoTile(
                      icon: Icons.badge,
                      title: "Visitor Type",
                      value: visitor.visitorType,
                    ),

                    if (visitor.purpose != null) ...[
                      const Divider(),
                      InfoTile(
                        icon: Icons.assignment,
                        title: "Purpose",
                        value: visitor.purpose!,
                      ),
                    ],

                    if (visitor.vehicleNumber != null) ...[
                      const Divider(),
                      InfoTile(
                        icon: Icons.directions_car,
                        title: "Vehicle",
                        value: visitor.vehicleNumber!,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (visitor.status == "APPROVED")
                AppPrimaryButton(
                  text: "CHECK IN",
                  icon: Icons.login,
                  isLoading: state.isLoading,
                  onPressed: () async {
                    await ref.read(guardProvider.notifier).checkIn();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),

              if (visitor.status == "CHECKED_IN")
                AppPrimaryButton(
                  text: "CHECK OUT",
                  icon: Icons.logout,
                  isLoading: state.isLoading,
                  onPressed: () async {
                    await ref.read(guardProvider.notifier).checkOut();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}