import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/emergency_provider.dart';

class EmergencySOSScreen extends ConsumerStatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  ConsumerState<EmergencySOSScreen> createState() =>
      _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends ConsumerState<EmergencySOSScreen> {
  final _messageController = TextEditingController();
  String _selectedType = 'MEDICAL';
  bool _submitting = false;

  final List<_EmergencyType> _types = const [
    _EmergencyType('MEDICAL', Icons.medical_services, 'Medical emergency'),
    _EmergencyType('FIRE', Icons.local_fire_department, 'Fire emergency'),
    _EmergencyType('POLICE', Icons.local_police, 'Police / security emergency'),
    _EmergencyType('GENERAL', Icons.warning_amber_rounded, 'Other emergency'),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _raiseSOS() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raise Emergency SOS?'),
        content: Text(
          'This will immediately notify the community security team and administrators about the $_selectedType emergency.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Raise SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);

    try {
      final alert = await ref.read(emergencyServiceProvider).raiseEmergency(
            emergencyType: _selectedType,
            message: _messageController.text.trim().isEmpty
                ? null
                : _messageController.text.trim(),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Emergency SOS #${alert.id} raised. Security and administrators have been notified.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Unable to raise SOS: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('Emergency SOS'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 38),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Use SOS only for a genuine emergency. Your alert is immediately shared with community security and administrators.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Emergency type',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._types.map(
            (type) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: RadioListTile<String>(
                value: type.value,
                groupValue: _selectedType,
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
                secondary: Icon(type.icon, color: Colors.red),
                title: Text(type.label),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            maxLines: 4,
            maxLength: 500,
            enabled: !_submitting,
            decoration: const InputDecoration(
              labelText: 'Additional details (optional)',
              hintText: 'Tell security what is happening and where help is needed.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: _submitting ? null : _raiseSOS,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sos),
              label: Text(_submitting ? 'Raising SOS...' : 'RAISE EMERGENCY SOS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyType {
  final String value;
  final IconData icon;
  final String label;

  const _EmergencyType(this.value, this.icon, this.label);
}
