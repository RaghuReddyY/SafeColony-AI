import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/emergency_alert.dart';
import '../providers/emergency_provider.dart';

class EmergencyAlertsScreen extends ConsumerStatefulWidget {
  const EmergencyAlertsScreen({super.key});

  @override
  ConsumerState<EmergencyAlertsScreen> createState() =>
      _EmergencyAlertsScreenState();
}

class _EmergencyAlertsScreenState
    extends ConsumerState<EmergencyAlertsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        ref.invalidate(unresolvedEmergencyProvider);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resolve(EmergencyAlert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Emergency?'),
        content: Text(
          'Mark emergency SOS #${alert.id} from ${alert.raisedByName ?? 'Unknown'} as resolved?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(emergencyServiceProvider).resolve(alert.id);
      ref.invalidate(unresolvedEmergencyProvider);
      ref.invalidate(allEmergencyProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency resolved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Unable to resolve emergency: $e'),
        ),
      );
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.deepOrange;
      case 'MEDIUM':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _icon(String type) {
    switch (type.toUpperCase()) {
      case 'MEDICAL':
        return Icons.medical_services;
      case 'FIRE':
        return Icons.local_fire_department;
      case 'POLICE':
        return Icons.local_police;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} ${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(unresolvedEmergencyProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('Active Emergency Alerts'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(unresolvedEmergencyProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load emergency alerts.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(unresolvedEmergencyProvider);
                await ref.read(unresolvedEmergencyProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No active emergency alerts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(child: Text('The community currently has no unresolved SOS alerts.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(unresolvedEmergencyProvider);
              await ref.read(unresolvedEmergencyProvider.future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final severityColor = _severityColor(alert.severity);

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: severityColor.withValues(alpha: .12),
                              foregroundColor: severityColor,
                              child: Icon(_icon(alert.alertType)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alert.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(_formatDate(alert.createdAt)),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(alert.severity),
                              labelStyle: TextStyle(
                                color: severityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          alert.message,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        _info('Raised by', alert.raisedByName ?? 'Unknown'),
                        _info('Role', alert.sourceRole ?? 'Unknown'),
                        if (alert.unitNumber != null)
                          _info('Unit', alert.unitNumber!),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _resolve(alert),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Mark Resolved'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
