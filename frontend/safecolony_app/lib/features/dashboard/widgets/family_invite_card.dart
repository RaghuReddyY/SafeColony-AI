import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../resident/services/family_invite_service.dart';

class FamilyInviteCard extends StatefulWidget {
  const FamilyInviteCard({super.key});

  @override
  State<FamilyInviteCard> createState() => _FamilyInviteCardState();
}

class _FamilyInviteCardState extends State<FamilyInviteCard> {
  final _service = FamilyInviteService();
  bool _loading = false;
  String? _code;
  String? _unit;
  String? _sponsorType;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getInvite();
      if (!mounted) return;
      setState(() {
        _code = data['code']?.toString();
        _unit = data['unit_number']?.toString();
        _sponsorType = data['sponsor_type']?.toString();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copyCode() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Family join code copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xffE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;

            final content = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xffEEF2FF),
                  child: Icon(Icons.family_restroom, color: Color(0xff4F46E5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invite family members',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_sponsorType == null ? 'Owner or Tenant' : _sponsorType == 'TENANT' ? 'Tenant' : 'Owner'} family can join this unit using a separate invitation code.',
                        style: TextStyle(color: Color(0xff64748B), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final action = _code != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xffF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_unit != null)
                              Text(
                                'Unit $_unit',
                                style: const TextStyle(fontSize: 11, color: Color(0xff64748B)),
                              ),
                            Text(
                              _code!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: Color(0xff1E293B),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Copy code',
                          onPressed: _copyCode,
                          icon: const Icon(Icons.copy_rounded, size: 20),
                        ),
                      ],
                    ),
                  )
                : FilledButton.icon(
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.key_rounded),
                    label: Text(_loading ? 'Loading...' : 'Get Code'),
                  );

            if (!compact) {
              return Row(
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 14),
                  action,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: action),
              ],
            );
          },
        ),
      ),
    );
  }
}
